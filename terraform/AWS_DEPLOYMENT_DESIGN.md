# AWS 部署架构设计

## 架构概览

```
Internet
    ↓
Application Load Balancer (ALB)
    ├── Frontend Target Group (Port 80)
    │   └── ECS Fargate Service (Frontend)
    │       └── Container: ghcr.io/.../frontend:latest
    │
    └── Backend Target Group (Port 8000)
        └── ECS Fargate Service (Backend)
            └── Container: ghcr.io/.../backend:latest
                └── DATABASE_URL → RDS PostgreSQL
```

## 核心组件

### 1. 网络层 (VPC)
- **VPC**: 创建独立的虚拟网络
- **Public Subnets**: 用于 ALB 和 NAT Gateway（2个可用区，高可用）
- **Private Subnets**: 用于 ECS 任务和 RDS（2个可用区，高可用）
- **Internet Gateway**: 提供公网访问
- **NAT Gateway**: 允许私有子网访问外网（拉取 GHCR 镜像）

### 2. 计算层 (ECS Fargate)
- **ECS Cluster**: 容器编排集群
- **Backend Service**: 运行 FastAPI 后端
  - 从 GHCR 拉取镜像
  - 连接到 RDS 数据库
  - 健康检查：`/healthz`
- **Frontend Service**: 运行 React 前端
  - 从 GHCR 拉取镜像
  - 通过 ALB 访问后端 API

### 3. 数据层 (RDS)
- **RDS PostgreSQL**: 托管数据库服务
  - 多可用区部署（高可用）
  - 自动备份
  - 安全组限制只允许 ECS 任务访问

### 4. 负载均衡 (ALB)
- **Application Load Balancer**: 应用层负载均衡
  - 前端监听器（Port 80）→ Frontend Target Group
  - 后端监听器（Port 8000）→ Backend Target Group
  - SSL/TLS 终止（可选，使用 ACM）

### 5. 安全
- **Security Groups**: 
  - ALB: 允许 80/443 入站
  - ECS Tasks: 只允许 ALB 访问
  - RDS: 只允许 ECS Tasks 访问
- **IAM Roles**: ECS 任务执行角色和任务角色
- **Secrets Manager**: 存储数据库密码（可选）

## 镜像管理策略

### 方案 A: 使用 GHCR（当前方案）
- **优点**: 无需维护 ECR，使用现有 CI/CD
- **挑战**: ECS 需要访问 GHCR（需要配置认证）
- **实现**: 
  - 使用 GitHub Personal Access Token
  - 存储在 AWS Secrets Manager
  - ECS 任务启动时拉取镜像

### 方案 B: 同步到 ECR（推荐）
- **优点**: 更好的 AWS 集成，更快的拉取速度
- **实现**: 
  - GitHub Actions 构建后推送到 GHCR
  - 同时推送到 ECR（或使用 Lambda 同步）
  - ECS 从 ECR 拉取

## 部署流程

1. **Terraform 初始化**
   ```bash
   terraform init
   ```

2. **配置变量**
   - 编辑 `terraform.tfvars`
   - 设置 GitHub 用户名、仓库名等

3. **规划部署**
   ```bash
   terraform plan
   ```

4. **应用配置**
   ```bash
   terraform apply
   ```

5. **获取输出**
   - ALB DNS 地址
   - RDS 端点
   - 其他资源信息

## 成本估算（每月）

- **ECS Fargate**: ~$30-50（2个服务，0.5 vCPU，1GB RAM）
- **RDS db.t3.micro**: ~$15-20
- **ALB**: ~$20-25
- **NAT Gateway**: ~$35（按流量计费）
- **数据传输**: ~$10-20
- **总计**: ~$110-150/月

## 高可用性

- ✅ 多可用区部署（2个 AZ）
- ✅ RDS 多可用区（自动故障转移）
- ✅ ECS 服务多任务实例
- ✅ ALB 健康检查自动恢复

## 扩展性

- **水平扩展**: ECS 自动扩展（基于 CPU/内存）
- **垂直扩展**: 调整任务 CPU/内存配置
- **数据库**: RDS 支持读写分离和扩展

## 监控和日志

- **CloudWatch Logs**: ECS 任务日志
- **CloudWatch Metrics**: ECS、RDS、ALB 指标
- **CloudWatch Alarms**: 自动告警

## 安全最佳实践

1. ✅ 使用私有子网部署应用
2. ✅ 最小权限 IAM 角色
3. ✅ 安全组最小开放端口
4. ✅ 数据库密码存储在 Secrets Manager
5. ✅ 启用 RDS 加密
6. ✅ VPC Flow Logs（可选）

