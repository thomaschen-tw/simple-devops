/**
 * Terraform 主配置文件
 * 定义 AWS Provider 和核心资源
 */

# Terraform 版本约束已移至 versions.tf

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  # 使用 AWS CLI profile

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Environment = var.environment
        Project     = var.project_name
      }
    )
  }
}

# 获取当前 AWS 账户 ID
data "aws_caller_identity" "current" {}

# 获取可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# 本地变量：计算可用区
locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  
  # 资源命名前缀
  name_prefix = "${var.project_name}-${var.environment}"
  
  # 镜像地址配置
  # 方案 A: 使用 GHCR（镜像需设为公开）
  # backend_image  = "ghcr.io/${var.github_username}/${var.github_repo}/backend:latest"
  # frontend_image = "ghcr.io/${var.github_username}/${var.github_repo}/frontend:latest"
  
  # 方案 B: 使用 ECR（推荐，取消注释并创建 ECR 仓库）
  backend_image  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}/${var.environment}/backend:latest"
  frontend_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}/${var.environment}/frontend:latest"
}

