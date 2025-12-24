# Terraform 初学者完整指南

## 📚 什么是 Terraform？

Terraform 是一个**基础设施即代码（Infrastructure as Code, IaC）**工具，让你可以用代码定义和管理云资源（如服务器、数据库、网络等）。

### 核心概念

1. **配置文件（.tf 文件）**：描述你想要创建的资源
2. **状态文件（.tfstate）**：记录实际创建的资源
3. **Provider**：连接 Terraform 和云服务（如 AWS）
4. **Resource**：具体的资源（如 VPC、EC2、RDS）

## 🎯 本项目的 Terraform 文件结构

```
terraform/
├── versions.tf              # Terraform 版本要求
├── main.tf                  # Provider 配置和核心变量
├── variables.tf             # 变量定义（输入）
├── outputs.tf              # 输出定义（结果）
├── vpc.tf                   # VPC 网络配置
├── security.tf              # 安全组配置
├── rds.tf                   # 数据库配置
├── ecs.tf                   # 容器服务配置
├── alb.tf                   # 负载均衡器配置
├── ecr-sync.tf              # 镜像仓库配置
├── terraform.tfvars.example # 变量值示例
└── README.md                # 使用文档
```

## 📝 每个文件的作用

### 1. versions.tf - 版本约束

**作用**：指定 Terraform 和 Provider 的版本要求

```hcl
terraform {
  required_version = ">= 1.0"  # Terraform 版本要求
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # AWS Provider 版本要求
    }
  }
}
```

**为什么需要**：确保所有人使用兼容的版本，避免版本差异导致的问题。

### 2. main.tf - 主配置文件

**作用**：
- 配置 AWS Provider（连接 AWS）
- 定义本地变量（计算值）
- 获取 AWS 账户信息

```hcl
provider "aws" {
  region  = var.aws_region    # 使用变量中的区域
  profile = var.aws_profile   # 使用 AWS CLI profile
}

# 获取当前 AWS 账户 ID
data "aws_caller_identity" "current" {}

# 本地变量（用于计算）
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  backend_image = "..."
}
```

**关键点**：
- `provider`：告诉 Terraform 使用哪个云服务商和如何认证
- `profile = "company"`：使用 AWS CLI 配置的 profile
- `locals`：定义只在当前模块内使用的变量

### 3. variables.tf - 变量定义

**作用**：定义所有可配置的变量（输入参数）

```hcl
variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile 名称"
  type        = string
  default     = "company"
}
```

**变量类型**：
- `string`：字符串
- `number`：数字
- `bool`：布尔值
- `list`：列表
- `map`：键值对

**为什么需要**：让配置可重用，不同环境使用不同的值。

### 4. terraform.tfvars - 变量值

**作用**：为变量提供实际值（不提交到 Git）

```hcl
aws_region   = "ap-southeast-1"
aws_profile  = "company"
project_name = "simple-blog"
db_password  = "your_password"
```

**重要**：此文件包含敏感信息，不要提交到 Git！

### 5. vpc.tf - 网络配置

**作用**：创建 VPC、子网、网关等网络资源

```hcl
# 创建 VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # ...
}

# 创建子网
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  # ...
}
```

**资源命名**：
- `aws_vpc.main`：资源类型 + 资源名称
- `main` 是你在代码中给这个 VPC 起的名字

### 6. security.tf - 安全组

**作用**：定义防火墙规则（允许/拒绝哪些流量）

```hcl
resource "aws_security_group" "alb" {
  # 允许 HTTP 流量
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**安全组**：就像防火墙，控制谁可以访问你的资源。

### 7. rds.tf - 数据库配置

**作用**：创建 PostgreSQL 数据库

```hcl
resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.t3.micro"
  # ...
}
```

### 8. ecs.tf - 容器配置

**作用**：创建 ECS 集群、任务定义和服务

```hcl
# ECS 集群
resource "aws_ecs_cluster" "main" {
  name = "simple-blog-prod-cluster"
}

# 任务定义（容器配置）
resource "aws_ecs_task_definition" "backend" {
  container_definitions = jsonencode([...])
}

