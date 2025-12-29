variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "simple-devops"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# GitHub Container Registry 配置
variable "github_username" {
  description = "GitHub username for pulling images from GHCR"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_token" {
  description = "GitHub token for pulling private images (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

# 数据库配置
variable "database_name" {
  description = "RDS database name"
  type        = string
  default     = "demo"
}

variable "database_username" {
  description = "RDS master username"
  type        = string
  default     = "demo"
}

variable "database_password" {
  description = "RDS master password (should use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

# ECS 配置
variable "backend_cpu" {
  description = "Backend ECS task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Backend ECS task memory in MB"
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

variable "frontend_cpu" {
  description = "Frontend ECS task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Frontend ECS task memory in MB"
  type        = number
  default     = 512
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}

# Auto Scaling 配置
variable "min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 10
}

# 网络配置
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# 域名和证书（可选）
variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = ""
}

# 标签
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "simple-devops"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

