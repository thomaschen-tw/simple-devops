/**
 * Terraform 版本约束
 * 确保使用兼容的 Terraform 和 Provider 版本
 */

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 可选：使用 S3 后端存储状态文件（推荐生产环境）
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "simple-blog/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

