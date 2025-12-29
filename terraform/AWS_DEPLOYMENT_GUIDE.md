# AWS 部署完整指南

## 📋 概述

本指南说明如何使用 Terraform 将前后端应用部署到 AWS。

## 🏗️ 架构设计

### 部署架构

```
Internet
    ↓
CloudFront (CDN) ← S3 (前端静态文件)
    ↓
Application Load Balancer (ALB)
    ├── /api/* → Backend ECS Fargate (多AZ)
    └── /* → Frontend ECS Fargate (多AZ)
    ↓
RDS PostgreSQL (Multi-AZ)
```

### 组件说明

1. **VPC 网络**
   - VPC：10.0.0.0/16
   - Public Subnets：公网子网（ALB）
   - Private Subnets：私网子网（ECS、RDS）
   - NAT Gateway：私网访问互联网

2. **前端**
   - **选项 A**：S3 + CloudFront（静态文件，推荐）
   - **选项 B**：ECS Fargate（容器化，当前配置）

3. **后端**
   - ECS Fargate：容器化后端服务
   - Auto Scaling：基于 CPU/内存自动扩缩容
   - Application Load Balancer：负载均衡和路由

4. **数据库**
   - RDS PostgreSQL 15
   - Multi-AZ（生产环境）
   - 自动备份和快照

## 🚀 部署步骤

### 1. 前提条件

#### 安装工具

```bash
# 安装 Terraform
brew install terraform  # macOS
# 或下载：https://www.terraform.io/downloads

# 安装 AWS CLI
brew install awscli  # macOS
# 或下载：https://aws.amazon.com/cli/
```

#### 配置 AWS 凭证

```bash
# 方法一：使用 AWS CLI 配置
aws configure
# 输入：Access Key ID, Secret Access Key, Region

# 方法二：设置环境变量
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

#### 准备 Docker 镜像

**选项 A：使用 GHCR（GitHub Container Registry）**
- 确保 GitHub Actions 已构建并推送镜像
- 镜像格式：`ghcr.io/USERNAME/REPO/backend:latest`

**选项 B：使用 ECR（Amazon Elastic Container Registry）**
- 使用 Terraform 创建的 ECR 仓库
- 推送镜像到 ECR

### 2. 配置 Terraform 变量

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

编辑 `terraform.tfvars`：

```hcl
aws_region = "us-east-1"
project_name = "simple-devops"
environment = "dev"

# GitHub 配置
github_username = "your-github-username"
github_repo = "your-repo-name"
# github_token = "your-github-token"  # 如果镜像私有

# 数据库配置
database_password = "YourStrongPassword123!"  # ⚠️ 请修改为强密码

# ECS 配置
backend_cpu = 512
backend_memory = 1024
backend_desired_count = 1

frontend_cpu = 256
frontend_memory = 512
frontend_desired_count = 1

