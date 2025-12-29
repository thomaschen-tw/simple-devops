# Terraform AWS 部署 - 分步学习指南

本指南将带你一步步学习如何使用 Terraform 在 AWS 上部署应用。每个步骤都包含详细说明和实际操作。

## 📋 前置准备

### 1. 安装工具

```bash
# 安装 Terraform
brew install terraform  # macOS
# 或访问 https://www.terraform.io/downloads

# 安装 AWS CLI
brew install awscli  # macOS
# 或访问 https://aws.amazon.com/cli/

# 验证安装
terraform --version
aws --version
```

### 2. 配置 AWS 凭证

```bash
aws configure
# 输入：
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: ap-southeast-1
# - Default output format: json
```

### 3. 准备 Docker 镜像

确保 GitHub Actions 已构建并推送镜像到 GHCR：
- `ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest`
- `ghcr.io/YOUR_USERNAME/YOUR_REPO/frontend:latest`

## 🎯 学习路径

### 步骤 1：基础配置和 VPC 网络

**目标**：创建 VPC 网络基础设施

**学习内容**：
- Terraform 基础语法
- VPC、子网、路由表
- 公网和私网子网的区别

**配置文件**：`vpc.tf`

**操作步骤**：

1. 创建 `terraform.tfvars`：
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

2. 编辑 `terraform.tfvars`，设置基本变量：
```hcl
aws_region = "ap-southeast-1"
project_name = "simple-devops"
environment = "dev"
vpc_cidr = "10.0.0.0/16"
```

3. 初始化并部署：
```bash
terraform init
terraform plan  # 查看将要创建的资源
terraform apply  # 创建 VPC（输入 yes）
```

4. 验证：
```bash
terraform output  # 查看输出
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=simple-devops-dev-vpc"
```

**预期结果**：
- ✅ VPC 创建成功
- ✅ 2 个公网子网
- ✅ 2 个私网子网
- ✅ Internet Gateway
- ✅ NAT Gateway（2 个）

**清理**（可选）：
```bash
terraform destroy  # 删除所有资源
```

---

### 步骤 2：安全组配置

**目标**：创建安全组，控制网络访问

**学习内容**：
- Security Groups 的作用
- 入站和出站规则
- 安全组之间的引用

**配置文件**：`security.tf`

**操作步骤**：

1. 部署（`security.tf` 中的资源已经定义好）：
```bash
terraform plan
terraform apply
```

2. 验证：
```bash
# 查看安全组
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=simple-devops-dev-*"
```

**预期结果**：
- ✅ ALB 安全组创建（允许 80/443）
- ✅ ECS Tasks 安全组创建（允许从 ALB 访问）
- ✅ RDS 安全组创建（允许从 ECS 访问 5432）

**学习要点**：
- 安全组是防火墙规则
- 可以基于安全组 ID 引用
- 最小权限原则

---

### 步骤 3：Application Load Balancer

**目标**：创建负载均衡器

**学习内容**：
- ALB 配置
- Target Groups
- Listener 和路由规则
- 安全组配置

**配置文件**：`alb.tf`

**操作步骤**：

1. 部署（`alb.tf` 中的资源已经定义好）：
```bash
terraform plan
terraform apply
```

2. 验证：
```bash
# 获取 ALB DNS 名称
terraform output alb_dns_name

# 测试访问（应该返回 404 或默认响应）
curl http://$(terraform output -raw alb_dns_name)
```

**预期结果**：
- ✅ ALB 创建成功
- ✅ DNS 名称可访问
- ✅ Target Groups 创建（但还没有目标）

**学习要点**：
- ALB 在公网子网
- Target Groups 用于路由流量
- Listener 监听端口（80/443）

---

### 步骤 4：RDS 数据库

**目标**：创建 PostgreSQL 数据库

**学习内容**：
- RDS 配置
- 安全组规则
- 数据库连接字符串

**配置文件**：`rds.tf`

**操作步骤**：

1. 在 `terraform.tfvars` 中添加数据库配置：
```hcl
database_name = "demo"
database_username = "demo"
database_password = "YourStrongPassword123!"  # ⚠️ 请修改
database_instance_class = "db.t3.micro"
```

2. 部署：
```bash
terraform plan
terraform apply
```

3. 验证：
```bash
# 查看 RDS 状态
aws rds describe-db-instances \
  --db-instance-identifier simple-devops-dev-db

# 获取数据库 endpoint
terraform output rds_endpoint
```

**预期结果**：
- ✅ RDS 实例创建成功
- ✅ 状态为 `available`
- ✅ 在私网子网中
- ✅ 安全组允许 ECS 访问

**学习要点**：
- RDS 在私网子网，不直接暴露到公网
- 通过安全组控制访问
- 数据库密码要强密码

---

### 步骤 5：ECS 集群和服务

**目标**：部署容器化应用

**学习内容**：
- ECS Fargate
- Task Definition
- Service 配置
- 容器健康检查

**配置文件**：`ecs.tf`

