terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 可选：使用 S3 后端存储状态
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "simple-devops/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# 数据源：获取默认 VPC（如果使用现有 VPC）
# data "aws_vpc" "default" {
#   default = true
# }

# 数据源：获取可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# 数据源：获取当前 AWS 账号 ID
data "aws_caller_identity" "current" {}

# 数据源：获取当前区域
data "aws_region" "current" {}

# VPC 模块
module "vpc" {
  source = "./modules/vpc"

  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  availability_zones = var.availability_zones
  tags             = var.tags
}

# ALB 模块（先创建，RDS 需要引用 ALB 的安全组）
module "alb" {
  source = "./modules/alb"

  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn  = var.certificate_arn
  domain_name      = var.domain_name
  tags             = var.tags
}

# RDS 模块
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.alb.backend_security_group_id
  database_name         = var.database_name
  database_username     = var.database_username
  database_password     = var.database_password
  instance_class        = var.database_instance_class
  allocated_storage     = var.database_allocated_storage
  tags                  = var.tags

  depends_on = [module.alb]
}

# ECR 仓库（用于存储 Docker 镜像，可选）
# 如果使用 GHCR，可以跳过此模块
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# ECS 集群
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# ECS Backend 服务
module "ecs_backend" {
  source = "./modules/ecs-service"

  project_name      = var.project_name
  environment       = var.environment
  service_name      = "backend"
  cluster_id        = aws_ecs_cluster.main.id
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  target_group_arn  = module.alb.backend_target_group_arn
  security_group_id = module.alb.backend_security_group_id

  # 容器配置
  cpu                = var.backend_cpu
  memory             = var.backend_memory
  desired_count      = var.backend_desired_count
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  # 镜像配置
  image_repository   = "ghcr.io/${var.github_username}/${var.github_repo}/backend"
  image_tag          = "latest"
  github_token       = var.github_token

  # 环境变量
  environment_variables = {
    DATABASE_URL = "postgresql+psycopg://${var.database_username}:${var.database_password}@${module.rds.endpoint}:5432/${var.database_name}"
  }

  tags = var.tags
}

# ECS Frontend 服务
module "ecs_frontend" {
  source = "./modules/ecs-service"

  project_name      = var.project_name
  environment       = var.environment
  service_name      = "frontend"
  cluster_id        = aws_ecs_cluster.main.id
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  target_group_arn  = module.alb.frontend_target_group_arn
  security_group_id = module.alb.frontend_security_group_id

  # 容器配置
  cpu                = var.frontend_cpu
  memory             = var.frontend_memory
  desired_count      = var.frontend_desired_count
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  # 镜像配置
  image_repository   = "ghcr.io/${var.github_username}/${var.github_repo}/frontend"
  image_tag          = "latest"
  github_token       = var.github_token

  # 环境变量
  environment_variables = {
    VITE_API_BASE_URL = var.domain_name != "" ? "https://${var.domain_name}/api" : "http://${module.alb.dns_name}/api"
  }

  tags = var.tags
}

# 前端静态资源（S3 + CloudFront）- 可选
# 如果使用 ECS Frontend，可以注释掉此模块
# module "frontend_static" {
#   source = "./modules/frontend"
#
#   project_name = var.project_name
#   environment  = var.environment
#   domain_name  = var.domain_name
#   certificate_arn = var.certificate_arn
#   tags         = var.tags
# }