# Auto Scaling
min_capacity = 1
max_capacity = 10
```

### 3. 初始化 Terraform

```bash
terraform init
```

这会下载 AWS provider 和初始化模块。

### 4. 预览变更

```bash
terraform plan
```

这会显示将要创建的资源。**仔细检查**，确保配置正确。

### 5. 部署

```bash
terraform apply
```

输入 `yes` 确认部署。

**部署时间**：约 10-15 分钟（创建 RDS 需要时间）

### 6. 获取输出

```bash
terraform output
```

输出包括：
- `frontend_url`：前端访问地址
- `backend_api_url`：后端 API 地址
- `alb_dns_name`：ALB DNS 名称
- `rds_endpoint`：RDS 数据库地址

## 🔧 配置说明

### 环境变量

后端容器会自动配置：
- `DATABASE_URL`：从 RDS endpoint 自动生成

前端容器会自动配置：
- `VITE_API_BASE_URL`：指向后端 API

### 健康检查

- **后端**：`/healthz` 端点
- **前端**：`/` 根路径

### Auto Scaling

ECS 服务会根据以下指标自动扩缩容：
- CPU 使用率 > 70%：扩容
- 内存使用率 > 80%：扩容
- 低于阈值：缩容（冷却期 5 分钟）

## 📊 资源清单

### 创建的资源

**网络**：
- 1x VPC
- 2x Public Subnets
- 2x Private Subnets
- 1x Internet Gateway
- 2x NAT Gateways
- 路由表和关联

**计算**：
- 1x ECS Cluster
- 1x ECS Backend Service
- 1x ECS Frontend Service
- 2x ECS Task Definitions
- Auto Scaling 配置

**负载均衡**：
- 1x Application Load Balancer
- 2x Target Groups
- 2x Security Groups

**数据库**：
- 1x RDS PostgreSQL Instance
- 1x DB Subnet Group
- 1x DB Parameter Group
- 1x Security Group

**存储**（如果使用 S3 + CloudFront）：
- 1x S3 Bucket
- 1x CloudFront Distribution

**监控**：
- 2x CloudWatch Log Groups

## 💰 成本优化

### 开发环境（最小配置）

```hcl
database_instance_class = "db.t3.micro"
backend_cpu = 256          # 0.25 vCPU
backend_memory = 512       # 0.5 GB
frontend_cpu = 256
frontend_memory = 512
```

**预计成本**：~$50-70/月

### 生产环境（推荐配置）

```hcl
database_instance_class = "db.t3.small"  # Multi-AZ
backend_cpu = 1024         # 1 vCPU
backend_memory = 2048      # 2 GB
backend_desired_count = 2  # 多实例
```

**预计成本**：~$150-200/月

### 成本优化建议

1. **使用 Spot Instances**（ECS Fargate 不支持，但可以考虑 EC2）
2. **使用 Reserved Instances**（RDS）
3. **删除未使用的 NAT Gateway**（开发环境可以只用一个）
4. **使用 S3 + CloudFront** 替代 ECS Frontend（更便宜）

## 🔐 安全最佳实践

### 1. 使用 AWS Secrets Manager

```hcl
# 在 variables.tf 中
variable "database_password" {
  # 从 Secrets Manager 获取
  # 不要硬编码密码
}
```

### 2. 启用加密

- RDS：存储加密已启用
- ECS：传输加密（HTTPS）
- S3：服务器端加密

### 3. 网络安全

- ECS 在 Private Subnets（不直接暴露）
- RDS 在 Private Subnets（只能从 ECS 访问）
- Security Groups：最小权限原则

### 4. IAM 角色

- ECS Task Execution Role：最小权限
- 不使用 root 凭证

## 🔄 更新部署

### 更新应用代码

```bash
# 1. 推送代码到 GitHub
git push

# 2. 等待 GitHub Actions 构建新镜像

# 3. 更新 ECS 服务（强制新部署）
aws ecs update-service \
  --cluster simple-devops-dev \
  --service simple-devops-dev-backend \
  --force-new-deployment

# 或使用 Terraform
terraform apply  # 如果镜像标签改变
```

### 更新基础设施

```bash
# 修改 terraform 配置
vim terraform.tfvars

# 预览变更
terraform plan

# 应用变更
terraform apply
```

## 🗑️ 删除部署

```bash
# ⚠️ 警告：这会删除所有资源，包括数据库数据！

terraform destroy
```

**注意**：
- RDS 有删除保护（生产环境）
- 需要先禁用删除保护：`aws rds modify-db-instance --db-instance-identifier ... --no-deletion-protection`

## 📚 相关文档

- [Terraform AWS Provider 文档](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Fargate 文档](https://docs.aws.amazon.com/ecs/latest/developerguide/AWS_Fargate.html)
- [RDS PostgreSQL 文档](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)

## ⚠️ 常见问题

### 1. ECS 任务无法启动

**检查**：
- 镜像是否正确拉取
- 安全组配置是否正确
- 子网是否有 NAT Gateway

### 2. 无法连接到数据库

**检查**：
- RDS 安全组是否允许 ECS 访问
- DATABASE_URL 是否正确
- RDS 是否在运行

### 3. ALB 健康检查失败

**检查**：
- 容器健康检查路径是否正确
- 安全组是否允许 ALB 访问容器
- 容器是否正常启动

## 🎯 下一步

1. **配置域名**：使用 Route 53 和 ACM 证书
2. **设置监控**：CloudWatch Alarms 和 Dashboards
3. **配置 CI/CD**：GitHub Actions 自动部署到 AWS
4. **备份策略**：RDS 自动备份和快照

