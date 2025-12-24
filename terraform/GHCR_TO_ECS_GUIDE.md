# GHCR 镜像在 ECS 中的使用指南

## 问题说明

ECS Fargate 原生不支持直接从 GitHub Container Registry (GHCR) 拉取私有镜像，因为 ECS 的 `repositoryCredentials` 只支持 Docker Hub 格式的认证。

## 解决方案

### 方案 A: 使用 ECR（推荐）⭐

**优点**：
- ✅ 更好的 AWS 集成
- ✅ 更快的拉取速度（同区域）
- ✅ 原生支持，无需额外配置
- ✅ 更好的安全性和访问控制

**实现步骤**：

1. **创建 ECR 仓库**（使用 Terraform）
   ```bash
   # 取消注释 terraform/ecr-sync.tf 中的资源
   terraform apply
   ```

2. **配置 GitHub Actions 同步镜像**
   - 使用 `.github/workflows/ecr-sync.yml`
   - 在 GitHub Secrets 中添加：
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_ACCOUNT_ID`

3. **更新 ECS Task Definition**
   ```hcl
   # 在 ecs.tf 中修改镜像地址
   image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}/${var.environment}/backend:latest"
   ```

### 方案 B: 使用公共镜像

如果 GHCR 镜像设置为公共，ECS 可以直接拉取：

1. 在 GitHub 仓库设置中将包设为公开
2. 在 ECS Task Definition 中直接使用镜像地址
3. 无需配置认证

### 方案 C: 使用 Lambda 同步（复杂）

创建一个 Lambda 函数定期从 GHCR 拉取镜像并推送到 ECR，但实现复杂，不推荐。

## 推荐实施步骤

### 1. 创建 ECR 仓库

编辑 `terraform/ecr-sync.tf`，取消注释 ECR 资源：

```bash
terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend
```

### 2. 配置 GitHub Actions

1. 在 GitHub 仓库中添加 Secrets：
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ACCOUNT_ID`

2. 启用 ECR 同步工作流（`.github/workflows/ecr-sync.yml`）

3. 每次构建后自动同步到 ECR

### 3. 更新 Terraform 配置

修改 `terraform/ecs.tf` 中的镜像地址：

```hcl
locals {
  # 使用 ECR 镜像
  backend_image  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}/${var.environment}/backend:latest"
  frontend_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}/${var.environment}/frontend:latest"
}
```

### 4. 应用配置

```bash
terraform apply
```

## 当前配置说明

当前 Terraform 配置使用 GHCR 镜像地址，但需要：

1. **镜像必须公开**，或
2. **使用 ECR 同步方案**（推荐）

如果使用 GHCR 私有镜像，ECS 任务将无法启动，因为无法认证。

## 验证

部署后检查 ECS 任务日志：

```bash
aws logs tail /ecs/simple-blog-prod/backend --follow
```

如果看到镜像拉取错误，说明需要切换到 ECR 方案。

