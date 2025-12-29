# AWS 部署架构说明

## 🏗️ 架构图

```
                    Internet
                       ↓
              ┌───────────────┐
              │  CloudFront    │ ← S3 (前端静态文件，可选)
              │     (CDN)      │
              └───────────────┘
                       ↓
        ┌──────────────────────────────┐
        │  Application Load Balancer    │
        │         (ALB)                │
        └──────────────────────────────┘
                 ↙        ↘
        ┌──────────┐    ┌──────────┐
        │ /api/*   │    │   /*     │
        └──────────┘    └──────────┘
              ↓              ↓
    ┌─────────────┐  ┌─────────────┐
    │  ECS        │  │  ECS        │
    │  Backend    │  │  Frontend   │
    │  (Fargate)  │  │  (Fargate)  │
    └─────────────┘  └─────────────┘
              ↓              ↓
        ┌──────────────────────┐
        │   RDS PostgreSQL      │
        │    (Multi-AZ)         │
        └──────────────────────┘
```

## 📦 组件详解

### 1. VPC 网络层

**VPC**：
- CIDR: `10.0.0.0/16`
- 启用 DNS 支持和 DNS 主机名

**Public Subnets**（公网子网）：
- 用途：ALB、NAT Gateway
- 数量：2 个（多 AZ）
- 自动分配公网 IP

**Private Subnets**（私网子网）：
- 用途：ECS 任务、RDS
- 数量：2 个（多 AZ）
- 通过 NAT Gateway 访问互联网

**NAT Gateway**：
- 数量：2 个（每个 AZ 一个）
- 用途：私网子网访问互联网（拉取 Docker 镜像）

### 2. 前端部署选项

#### 选项 A：S3 + CloudFront（推荐，成本更低）

**优势**：
- ✅ 成本低（S3 存储 + CloudFront 流量）
- ✅ 性能好（CDN 全球分发）
- ✅ 简单（静态文件托管）

**配置**：
- S3 Bucket：存储前端构建产物
- CloudFront Distribution：CDN 分发
- Origin Access Control：保护 S3 访问

#### 选项 B：ECS Fargate（当前配置）

**优势**：
- ✅ 容器化部署
- ✅ 与后端统一管理
- ✅ 支持动态内容

**配置**：
- ECS Service：Fargate 任务
- Target Group：ALB 目标组
- Auto Scaling：自动扩缩容

### 3. 后端部署

**ECS Fargate**：
- 容器化部署
- 无服务器管理（无需管理 EC2）
- 自动扩缩容

**配置**：
- CPU：512 (0.5 vCPU) - 2048 (2 vCPU)
- Memory：1024 MB - 4096 MB
- Desired Count：1 - 10

**Auto Scaling**：
- CPU > 70%：扩容
- Memory > 80%：扩容
- 冷却期：扩容 60s，缩容 300s

### 4. 数据库

**RDS PostgreSQL 15**：
- 托管数据库服务
- Multi-AZ（生产环境）
- 自动备份
- 存储加密

**配置**：
- Instance Class：db.t3.micro - db.t3.large
- Storage：20 GB（可自动扩展）
- Backup：7 天保留期

### 5. 负载均衡

**Application Load Balancer (ALB)**：
- 第 7 层负载均衡
- 路由规则：
  - `/api/*`, `/search`, `/posts*`, `/healthz`, `/docs*` → Backend
  - `/*` → Frontend
- SSL 终止（如果配置证书）
- 健康检查

### 6. 安全

**Security Groups**：
- ALB SG：允许 80/443 入站
- Backend SG：允许 ALB → 8000
- Frontend SG：允许 ALB → 80
- RDS SG：允许 Backend SG → 5432

**网络隔离**：
- ECS 在 Private Subnets（不直接暴露）
- RDS 在 Private Subnets（只能从 ECS 访问）
- ALB 在 Public Subnets（对外提供服务）

## 🔄 数据流

### 前端请求流程

1. 用户访问前端 URL
2. CloudFront（如果使用）或 ALB 接收请求
3. ALB 路由到 Frontend ECS 任务
4. Frontend 容器返回 HTML/JS/CSS

### API 请求流程

1. 前端发起 API 请求（如 `/api/search?q=test`）
2. ALB 接收请求，匹配 `/api/*` 规则
3. ALB 路由到 Backend ECS 任务
4. Backend 容器处理请求
5. Backend 连接 RDS 查询数据
6. Backend 返回 JSON 响应
7. 前端接收并显示数据

