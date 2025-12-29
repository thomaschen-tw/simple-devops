# AWS 部署检查清单

## ✅ 部署前检查

### 1. AWS 账号准备
- [ ] AWS 账号已创建
- [ ] IAM 用户已创建（有足够权限）
- [ ] Access Key 和 Secret Key 已获取
- [ ] AWS CLI 已配置：`aws configure`
- [ ] 账户有足够配额（VPC、ECS、RDS 等）

### 2. Docker 镜像准备
- [ ] GitHub Actions 已构建后端镜像
- [ ] GitHub Actions 已构建前端镜像
- [ ] 镜像已推送到 GHCR
- [ ] 镜像可以正常拉取：`docker pull ghcr.io/USER/REPO/backend:latest`

### 3. Terraform 配置
- [ ] Terraform 已安装：`terraform --version`
- [ ] `terraform.tfvars` 已创建并配置
- [ ] 所有必需变量已填写
- [ ] 数据库密码已设置为强密码
- [ ] GitHub 用户名和仓库名正确

### 4. 网络配置
- [ ] VPC CIDR 不冲突（默认：10.0.0.0/16）
- [ ] 可用区配置正确（至少 2 个）
- [ ] 域名和证书（如果使用）已准备

## 🚀 部署步骤

### 步骤 1：初始化

```bash
cd terraform
terraform init
```

**检查**：
- ✅ Provider 下载成功
- ✅ 模块初始化成功
- ✅ 无错误信息

### 步骤 2：验证配置

```bash
terraform validate
```

**检查**：
- ✅ 配置语法正确
- ✅ 变量定义正确
- ✅ 无验证错误

### 步骤 3：预览变更

```bash
terraform plan
```

**检查**：
- ✅ 资源数量合理（约 30-40 个）
- ✅ 没有意外的删除操作
- ✅ 成本估算合理
- ✅ 配置正确

### 步骤 4：部署

```bash
terraform apply
```

**输入 `yes` 确认**

**等待时间**：10-15 分钟

**监控**：
- RDS 创建需要最长时间（5-10 分钟）
- ECS 服务启动需要时间（2-5 分钟）

### 步骤 5：验证部署

```bash
# 获取输出
terraform output

# 测试前端
curl $(terraform output -raw frontend_url)

# 测试后端健康检查
curl $(terraform output -raw backend_api_url)/healthz

# 测试搜索 API
curl "$(terraform output -raw backend_api_url)/search?q=test"
```

## 🔍 部署后验证

### 1. 网络验证
- [ ] VPC 创建成功
- [ ] 子网创建成功（2 个 Public，2 个 Private）
- [ ] NAT Gateway 运行正常
- [ ] 路由表配置正确

### 2. 数据库验证
- [ ] RDS 实例创建成功
- [ ] 数据库状态：`available`
- [ ] 可以从 ECS 连接数据库
- [ ] 安全组规则正确

### 3. ECS 验证
- [ ] ECS Cluster 创建成功
- [ ] Backend Service 运行正常
- [ ] Frontend Service 运行正常
- [ ] 任务状态：`RUNNING`
- [ ] 健康检查通过

### 4. ALB 验证
- [ ] ALB 创建成功
- [ ] DNS 名称可访问
- [ ] Target Groups 健康检查通过
- [ ] 路由规则正确

### 5. 应用验证
- [ ] 前端页面可以访问
- [ ] 后端 API 响应正常
- [ ] 搜索功能正常
- [ ] 创建文章功能正常
- [ ] 数据库连接正常

## 📊 资源验证命令

### 检查 ECS 服务

```bash
# 列出 ECS 服务
aws ecs list-services --cluster simple-devops-dev

# 查看服务详情
aws ecs describe-services \
  --cluster simple-devops-dev \
  --services simple-devops-dev-backend

# 查看任务
aws ecs list-tasks --cluster simple-devops-dev
```

### 检查 RDS

```bash
# 列出 RDS 实例
aws rds describe-db-instances \
  --db-instance-identifier simple-devops-dev-db

# 检查状态
aws rds describe-db-instances \
  --query 'DBInstances[?DBInstanceIdentifier==`simple-devops-dev-db`].DBInstanceStatus'
```

### 检查 ALB

```bash
# 列出负载均衡器
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?LoadBalancerName==`simple-devops-dev-alb`]'

# 检查目标组健康
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## ⚠️ 常见问题

### 问题 1：ECS 任务无法启动

**检查**：
```bash
# 查看任务日志
aws logs tail /ecs/simple-devops-dev-backend --follow

# 检查任务定义
aws ecs describe-task-definition \
  --task-definition simple-devops-dev-backend
```

**可能原因**：
- 镜像拉取失败（检查镜像 URL 和权限）
- 环境变量错误（检查 DATABASE_URL）
- 资源不足（检查 CPU/内存配置）

### 问题 2：无法连接到数据库

**检查**：
```bash
# 检查 RDS 安全组
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=simple-devops-dev-rds-sg"

# 检查 RDS 状态
aws rds describe-db-instances \
  --db-instance-identifier simple-devops-dev-db
```

**可能原因**：
- 安全组规则不正确
- RDS 未完全启动
- DATABASE_URL 配置错误

### 问题 3：ALB 健康检查失败

**检查**：
```bash
# 查看目标组健康状态
aws elbv2 describe-target-health \
  --target-group-arn <arn>
```

**可能原因**：
- 容器未启动
- 健康检查路径错误
- 安全组阻止 ALB 访问

## 🗑️ 清理资源

### 删除所有资源

```bash
terraform destroy
```

**⚠️ 警告**：
- 这会删除所有资源，包括数据库数据
- RDS 有删除保护（生产环境），需要先禁用

### 禁用 RDS 删除保护

```bash
aws rds modify-db-instance \
  --db-instance-identifier simple-devops-dev-db \
  --no-deletion-protection \
  --apply-immediately
```

## 📚 相关文档

- [快速开始指南](QUICKSTART.md)
- [完整部署指南](AWS_DEPLOYMENT_GUIDE.md)
- [架构说明](AWS_ARCHITECTURE.md)

