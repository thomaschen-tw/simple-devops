# 🚀 AWS Terraform 快速开始指南

## 5 分钟快速部署

### 步骤 1: 配置 AWS CLI Profile

```bash
# 配置 AWS CLI profile（推荐方式）
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

**说明**：使用 profile 的好处是可以管理多个 AWS 账户，切换方便。

### 步骤 2: 配置 Terraform 变量

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

编辑 `terraform.tfvars`：

```hcl
aws_region   = "us-east-1"
project_name = "simple-blog"
environment  = "prod"

github_username = "thomaschen-tw"  # 替换为你的 GitHub 用户名
github_repo     = "simple-devops"  # 替换为你的仓库名

db_username = "admin"
db_password = "YourSecurePassword123!"  # 使用强密码
db_name     = "blog"
```

### 步骤 3: 配置 GitHub Secrets（用于 ECR 同步）

在 GitHub 仓库中添加 Secrets：

1. 进入仓库 → Settings → Secrets and variables → Actions
2. 添加以下 Secrets：
   - `AWS_ACCESS_KEY_ID`: 你的 AWS Access Key ID
   - `AWS_SECRET_ACCESS_KEY`: 你的 AWS Secret Access Key
   - `AWS_ACCOUNT_ID`: 你的 AWS 账户 ID（12位数字）

获取 AWS 账户 ID：
```bash
aws sts get-caller-identity --query Account --output text
```

### 步骤 4: 初始化 Terraform

```bash
terraform init
```

### 步骤 5: 规划部署

```bash
terraform plan
```

检查将要创建的资源（约 30+ 个资源）。

### 步骤 6: 应用配置

```bash
terraform apply
```

输入 `yes` 确认。部署过程约 10-15 分钟。

### 步骤 7: 同步镜像到 ECR

部署完成后，需要手动同步一次镜像（后续 GitHub Actions 会自动同步）：

```bash
# 获取 AWS 账户 ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile company --query Account --output text)

# 登录 ECR（使用 profile）
aws ecr get-login-password --profile company --region ap-southeast-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com

# 登录 GHCR
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

### 步骤 8: 获取访问地址

```bash
terraform output
```

访问前端：
```
http://simple-blog-prod-alb-xxxxx.us-east-1.elb.amazonaws.com
```

访问后端 API：
```
http://simple-blog-prod-alb-xxxxx.us-east-1.elb.amazonaws.com:8000
```

## ✅ 验证部署

1. **检查 ECS 服务状态**：
   ```bash
   aws ecs list-services --profile company --cluster simple-blog-prod-cluster
   ```

2. **查看任务状态**：
   ```bash
   aws ecs list-tasks --profile company --cluster simple-blog-prod-cluster --service-name simple-blog-prod-backend
   ```

3. **查看日志**：
   ```bash
   aws logs tail /ecs/simple-blog-prod/backend --profile company --follow
   ```

4. **测试健康检查**：
   ```bash
   curl http://$(terraform output -raw alb_dns_name)/healthz
   ```

## 🔧 常见问题

### Q: ECS 任务无法启动？

**A**: 检查以下几点：
1. 镜像是否已同步到 ECR
2. CloudWatch Logs 中的错误信息
3. 安全组配置是否正确
4. 数据库连接字符串是否正确

### Q: 无法访问应用？

**A**: 
1. 检查 ALB 健康检查状态
2. 等待 ECS 任务完全启动（约 2-3 分钟）
3. 检查安全组规则

### Q: 如何更新应用？

**A**: 
1. 推送代码到 GitHub
2. GitHub Actions 构建新镜像
3. ECR 同步工作流自动同步（或手动同步）
4. 更新 ECS 服务：
   ```bash
   aws ecs update-service --cluster simple-blog-prod-cluster --service simple-blog-prod-backend --force-new-deployment
   ```

## 📊 成本控制

- **开发/测试环境**：可以使用 `db.t3.micro` 和较小的 ECS 配置
- **生产环境**：建议使用 `db.t3.small` 或更高配置
- **NAT Gateway**：是主要成本来源，考虑使用 VPC Endpoints（S3、ECR）

## 🗑️ 清理资源

**警告**：这会删除所有资源，包括数据库！

```bash
terraform destroy
```

## 📚 下一步

- 配置自定义域名（Route 53 + ACM）
- 启用 HTTPS（ALB + ACM）
- 配置自动扩展（ECS Auto Scaling）
- 设置 CloudWatch 告警
- 配置备份策略

