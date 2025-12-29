# Terraform AWS 部署

使用 Terraform 将前后端应用部署到 AWS 云平台。

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
aws_region = "ap-southeast-1"
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

## 📚 学习路径

**推荐**：如果你是 Terraform 新手，请按照 **[分步学习指南](STEP_BY_STEP_GUIDE.md)** 一步步学习。

### 分步学习指南

1. **步骤 1**：VPC 网络基础设施（`vpc.tf`）
2. **步骤 2**：安全组配置（`security.tf`）
3. **步骤 3**：Application Load Balancer（`alb.tf`）
4. **步骤 4**：RDS 数据库（`rds.tf`）
5. **步骤 5**：ECS 集群和服务（`ecs.tf`）
6. **步骤 6**：完整部署和验证

每个步骤都包含：
- 📖 学习内容说明
- 🔧 操作步骤
- ✅ 验证方法
- 💡 学习要点

👉 **[开始学习](STEP_BY_STEP_GUIDE.md)**

## 📁 文件结构

```
terraform/
├── README.md                    # 本文档
├── STEP_BY_STEP_GUIDE.md       # 分步学习指南 ⭐
├── CONFIGURATION_SUMMARY.md     # 配置总结文档
├── GHCR_TO_ECS_GUIDE.md        # GHCR 镜像配置
│
├── main.tf                      # Provider 配置和数据源
├── locals.tf                    # 本地变量定义
├── variables.tf                 # 变量定义
├── outputs.tf                   # 输出定义
├── versions.tf                  # Terraform 版本要求
│
├── vpc.tf                       # 步骤 1：VPC 网络配置
├── security.tf                  # 步骤 2：安全组配置
├── alb.tf                       # 步骤 3：负载均衡器配置
├── rds.tf                       # 步骤 4：RDS 数据库配置
├── ecs.tf                       # 步骤 5：ECS 服务配置
│
├── terraform.tfvars.example     # 变量示例
└── ecr-sync.tf                  # 可选：ECR 镜像同步
```

## 🏗️ 架构概述

```
Internet
    ↓
Application Load Balancer (ALB)
    ├── /api/* → ECS Backend (Fargate)
    └── /* → ECS Frontend (Fargate)
    ↓
RDS PostgreSQL
```

### 核心组件

- **VPC**：虚拟私有云，包含公网和私网子网
- **Security Groups**：安全组，控制网络访问
- **RDS PostgreSQL**：托管数据库服务
- **ECS Fargate**：容器化应用服务（无服务器）
- **Application Load Balancer**：负载均衡和路由

## 🔧 配置说明

### 必需变量

- `aws_region`：AWS 区域（默认：`ap-southeast-1`）
- `github_username`：GitHub 用户名
- `github_repo`：GitHub 仓库名
- `database_password`：RDS 数据库密码

### 可选变量

- `availability_zones`：可用区列表（留空自动检测）
- `domain_name`：自定义域名
- `certificate_arn`：SSL 证书 ARN
- `database_instance_class`：RDS 实例类型（默认：`db.t3.micro`）
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
- 开发环境使用单可用区（`multi_az = false`）
- 开发环境使用 1 个 NAT Gateway（节省 ~$32/月）

## ⚠️ 重要提示

1. **数据库密码**：使用强密码，生产环境建议使用 AWS Secrets Manager
2. **镜像权限**：如果 GHCR 镜像私有，需要配置 `github_token`
3. **成本控制**：学习完成后及时 `terraform destroy`，避免费用
4. **删除保护**：生产环境 RDS 有删除保护，需要先禁用才能删除

## 🔄 更新部署

```bash
# 修改配置后
terraform plan
terraform apply

# 更新应用（强制新部署）
aws ecs update-service \
  --cluster simple-devops-dev-cluster \
  --service simple-devops-dev-backend \
  --force-new-deployment
```

## 🗑️ 清理资源

```bash
# ⚠️ 警告：删除所有资源
terraform destroy
```

## 📖 更多信息

- [分步学习指南](STEP_BY_STEP_GUIDE.md) - 详细的学习路径
- [配置总结文档](CONFIGURATION_SUMMARY.md) - 配置结构和说明
- [GHCR 到 ECS 指南](GHCR_TO_ECS_GUIDE.md) - 镜像配置说明

查看项目根目录的 [README.md](../README.md) 了解项目整体架构。
