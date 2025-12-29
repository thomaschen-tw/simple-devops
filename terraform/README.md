# Terraform AWS 部署

使用 Terraform 将前后端应用部署到 AWS 云平台。

## 📋 架构概述

```
Internet → CloudFront (可选) → ALB → ECS Fargate (Backend/Frontend) → RDS PostgreSQL
```

### 核心组件

- **VPC**：虚拟私有云，包含公网和私网子网
- **RDS PostgreSQL**：托管数据库服务
- **ECS Fargate**：容器化应用服务（无服务器）
- **Application Load Balancer**：负载均衡和路由
- **S3 + CloudFront**：前端静态资源（可选，更便宜）

## 🚀 快速开始

### 1. 安装工具

```bash
# 安装 Terraform
brew install terraform

# 安装 AWS CLI
brew install awscli

# 配置 AWS 凭证
aws configure
```

### 2. 配置变量

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # 编辑配置
```

**最小配置**：
```hcl
aws_region = "us-east-1"
project_name = "simple-devops"
environment = "dev"

github_username = "your-github-username"
github_repo = "your-repo-name"
database_password = "YourStrongPassword123!"
```

### 3. 部署

```bash
terraform init
terraform plan
terraform apply
```

### 4. 获取访问地址

```bash
terraform output frontend_url
terraform output backend_api_url
```

## 📁 文件结构

```
terraform/
├── README.md                    # 本文档
├── QUICKSTART.md                # 快速开始指南
├── AWS_DEPLOYMENT_GUIDE.md      # 完整部署指南
├── AWS_ARCHITECTURE.md          # 架构说明
├── DEPLOYMENT_CHECKLIST.md      # 部署检查清单
├── main.tf                      # 主配置文件
├── variables.tf                 # 变量定义
├── outputs.tf                  # 输出定义
├── terraform.tfvars.example     # 变量示例
└── modules/
    ├── vpc/                     # VPC 模块
    ├── rds/                     # RDS 模块
    ├── alb/                     # ALB 模块
    ├── ecs-service/             # ECS 服务模块
    ├── ecr/                     # ECR 模块（可选）
    └── frontend/                # 前端模块（S3+CloudFront，可选）
```

## 🔧 配置说明

### 必需变量

- `aws_region`：AWS 区域
- `github_username`：GitHub 用户名
- `github_repo`：GitHub 仓库名
- `database_password`：RDS 数据库密码

### 可选变量

- `domain_name`：自定义域名
- `certificate_arn`：SSL 证书 ARN
- `database_instance_class`：RDS 实例类型
- `backend_cpu`、`backend_memory`：后端资源配置
- `min_capacity`、`max_capacity`：Auto Scaling 配置

## 💰 成本估算

### 开发环境（最小配置）
- **预计成本**：~$70-100/月
- RDS db.t3.micro：~$15
- ECS Fargate：~$10
- ALB：~$16
- NAT Gateway：~$32（可优化为 1 个）

### 生产环境（推荐配置）
- **预计成本**：~$180-240/月
- RDS db.t3.small Multi-AZ：~$60
- ECS Fargate（2 tasks）：~$120
- ALB：~$16
- NAT Gateway：~$64

**成本优化建议**：
- 使用 S3 + CloudFront 替代 ECS Frontend（节省 ~$30/月）
- 开发环境使用 1 个 NAT Gateway（节省 ~$32/月）

## 📚 文档

- [快速开始](QUICKSTART.md) - 5 分钟快速部署
- [完整部署指南](AWS_DEPLOYMENT_GUIDE.md) - 详细步骤和说明
- [架构说明](AWS_ARCHITECTURE.md) - 架构设计和组件说明
- [部署检查清单](DEPLOYMENT_CHECKLIST.md) - 部署前后检查项

## ⚠️ 重要提示

1. **数据库密码**：使用强密码，生产环境建议使用 AWS Secrets Manager
2. **镜像权限**：如果 GHCR 镜像私有，需要配置 `github_token`
3. **成本控制**：开发环境可以删除未使用的资源
4. **删除保护**：生产环境 RDS 有删除保护，需要先禁用才能删除

## 🔄 更新部署

```bash
# 修改配置后
terraform plan
terraform apply

# 更新应用（强制新部署）
aws ecs update-service \
  --cluster simple-devops-dev \
  --service simple-devops-dev-backend \
  --force-new-deployment
```

## 🗑️ 清理资源

```bash
# ⚠️ 警告：删除所有资源
terraform destroy
```

## 📖 更多信息

查看项目根目录的 [README.md](../README.md) 了解项目整体架构。