# ECS 服务（运行容器）
resource "aws_ecs_service" "backend" {
  # ...
}
```

### 9. alb.tf - 负载均衡器

**作用**：创建 Application Load Balancer，分发流量

```hcl
resource "aws_lb" "main" {
  load_balancer_type = "application"
  # ...
}
```

### 10. outputs.tf - 输出定义

**作用**：定义部署后输出的信息

```hcl
output "frontend_url" {
  value = "http://${aws_lb.main.dns_name}"
}
```

**用途**：部署完成后，可以快速获取重要信息（如访问地址）。

## 🚀 完整部署流程（初学者版）

### 步骤 1: 安装 Terraform

**macOS**:
```bash
brew install terraform
```

**验证安装**:
```bash
terraform version
```

### 步骤 2: 配置 AWS CLI Profile

```bash
# 配置 AWS CLI profile
aws configure --profile company

# 输入以下信息：
# AWS Access Key ID: [你的 Access Key]
# AWS Secret Access Key: [你的 Secret Key]
# Default region name: ap-southeast-1
# Default output format: json

# 验证配置
aws sts get-caller-identity --profile company
```

**输出示例**：
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

### 步骤 3: 准备 Terraform 配置

```bash
cd terraform

# 复制变量示例文件
cp terraform.tfvars.example terraform.tfvars

# 编辑 terraform.tfvars（使用你喜欢的编辑器）
nano terraform.tfvars
# 或
vim terraform.tfvars
```

**编辑 terraform.tfvars**：
```hcl
aws_region   = "ap-southeast-1"
aws_profile  = "company"  # 使用你配置的 profile 名称
project_name = "simple-blog"
environment  = "prod"

github_username = "thomaschen-tw"
github_repo     = "simple-devops"

db_username = "admin"
db_password = "YourSecurePassword123!"  # 使用强密码
db_name     = "blog"
```

### 步骤 4: 初始化 Terraform

```bash
terraform init
```

**这个命令做了什么**：
1. 下载 AWS Provider 插件
2. 创建 `.terraform` 目录（存储插件）
3. 初始化后端（如果配置了）

**输出示例**：
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
Terraform has been successfully initialized!
```

### 步骤 5: 验证配置（可选）

```bash
# 验证语法
terraform validate

# 格式化代码
terraform fmt
```

### 步骤 6: 规划部署

```bash
terraform plan
```

**这个命令做了什么**：
1. 读取所有 `.tf` 文件
2. 检查当前 AWS 资源状态
3. 计算需要创建/修改/删除的资源
4. 显示变更计划（不会实际创建）

**输出说明**：
- `+`：将创建新资源
- `~`：将修改现有资源
- `-`：将删除资源
- `-/+`：将替换资源

**示例输出**：
```
Plan: 35 to add, 0 to change, 0 to destroy.
```

### 步骤 7: 应用配置

```bash
terraform apply
```

**交互式确认**：
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

**自动确认**（跳过确认）：
```bash
terraform apply -auto-approve
```

**这个命令做了什么**：
1. 创建所有定义的资源
2. 等待资源就绪
3. 保存状态到 `.tfstate` 文件

**预计时间**：10-15 分钟（创建 RDS 需要时间）

### 步骤 8: 查看输出

```bash
terraform output
```

**输出示例**：
```
alb_dns_name = "simple-blog-prod-alb-xxxxx.ap-southeast-1.elb.amazonaws.com"
frontend_url = "http://simple-blog-prod-alb-xxxxx.ap-southeast-1.elb.amazonaws.com"
```

### 步骤 9: 同步镜像到 ECR

部署完成后，需要将 GitHub Actions 构建的镜像同步到 ECR：

```bash
# 获取 AWS 账户 ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile company --query Account --output text)

# 登录 ECR
aws ecr get-login-password --profile company --region ap-southeast-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com

# 登录 GHCR（需要 GitHub Token）
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 同步后端镜像
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest
docker tag ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com/simple-blog/prod/backend:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com/simple-blog/prod/backend:latest

# 同步前端镜像
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/frontend:latest
docker tag ghcr.io/YOUR_USERNAME/YOUR_REPO/frontend:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com/simple-blog/prod/frontend:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com/simple-blog/prod/frontend:latest
```

## 🔍 Terraform 命令详解

### 基础命令