**操作步骤**：

1. 在 `terraform.tfvars` 中添加 ECS 配置：
```hcl
github_username = "your-github-username"
github_repo = "your-repo-name"

backend_cpu = 512
backend_memory = 1024
backend_desired_count = 1

frontend_cpu = 256
frontend_memory = 512
frontend_desired_count = 1
```

2. 部署：
```bash
terraform plan
terraform apply
```

3. 验证：
```bash
# 查看 ECS 服务状态
aws ecs describe-services \
  --cluster simple-devops-dev-cluster \
  --services simple-devops-dev-backend

# 查看任务状态
aws ecs list-tasks --cluster simple-devops-dev-cluster

# 测试应用
curl http://$(terraform output -raw alb_dns_name)/healthz
curl http://$(terraform output -raw alb_dns_name)
```

**预期结果**：
- ✅ ECS Cluster 创建
- ✅ Backend Service 运行
- ✅ Frontend Service 运行
- ✅ 任务状态为 `RUNNING`
- ✅ 健康检查通过

**学习要点**：
- ECS 任务在私网子网
- 通过 ALB 访问
- 容器镜像从 GHCR 拉取
- 环境变量自动配置

---

### 步骤 6：完整部署和验证

**目标**：验证完整应用

**操作步骤**：

1. 获取访问地址：
```bash
terraform output frontend_url
terraform output backend_api_url
```

2. 测试功能：
```bash
# 健康检查
curl $(terraform output -raw backend_api_url)/healthz

# 搜索功能
curl "$(terraform output -raw backend_api_url)/search?q=test"

# 前端访问
curl $(terraform output -raw frontend_url)
```

3. 查看日志：
```bash
# 后端日志
aws logs tail /ecs/simple-devops-dev/backend --follow

# 前端日志
aws logs tail /ecs/simple-devops-dev/frontend --follow
```

4. 监控资源：
```bash
# ECS 服务状态
aws ecs describe-services \
  --cluster simple-devops-dev-cluster \
  --services simple-devops-dev-backend simple-devops-dev-frontend

# RDS 状态
aws rds describe-db-instances \
  --db-instance-identifier simple-devops-dev-db
```

**预期结果**：
- ✅ 前端可以访问
- ✅ 后端 API 正常响应
- ✅ 搜索功能正常
- ✅ 数据库连接正常

---

## 📚 配置文件说明

### 核心文件

- `main.tf`：Provider 配置和数据源
- `locals.tf`：本地变量定义
- `variables.tf`：变量定义
- `outputs.tf`：输出定义
- `terraform.tfvars`：变量值（不提交到 Git）

### 资源文件

- `vpc.tf`：VPC 网络配置
- `security.tf`：安全组配置
- `alb.tf`：负载均衡器配置
- `rds.tf`：RDS 数据库配置
- `ecs.tf`：ECS 服务配置
- `versions.tf`：Terraform 版本要求

### 可选文件

- `ecr-sync.tf`：ECR 镜像同步（如果使用 ECR）

## 🔧 常用命令

### Terraform 命令

```bash
# 初始化
terraform init

# 格式化代码
terraform fmt

# 验证配置
terraform validate

# 预览变更
terraform plan

# 应用变更
terraform apply

# 查看输出
terraform output

# 删除资源
terraform destroy
```

### AWS CLI 命令

```bash
# 查看 VPC
aws ec2 describe-vpcs

# 查看 RDS
aws rds describe-db-instances

# 查看 ECS 服务
aws ecs describe-services --cluster <cluster-name>

# 查看日志
aws logs tail <log-group-name> --follow
```

## 💡 学习建议

1. **循序渐进**：按步骤 1-6 顺序学习
2. **理解概念**：每个步骤都要理解其作用
3. **动手实践**：每步都要实际操作
4. **查看文档**：遇到问题查看 AWS 文档
5. **清理资源**：学习完成后及时清理，避免费用

## ⚠️ 注意事项

1. **成本控制**：
   - 学习完成后及时 `terraform destroy`
   - 开发环境使用最小配置
   - 监控 AWS 账单

2. **安全**：
   - 数据库密码使用强密码
   - 不要提交 `terraform.tfvars` 到 Git
   - 使用 IAM 最小权限原则

3. **故障排查**：
   - 查看 CloudWatch 日志
   - 检查安全组规则
   - 验证网络连接

## 🎓 下一步学习

完成基础部署后，可以学习：

1. **Auto Scaling**：自动扩缩容配置
2. **监控告警**：CloudWatch Alarms
3. **CI/CD 集成**：GitHub Actions 自动部署
4. **多环境管理**：dev/staging/prod
5. **成本优化**：使用 S3 + CloudFront 替代 ECS Frontend

## 📖 参考资源

- [Terraform AWS Provider 文档](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS 文档](https://docs.aws.amazon.com/ecs/)
- [AWS RDS 文档](https://docs.aws.amazon.com/rds/)
- [Terraform 官方文档](https://www.terraform.io/docs)
