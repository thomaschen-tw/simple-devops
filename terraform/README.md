# AWS Terraform 部署指南

## 📋 前提条件

1. ✅ **AWS CLI 已安装并配置 Profile**
   ```bash
   # 配置 AWS CLI profile（推荐方式）
   aws configure --profile company
   # 输入：
   # - AWS Access Key ID
   # - AWS Secret Access Key
   # - Default region: ap-southeast-1
   # - Default output format: json
   
   # 验证配置
   aws sts get-caller-identity --profile company
   ```
   
   **注意**：Terraform 会使用 `terraform.tfvars` 中指定的 profile 名称。

2. ✅ **Terraform 已安装**（版本 >= 1.0）
   ```bash
   terraform version
   ```

3. ✅ **GitHub Actions 已构建镜像**
   - 确保镜像已推送到 GHCR：`ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest`
   - 确保镜像已推送到 GHCR：`ghcr.io/YOUR_USERNAME/YOUR_REPO/frontend:latest`

4. ✅ **GitHub Secrets 配置**（用于 ECR 同步）
   - `AWS_ACCESS_KEY_ID`: AWS 访问密钥 ID
   - `AWS_SECRET_ACCESS_KEY`: AWS 秘密访问密钥
   - `AWS_ACCOUNT_ID`: AWS 账户 ID（12位数字）

## 🚀 快速开始

### 1. 配置变量

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

编辑 `terraform.tfvars`，填入实际值：

```hcl
aws_region   = "ap-southeast-1"  # AWS 区域（新加坡）
aws_profile  = "company"          # AWS CLI Profile 名称
project_name = "simple-blog"
environment  = "prod"

github_username = "thomaschen-tw"
github_repo     = "simple-devops"
# github_token 可选，如果使用 GHCR 私有镜像才需要

db_username = "admin"
db_password = "your_secure_password"  # 使用强密码！
db_name     = "blog"
```

**重要**：
- ✅ 当前配置使用 **ECR**（推荐），镜像会自动从 GHCR 同步到 ECR
- ✅ 使用 **AWS CLI Profile** 进行认证（`aws_profile = "company"`）
- ✅ 确保已配置 `aws configure --profile company`

### 2. 初始化 Terraform

```bash
terraform init
```

### 3. 规划部署

```bash
terraform plan
```

检查将要创建的资源，确保无误。

### 4. 应用配置

```bash
terraform apply
```

输入 `yes` 确认创建资源。

### 5. 获取访问地址

部署完成后，Terraform 会输出访问地址：

```bash
terraform output
```

输出示例：
```
alb_dns_name = "simple-blog-prod-alb-123456789.us-east-1.elb.amazonaws.com"
frontend_url = "http://simple-blog-prod-alb-123456789.us-east-1.elb.amazonaws.com"
backend_url = "http://simple-blog-prod-alb-123456789.us-east-1.elb.amazonaws.com:8000"
```

**访问说明**：
- 🌐 **前端**: `http://ALB_DNS/` - 访问前端应用
- 🔧 **后端 API**: `http://ALB_DNS/search`、`http://ALB_DNS/posts` 等 - 通过 ALB 路径路由自动转发到后端
- 📖 **API 文档**: `http://ALB_DNS/docs` - FastAPI 自动生成的文档

**注意**：前端使用相对路径访问后端 API，ALB 会自动将 API 路径路由到后端服务。

## 📁 文件结构

```
terraform/
├── main.tf              # Provider 和主配置
├── variables.tf         # 变量定义
├── terraform.tfvars     # 变量值（不提交到 Git）
├── vpc.tf               # VPC 网络配置
├── security.tf          # 安全组配置
├── rds.tf               # RDS 数据库配置
├── ecs.tf               # ECS 容器配置
├── alb.tf               # 负载均衡器配置
├── outputs.tf           # 输出定义
├── .gitignore          # Git 忽略文件
└── README.md           # 本文档
```

## 🏗️ 架构说明

### 网络架构

- **VPC**: `10.0.0.0/16`
- **Public Subnets**: 用于 ALB 和 NAT Gateway（2个可用区）
- **Private Subnets**: 用于 ECS 任务和 RDS（2个可用区）
- **Internet Gateway**: 提供公网访问
- **NAT Gateway**: 允许私有子网访问外网（拉取 GHCR 镜像）

