/**
 * Terraform 变量定义
 * 定义所有可配置的变量
 */

variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "ap-southeast-1"  # 新加坡区域
}

variable "aws_profile" {
  description = "AWS CLI Profile 名称（用于认证）"
  type        = string
  default     = "company"
}

variable "project_name" {
  description = "项目名称，用于资源命名"
  type        = string
  default     = "simple-blog"
}

variable "environment" {
  description = "环境名称（dev/staging/prod）"
  type        = string
  default     = "prod"
}

# GitHub 配置
variable "github_username" {
  description = "GitHub 用户名"
  type        = string
}

variable "github_repo" {
  description = "GitHub 仓库名"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token（用于拉取 GHCR 镜像）"
  type        = string
  sensitive   = true
}

# 数据库配置
variable "db_username" {
  description = "RDS 数据库用户名"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS 数据库密码（建议使用 Secrets Manager）"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "数据库名称"
  type        = string
  default     = "blog"
}

variable "db_instance_class" {
  description = "RDS 实例类型"
  type        = string
  default     = "db.t3.micro"
}

# ECS 配置
variable "backend_cpu" {
  description = "后端服务 CPU 单位（1024 = 1 vCPU）"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "后端服务内存（MB）"
  type        = number
  default     = 1024
}

variable "frontend_cpu" {
  description = "前端服务 CPU 单位（1024 = 1 vCPU）"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "前端服务内存（MB）"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "每个服务的期望任务数量"
  type        = number
  default     = 1
}

# 网络配置
variable "vpc_cidr" {
  description = "VPC CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "可用区列表"
  type        = list(string)
  default     = []
}

# 标签
variable "common_tags" {
  description = "应用到所有资源的通用标签"
  type        = map(string)
  default = {
    Project     = "SimpleBlog"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