### 数据库连接

1. Backend ECS 任务启动
2. 从环境变量读取 `DATABASE_URL`
3. 连接到 RDS endpoint（私网）
4. 执行 SQL 查询
5. 返回结果

## 📊 资源清单

### 网络资源
- 1x VPC
- 2x Public Subnets
- 2x Private Subnets
- 1x Internet Gateway
- 2x NAT Gateways
- 2x Elastic IPs
- 路由表和关联

### 计算资源
- 1x ECS Cluster
- 1x ECS Backend Service
- 1x ECS Frontend Service
- 2x ECS Task Definitions
- 2x Auto Scaling Targets
- 4x Auto Scaling Policies

### 负载均衡
- 1x Application Load Balancer
- 2x Target Groups
- 2x Listeners
- 2x Listener Rules
- 3x Security Groups

### 数据库
- 1x RDS PostgreSQL Instance
- 1x DB Subnet Group
- 1x DB Parameter Group
- 1x Security Group

### 存储（如果使用 S3）
- 1x S3 Bucket
- 1x CloudFront Distribution
- 1x Origin Access Control

### IAM
- 2x Task Execution Roles
- 2x Task Roles
- 2x IAM Policies

### 监控
- 2x CloudWatch Log Groups

## 💰 成本分析

### 开发环境（最小配置）

| 资源 | 配置 | 月成本 |
|------|------|--------|
| RDS db.t3.micro | 单 AZ | ~$15 |
| ECS Backend | 0.25 vCPU, 0.5GB | ~$5 |
| ECS Frontend | 0.25 vCPU, 0.5GB | ~$5 |
| ALB | 标准 | ~$16 |
| NAT Gateway | 2x | ~$64 |
| S3 + CloudFront | 少量流量 | ~$1 |
| **总计** | | **~$106/月** |

**优化建议**：
- 使用 1 个 NAT Gateway（节省 $32/月）
- 使用 S3 + CloudFront 替代 ECS Frontend（节省 $5/月）
- **优化后**：~$69/月

### 生产环境（推荐配置）

| 资源 | 配置 | 月成本 |
|------|------|--------|
| RDS db.t3.small Multi-AZ | 双 AZ | ~$60 |
| ECS Backend | 1 vCPU, 2GB, 2 tasks | ~$60 |
| ECS Frontend | 0.5 vCPU, 1GB, 2 tasks | ~$30 |
| ALB | 标准 | ~$16 |
| NAT Gateway | 2x | ~$64 |
| S3 + CloudFront | 中等流量 | ~$10 |
| **总计** | | **~$240/月** |

**优化建议**：
- 使用 S3 + CloudFront 替代 ECS Frontend（节省 $30/月）
- 使用 Reserved Instances（RDS，节省 30-40%）
- **优化后**：~$180/月

## 🔐 安全设计

### 网络层安全

1. **VPC 隔离**：应用在私有网络
2. **Security Groups**：最小权限原则
3. **NAT Gateway**：私网访问互联网，不暴露 IP

### 应用层安全

1. **HTTPS**：ALB SSL 终止
2. **加密传输**：RDS 连接加密
3. **存储加密**：RDS 存储加密

### 访问控制

1. **IAM Roles**：最小权限
2. **Secrets Management**：使用 AWS Secrets Manager（推荐）
3. **数据库密码**：不在代码中硬编码

## 📈 扩展性

### 水平扩展

- **ECS Auto Scaling**：自动增加/减少任务数
- **RDS Read Replicas**：读取扩展（可选）
- **ALB**：自动分发流量

### 垂直扩展

- **ECS**：增加 CPU/内存
- **RDS**：升级实例类型

## 🔍 监控和日志

### CloudWatch

- **Logs**：ECS 容器日志
- **Metrics**：CPU、内存、请求数
- **Alarms**：自动告警

### 健康检查

- **ALB**：定期检查 Target Group
- **ECS**：容器健康检查
- **RDS**：自动故障转移（Multi-AZ）

## 🎯 最佳实践

1. **多 AZ 部署**：高可用性
2. **Auto Scaling**：应对流量波动
3. **备份策略**：RDS 自动备份
4. **监控告警**：CloudWatch Alarms
5. **成本优化**：使用 S3 + CloudFront 替代 ECS Frontend

## 📚 参考资源

- [AWS ECS Fargate](https://docs.aws.amazon.com/ecs/latest/developerguide/AWS_Fargate.html)
- [AWS RDS PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [AWS ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

