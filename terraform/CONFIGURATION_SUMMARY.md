# Terraform 配置总结

## 📋 配置方式说明

本项目使用**直接在根目录定义资源**的方式，而不是使用 modules。这样更简单直接，便于学习和理解。

## 📁 文件组织

### 核心配置文件

1. **`main.tf`** - Provider 配置和数据源
   - AWS Provider 配置
   - 数据源（可用区、账号 ID、区域）

2. **`locals.tf`** - 本地变量
   - `name_prefix`：资源名称前缀
   - `azs`：可用区列表
   - `backend_image`、`frontend_image`：Docker 镜像地址

3. **`variables.tf`** - 变量定义
   - AWS 区域、项目名称、环境
   - GitHub 配置
   - 数据库配置
   - ECS 配置
   - 网络配置

4. **`outputs.tf`** - 输出定义
   - VPC、ALB、RDS、ECS 的输出值

### 资源配置文件（按步骤）

1. **`vpc.tf`** - 步骤 1：VPC 网络
   - VPC、子网、网关、路由表

2. **`security.tf`** - 步骤 2：安全组
   - ALB 安全组
   - ECS 任务安全组
   - RDS 安全组

3. **`alb.tf`** - 步骤 3：负载均衡器
   - Application Load Balancer
   - Target Groups
   - Listeners 和路由规则

4. **`rds.tf`** - 步骤 4：数据库
   - RDS PostgreSQL 实例
   - DB Subnet Group
   - Parameter Group
   - IAM Role（增强监控）

5. **`ecs.tf`** - 步骤 5：容器服务
   - ECS Cluster
   - Task Definitions（Backend 和 Frontend）
   - ECS Services
   - IAM Roles
   - CloudWatch Log Groups

### 可选文件

- **`ecr-sync.tf`** - ECR 镜像仓库（可选，如果使用 GHCR 可跳过）

## 🔗 资源依赖关系

```
main.tf (Provider)
    ↓
vpc.tf (VPC 网络)
    ↓
security.tf (安全组)
    ↓
alb.tf (负载均衡器)
    ↓
rds.tf (数据库) ──┐
    ↓              │
ecs.tf (容器服务) ─┘
```

## 🎯 配置特点

### 1. 使用本地变量统一命名

所有资源使用 `local.name_prefix` 作为前缀：
- `simple-devops-dev-vpc`
- `simple-devops-dev-alb`
- `simple-devops-dev-db`

### 2. 环境区分

通过 `var.environment` 区分环境：
- `dev`：开发环境（单可用区、无删除保护）
- `prod`：生产环境（多可用区、删除保护、增强监控）

### 3. 自动检测可用区

如果 `availability_zones` 为空，自动检测当前区域的所有可用区。

### 4. 安全组规则

- ALB：允许 80/443 端口从公网访问
- ECS Tasks：只允许从 ALB 访问
- RDS：只允许从 ECS Tasks 访问（5432 端口）

## 📊 变量使用说明

### 必需变量

```hcl
aws_region = "ap-southeast-1"
project_name = "simple-devops"
environment = "dev"
github_username = "your-username"
github_repo = "your-repo"
database_password = "YourPassword123!"
```

### 可选变量（有默认值）

```hcl
vpc_cidr = "10.0.0.0/16"
availability_zones = []  # 自动检测
database_instance_class = "db.t3.micro"
backend_cpu = 512
backend_memory = 1024
```

## 🔧 配置修改建议

### 开发环境优化

在 `terraform.tfvars` 中：
```hcl
environment = "dev"
database_instance_class = "db.t3.micro"
backend_cpu = 256  # 降低资源
backend_memory = 512
```

### 生产环境配置

在 `terraform.tfvars` 中：
```hcl
environment = "prod"
database_instance_class = "db.t3.small"
backend_cpu = 1024
backend_memory = 2048
backend_desired_count = 2  # 多实例
```

## 📚 相关文档

- [分步学习指南](STEP_BY_STEP_GUIDE.md) - 详细的学习步骤
- [README.md](README.md) - 快速开始和概览
- [GHCR 到 ECS 指南](GHCR_TO_ECS_GUIDE.md) - 镜像配置说明

