# AWS Terraform 部署总结

## 📐 架构设计

### 网络架构
```
Internet
    ↓
Application Load Balancer (ALB)
    ├── Port 80 (HTTP)
    │   ├── /search, /posts, /docs → Backend Target Group
    │   └── / (其他路径) → Frontend Target Group
    │
    ├── Public Subnets (2个可用区)
    │   ├── ALB
    │   └── NAT Gateway
    │
    └── Private Subnets (2个可用区)
        ├── ECS Fargate Tasks (Backend + Frontend)
        └── RDS PostgreSQL (Multi-AZ)
```

### 核心组件

1. **VPC 网络**
   - VPC: `10.0.0.0/16`
   - Public Subnets: 2个（用于 ALB 和 NAT Gateway）
   - Private Subnets: 2个（用于 ECS 和 RDS）
   - Internet Gateway + NAT Gateway

2. **计算层 (ECS Fargate)**
   - Backend Service: FastAPI 后端容器
   - Frontend Service: React 前端容器
   - 从 ECR 拉取镜像

3. **数据层 (RDS)**
   - PostgreSQL 15.4
   - Multi-AZ 部署（高可用）
   - 自动备份（7天保留）

4. **负载均衡 (ALB)**
   - 路径路由：API 路径 → 后端，其他 → 前端
   - 健康检查自动恢复

5. **镜像管理 (ECR)**
   - GitHub Actions 构建镜像到 GHCR
   - 自动同步到 ECR（通过 GitHub Actions workflow）

## 🔄 部署流程

### 首次部署

1. **配置 AWS 凭证**
   ```bash
   aws configure
   ```

2. **配置 Terraform 变量**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # 编辑 terraform.tfvars
   ```

3. **初始化并部署**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **同步镜像到 ECR**
   ```bash
   # 手动同步一次（后续自动）
   # 见 QUICK_START.md
   ```

5. **配置 GitHub Actions ECR 同步**
   - 添加 AWS Secrets 到 GitHub
   - 启用 `.github/workflows/ecr-sync.yml`

### 后续更新

1. **代码更新** → GitHub Actions 构建镜像
2. **自动同步** → ECR 同步工作流
3. **更新服务** → 手动触发 ECS 服务更新

## 📁 文件说明

### Terraform 文件

- `main.tf`: Provider 配置和本地变量
- `variables.tf`: 变量定义
- `vpc.tf`: VPC 网络配置
- `security.tf`: 安全组配置
- `rds.tf`: RDS 数据库配置
- `ecs.tf`: ECS 容器配置
- `alb.tf`: 负载均衡器配置
- `ecr-sync.tf`: ECR 仓库配置
- `outputs.tf`: 输出定义
- `versions.tf`: Terraform 版本约束

### 配置文件

- `terraform.tfvars.example`: 变量配置示例
- `.gitignore`: Git 忽略规则

### 文档文件

- `README.md`: 完整部署指南
- `QUICK_START.md`: 快速开始指南
- `AWS_DEPLOYMENT_DESIGN.md`: 架构设计文档
- `GHCR_TO_ECS_GUIDE.md`: GHCR/ECR 使用指南

## 🔐 安全配置

1. ✅ **网络隔离**
   - ECS 任务在私有子网
   - RDS 在私有子网
   - 只允许 ALB 访问 ECS

2. ✅ **访问控制**
   - 最小权限 IAM 角色
   - 安全组最小开放端口
   - RDS 只允许 ECS 访问

3. ✅ **数据安全**
   - RDS 加密存储
   - Secrets Manager 存储敏感信息
   - ECR 镜像扫描

## 💰 成本优化

1. **开发环境**
   - 使用 `db.t3.micro`
   - ECS 最小配置（256 CPU, 512 MB）
   - 单可用区部署（节省 NAT Gateway）

2. **生产环境**
   - 多可用区部署（高可用）
   - 自动扩展（按需）
   - 保留 Spot 实例选项

3. **成本控制**
   - CloudWatch 告警
   - 定期审查资源使用
   - 使用 Reserved Instances（RDS）

## 🚀 扩展性

- **水平扩展**: ECS Auto Scaling（基于 CPU/内存）
- **垂直扩展**: 调整任务 CPU/内存配置
- **数据库**: RDS 支持读写分离和扩展

## 📊 监控

- **CloudWatch Logs**: 应用日志
- **CloudWatch Metrics**: 资源指标
- **CloudWatch Alarms**: 自动告警
- **ECS Container Insights**: 容器监控

## 🔧 维护

### 更新应用

```bash
# 1. 代码更新后，GitHub Actions 自动构建
# 2. ECR 自动同步（如果配置了）
# 3. 手动更新 ECS 服务
aws ecs update-service \
  --cluster simple-blog-prod-cluster \
  --service simple-blog-prod-backend \
  --force-new-deployment
```

### 查看日志

```bash
aws logs tail /ecs/simple-blog-prod/backend --follow
aws logs tail /ecs/simple-blog-prod/frontend --follow
```

### 查看资源状态

```bash
terraform show
terraform output
```

## ⚠️ 注意事项

1. **镜像同步**: 首次部署需要手动同步镜像到 ECR
2. **数据库密码**: 使用强密码，存储在 Secrets Manager
3. **成本**: NAT Gateway 会产生持续费用
4. **高可用**: RDS Multi-AZ 会增加成本但提供高可用
5. **备份**: RDS 自动备份已启用，保留 7 天

## 📚 参考资源

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Fargate 文档](https://docs.aws.amazon.com/ecs/latest/developerguide/AWS_Fargate.html)
- [RDS PostgreSQL 文档](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [ALB 文档](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)