| 命令 | 作用 | 何时使用 |
|------|------|----------|
| `terraform init` | 初始化工作目录 | 首次使用或添加新 Provider |
| `terraform plan` | 显示执行计划 | 部署前检查变更 |
| `terraform apply` | 应用配置 | 创建/更新资源 |
| `terraform destroy` | 删除所有资源 | 清理环境 |
| `terraform validate` | 验证配置语法 | 检查配置错误 |
| `terraform fmt` | 格式化代码 | 统一代码风格 |
| `terraform show` | 显示当前状态 | 查看已创建的资源 |
| `terraform output` | 显示输出值 | 获取重要信息 |

### 状态管理

```bash
# 查看状态文件内容
terraform state list          # 列出所有资源
terraform state show aws_vpc.main  # 查看特定资源

# 刷新状态（从 AWS 同步）
terraform refresh

# 导入现有资源（如果资源已存在）
terraform import aws_vpc.main vpc-xxxxx
```

## 📖 理解 Terraform 语法

### 资源定义

```hcl
resource "资源类型" "资源名称" {
  参数名 = 值
  参数名 = 值
}
```

**示例**：
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}
```

### 引用其他资源

```hcl
# 引用 VPC 的 ID
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id  # 引用上面定义的 VPC
}
```

### 使用变量

```hcl
# 定义变量
variable "region" {
  type = string
}

# 使用变量
provider "aws" {
  region = var.region
}
```

### 使用输出

```hcl
# 定义输出
output "vpc_id" {
  value = aws_vpc.main.id
}

# 在其他资源中引用
resource "aws_subnet" "example" {
  vpc_id = aws_vpc.main.id
}
```

## 🐛 常见问题

### Q1: `terraform init` 失败

**错误**：`Error: Failed to query available provider packages`

**解决**：
```bash
# 检查网络连接
ping registry.terraform.io

# 使用代理（如果需要）
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port
```

### Q2: `terraform plan` 显示认证错误

**错误**：`Error: NoValidCredentialSources`

**解决**：
```bash
# 检查 AWS profile 配置
aws configure list --profile company

# 测试 AWS 连接
aws sts get-caller-identity --profile company

# 确保 terraform.tfvars 中 profile 名称正确
```

### Q3: 资源创建失败

**解决**：
1. 查看错误信息
2. 检查 AWS 权限
3. 检查资源限制（如 VPC 数量）
4. 查看 CloudWatch Logs

### Q4: 如何更新单个资源？

```bash
# 只更新特定资源
terraform apply -target=aws_ecs_service.backend

# 替换资源（删除后重建）
terraform taint aws_db_instance.main
terraform apply
```

## 📚 学习资源

1. **Terraform 官方文档**：https://www.terraform.io/docs
2. **AWS Provider 文档**：https://registry.terraform.io/providers/hashicorp/aws/latest/docs
3. **Terraform 最佳实践**：https://www.terraform.io/docs/cloud/guides/recommended-practices

## ✅ 检查清单

部署前检查：

- [ ] Terraform 已安装
- [ ] AWS CLI 已配置 profile
- [ ] `terraform.tfvars` 已配置
- [ ] GitHub Actions 已构建镜像
- [ ] 有足够的 AWS 权限
- [ ] 了解预计成本

部署后检查：

- [ ] `terraform apply` 成功完成
- [ ] 镜像已同步到 ECR
- [ ] ECS 服务正常运行
- [ ] 可以访问前端
- [ ] 可以访问后端 API

## 🎓 下一步学习

1. **理解状态文件**：`.tfstate` 的作用和管理
2. **模块化**：将配置拆分为可重用的模块
3. **远程状态**：使用 S3 存储状态文件
4. **工作空间**：管理多个环境（dev/staging/prod）
5. **变量验证**：添加变量验证规则

## 💡 最佳实践

1. ✅ **版本控制**：所有 `.tf` 文件提交到 Git
2. ✅ **敏感信息**：使用 `terraform.tfvars`（不提交）
3. ✅ **状态文件**：使用远程后端（S3）
4. ✅ **代码审查**：`terraform plan` 后审查变更
5. ✅ **标签**：为所有资源添加标签
6. ✅ **文档**：保持 README 更新

## 🎯 快速参考

```bash
# 完整部署流程
cd terraform
cp terraform.tfvars.example terraform.tfvars
# 编辑 terraform.tfvars
terraform init
terraform plan
terraform apply

# 查看输出
terraform output

# 更新资源
terraform plan
terraform apply

# 删除所有资源
terraform destroy
```

祝你部署顺利！🚀