### 应用架构

- **ECS Fargate**: 无服务器容器运行
  - Backend Service: FastAPI 后端
  - Frontend Service: React 前端
- **Application Load Balancer**: 应用层负载均衡
  - Port 80: 前端
  - Port 8000: 后端 API
- **RDS PostgreSQL**: 托管数据库（多可用区，高可用）

### 安全

- **Security Groups**: 最小权限原则
  - ALB: 允许 80/443 入站
  - ECS Tasks: 只允许 ALB 访问
  - RDS: 只允许 ECS Tasks 访问
- **Secrets Manager**: 存储 GitHub Token
- **IAM Roles**: 最小权限角色

## 🔧 常用命令

```bash
# 查看资源状态
terraform show

# 查看输出
terraform output

# 更新配置
terraform plan
terraform apply

# 销毁资源（谨慎操作！）
terraform destroy

# 查看特定资源
terraform state list
terraform state show aws_lb.main
```

## 📊 监控和日志

### CloudWatch Logs

- Backend 日志: `/ecs/simple-blog-prod/backend`
- Frontend 日志: `/ecs/simple-blog-prod/frontend`

查看日志：
```bash
aws logs tail /ecs/simple-blog-prod/backend --follow
```

### CloudWatch Metrics

- ECS: CPU、内存使用率
- RDS: 连接数、CPU、存储
- ALB: 请求数、响应时间、错误率

## 💰 成本估算

每月约 $110-150：
- ECS Fargate: ~$30-50
- RDS db.t3.micro: ~$15-20
- ALB: ~$20-25
- NAT Gateway: ~$35
- 数据传输: ~$10-20

## 🔄 更新部署

### 更新镜像

**方法一：自动更新（推荐）**

1. GitHub Actions 自动构建新镜像并推送到 GHCR
2. ECR 同步工作流自动将镜像同步到 ECR
3. 手动触发 ECS 服务更新：
   ```bash
   aws ecs update-service \
     --cluster simple-blog-prod-cluster \
     --service simple-blog-prod-backend \
     --force-new-deployment
   
   aws ecs update-service \
     --cluster simple-blog-prod-cluster \
     --service simple-blog-prod-frontend \
     --force-new-deployment
   ```

**方法二：手动同步镜像**

如果 ECR 同步工作流未启用，可以手动同步：

```bash
# 登录 GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 登录 ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 拉取 GHCR 镜像并推送到 ECR
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest
docker tag ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/simple-blog/prod/backend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/simple-blog/prod/backend:latest
```

### 更新配置

修改 Terraform 文件后：
```bash
terraform plan
terraform apply
```

## 🐛 故障排查

### ECS 任务无法启动

1. 检查 CloudWatch Logs
2. 检查任务定义中的镜像地址
3. 检查 Secrets Manager 中的 GitHub Token
4. 检查安全组配置

### 无法访问应用

1. 检查 ALB 健康检查状态
2. 检查安全组规则
3. 检查 ECS 任务状态
4. 检查 CloudWatch Logs

### 数据库连接失败

1. 检查 RDS 安全组
2. 检查 DATABASE_URL 环境变量
3. 检查 RDS 端点地址

## 📝 注意事项

1. ⚠️ **GitHub Token**: 确保 Token 有 `read:packages` 权限
2. ⚠️ **数据库密码**: 使用强密码，建议存储在 Secrets Manager
3. ⚠️ **成本控制**: NAT Gateway 会产生费用，考虑使用 VPC Endpoints
4. ⚠️ **备份**: RDS 自动备份已启用，保留 7 天
5. ⚠️ **高可用**: RDS 多可用区部署，ECS 服务可扩展到多个任务

## 🔐 安全建议

1. ✅ 使用 Secrets Manager 存储敏感信息
2. ✅ 启用 RDS 加密
3. ✅ 定期轮换数据库密码
4. ✅ 启用 CloudTrail 审计
5. ✅ 使用 WAF 保护 ALB（可选）

## 📚 参考文档

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Fargate](https://docs.aws.amazon.com/ecs/latest/developerguide/AWS_Fargate.html)
- [RDS PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)

