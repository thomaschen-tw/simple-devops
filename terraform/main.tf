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
  #   region = "ap-southeast-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# 数据源：获取可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# 数据源：获取当前 AWS 账号 ID
data "aws_caller_identity" "current" {}

# 数据源：获取当前区域
data "aws_region" "current" {}

# ============================================================================
# 步骤 1：VPC 网络基础设施
# ============================================================================
# 学习内容：VPC、子网、路由表、NAT Gateway
# 参考：STEP_BY_STEP_GUIDE.md 步骤 1
# 配置文件：vpc.tf

# ============================================================================
# 步骤 2：安全组配置
# ============================================================================
# 学习内容：Security Groups、网络访问控制
# 配置文件：security.tf
# 注意：安全组需要在 ALB 和 RDS 之前创建

# ============================================================================
# 步骤 3：Application Load Balancer
# ============================================================================
# 学习内容：ALB、Target Groups、Listener、路由规则
# 参考：STEP_BY_STEP_GUIDE.md 步骤 3
# 配置文件：alb.tf
# 注意：RDS 需要引用 ALB 的安全组，所以先创建 ALB

# ============================================================================
# 步骤 4：RDS 数据库
# ============================================================================
# 学习内容：RDS PostgreSQL、安全组、数据库连接
# 参考：STEP_BY_STEP_GUIDE.md 步骤 2
# 配置文件：rds.tf
# 注意：RDS 依赖 ALB 的安全组（ECS tasks security group）

# ============================================================================
# 步骤 5：ECS 集群和服务
# ============================================================================
# 学习内容：ECS Fargate、Task Definition、Service、容器配置
# 参考：STEP_BY_STEP_GUIDE.md 步骤 4
# 配置文件：ecs.tf

# ============================================================================
# 可选资源（已注释，需要时可取消注释）
# ============================================================================

# ECR 镜像仓库（可选）
# 如果使用 GHCR，可以跳过此配置
# 如果需要使用 ECR，取消注释并配置 ecr-sync.tf
# 参考：ecr-sync.tf
