# Terraform AWS 部署快速开始

## 🚀 5 分钟快速部署

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
```

编辑 `terraform.tfvars`，至少修改：
- `github_username`
- `github_repo`
- `database_password`（强密码）

### 3. 部署

```bash
# 初始化
terraform init

# 预览
terraform plan

# 部署（输入 yes 确认）
terraform apply
```

### 4. 获取访问地址

```bash
terraform output frontend_url
terraform output backend_api_url
```

## 📋 完整步骤

### 步骤 1：准备 AWS 账号

1. 创建 AWS 账号（如果还没有）
2. 创建 IAM 用户并获取 Access Key
3. 配置 AWS CLI：

```bash
aws configure
# AWS Access Key ID: your_access_key
# AWS Secret Access Key: your_secret_key
# Default region: us-east-1
# Default output format: json
```

### 步骤 2：准备 Docker 镜像

确保 GitHub Actions 已构建并推送镜像到 GHCR：

```bash
# 检查镜像是否存在
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/frontend:latest
```

### 步骤 3：配置 Terraform

```bash
cd terraform

# 复制示例配置
cp terraform.tfvars.example terraform.tfvars

# 编辑配置
vim terraform.tfvars  # 或使用你喜欢的编辑器
```

**最小配置**（`terraform.tfvars`）：
```hcl
aws_region = "us-east-1"
project_name = "simple-devops"
environment = "dev"

github_username = "your-github-username"
github_repo = "your-repo-name"

database_password = "YourStrongPassword123!"
```

### 步骤 4：初始化 Terraform

```bash
terraform init
```

这会：
- 下载 AWS provider
- 初始化模块

### 步骤 5：预览变更

```bash
terraform plan
```

**检查输出**：
- 确认要创建的资源
- 检查配置是否正确
- 注意成本警告

### 步骤 6：部署

```bash
terraform apply
```

输入 `yes` 确认。

**部署时间**：约 10-15 分钟

### 步骤 7：验证部署

```bash
# 获取输出
terraform output

# 访问前端
curl $(terraform output -raw frontend_url)

# 访问后端健康检查
curl $(terraform output -raw backend_api_url)/healthz
```

## 🔧 配置选项

### 开发环境（低成本）

```hcl
database_instance_class = "db.t3.micro"
backend_cpu = 256
backend_memory = 512
backend_desired_count = 1
```

### 生产环境（高可用）

```hcl
database_instance_class = "db.t3.small"
backend_cpu = 1024
backend_memory = 2048
backend_desired_count = 2
min_capacity = 2
max_capacity = 10
```

## 📊 部署后检查清单

- [ ] ALB 健康检查通过
- [ ] 前端可以访问
- [ ] 后端 API 响应正常
- [ ] 数据库连接正常
- [ ] CloudWatch 日志正常
- [ ] Auto Scaling 配置正确

## 🗑️ 清理资源

```bash
# ⚠️ 警告：删除所有资源，包括数据库数据
terraform destroy
```

## 📚 更多信息

- [完整部署指南](AWS_DEPLOYMENT_GUIDE.md)
- [Terraform README](README.md)

