# Terraform 文件结构详解（初学者版）

## 📁 文件组织结构

```
terraform/
├── versions.tf              # 版本约束
├── main.tf                  # Provider 配置
├── variables.tf             # 变量定义
├── terraform.tfvars         # 变量值（不提交 Git）
├── vpc.tf                   # 网络配置
├── security.tf              # 安全组配置
├── rds.tf                   # 数据库配置
├── ecr-sync.tf              # 镜像仓库配置
├── ecs.tf                   # 容器服务配置
├── alb.tf                   # 负载均衡器配置
├── outputs.tf               # 输出定义
└── README.md                # 使用文档
```

## 🔍 每个文件的详细说明

### 1. versions.tf - "版本说明书"

**作用**：告诉 Terraform 需要什么版本

**类比**：就像 `package.json` 中的版本要求

```hcl
terraform {
  required_version = ">= 1.0"  # Terraform 版本
  
  required_providers {
    aws = {
      version = "~> 5.0"  # AWS Provider 版本
    }
  }
}
```

**为什么需要**：
- 确保团队使用相同版本
- 避免版本不兼容问题

### 2. variables.tf - "参数定义表"

**作用**：定义所有可配置的参数

**类比**：就像函数的参数列表

```hcl
variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "ap-southeast-1"
}
```

**关键字段**：
- `description`：参数说明
- `type`：参数类型
- `default`：默认值（可选）

### 3. main.tf - "连接配置"

**作用**：配置如何连接 AWS

**类比**：就像数据库连接字符串

```hcl
provider "aws" {
  region  = var.aws_region   # 使用哪个区域
  profile = var.aws_profile  # 使用哪个 AWS profile
}
```

**关键点**：
- `region`：AWS 区域
- `profile`：AWS CLI profile 名称
- Terraform 会读取 `~/.aws/credentials` 中的 profile

### 4. terraform.tfvars - "实际参数值"

**作用**：为变量提供实际值

**类比**：就像配置文件（.env 文件）

```hcl
aws_region   = "ap-southeast-1"
aws_profile  = "company"
db_password  = "YourPassword123"
```

**重要**：
- 包含敏感信息
- 不提交到 Git（在 .gitignore 中）

### 5. vpc.tf - "网络蓝图"

**作用**：定义网络结构

**包含内容**：
- VPC（虚拟网络）
- Subnets（子网）
- Internet Gateway（互联网网关）
- NAT Gateway（网络地址转换）
- Route Tables（路由表）

**为什么单独文件**：
- 网络是基础设施的基础
- 其他资源都依赖网络

### 6. security.tf - "防火墙规则"

**作用**：定义安全组（防火墙规则）

**包含内容**：
- ALB Security Group（允许公网访问）
- ECS Tasks Security Group（只允许 ALB 访问）
- RDS Security Group（只允许 ECS 访问）

**为什么单独文件**：
- 安全规则很重要
- 便于审查和管理

### 7. rds.tf - "数据库配置"

**作用**：创建 PostgreSQL 数据库

**包含内容**：
- DB Subnet Group（数据库子网组）
- Parameter Group（参数组）
- DB Instance（数据库实例）

**为什么单独文件**：
- 数据库是独立的重要组件
- 配置相对复杂

### 8. ecr-sync.tf - "镜像仓库"

**作用**：创建 ECR 仓库存储 Docker 镜像

**包含内容**：
- ECR Repository（镜像仓库）
- Lifecycle Policy（生命周期策略，自动删除旧镜像）

**为什么单独文件**：
- 镜像管理是独立功能
- 可以单独启用/禁用

### 9. ecs.tf - "容器服务配置"

**作用**：配置 ECS 容器服务

**包含内容**：
- ECS Cluster（集群）
- Task Definition（任务定义，容器配置）
- ECS Service（服务，运行容器）
- IAM Roles（权限角色）
- CloudWatch Log Groups（日志组）

**为什么单独文件**：
- ECS 配置最复杂
- 包含多个相关资源

### 10. alb.tf - "负载均衡器"

**作用**：创建 Application Load Balancer

**包含内容**：
- ALB（负载均衡器）
- Target Groups（目标组）
- Listeners（监听器）
- Listener Rules（路由规则）

**为什么单独文件**：
- 负载均衡是独立的网络组件
- 配置相对独立

### 11. outputs.tf - "输出结果"

**作用**：定义部署后输出的信息

**类比**：就像函数的返回值

```hcl
output "frontend_url" {
  value = "http://${aws_lb.main.dns_name}"
}
```

**用途**：
- 快速获取重要信息
- 无需手动查找资源

## 🔗 文件之间的依赖关系

### 依赖图

```
versions.tf (版本要求)
    ↓
variables.tf (定义变量)
    ↓
main.tf (配置 Provider，使用变量)
    ↓
vpc.tf (创建网络，依赖 Provider)
    ↓
security.tf (创建安全组，依赖 VPC)
    ↓
rds.tf (创建数据库，依赖 VPC + Security Groups)
ecr-sync.tf (创建镜像仓库，依赖 Provider)
    ↓
ecs.tf (创建容器服务，依赖 VPC + Security Groups + ECR)
    ↓
alb.tf (创建负载均衡，依赖 VPC + Security Groups + ECS)
    ↓
outputs.tf (输出信息，依赖所有资源)
```

### 执行顺序

Terraform 会自动分析依赖关系，按正确顺序创建资源：

1. **首先**：创建 VPC 和基础网络
2. **然后**：创建安全组
3. **接着**：创建数据库和镜像仓库
4. **最后**：创建容器服务和负载均衡

## 📖 如何阅读 Terraform 文件

### 步骤 1: 从 variables.tf 开始

了解需要配置哪些参数：
```hcl
variable "aws_region" { ... }
variable "db_password" { ... }
```

### 步骤 2: 看 main.tf

了解如何连接 AWS：
```hcl
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```

### 步骤 3: 看各个资源文件

按依赖顺序阅读：
1. `vpc.tf` - 网络基础
2. `security.tf` - 安全规则
3. `rds.tf` - 数据库
4. `ecs.tf` - 容器服务
5. `alb.tf` - 负载均衡

### 步骤 4: 看 outputs.tf

了解会输出什么信息

## 🎯 文件命名约定

### 命名原则

1. **按功能命名**：`vpc.tf`、`rds.tf`、`ecs.tf`
2. **使用小写**：`security.tf` 而不是 `Security.tf`
3. **使用下划线**：`ecr-sync.tf` 或 `ecr_sync.tf`（都可以）
4. **描述性名称**：`alb.tf` 而不是 `lb.tf`

### 常见命名模式

- `网络相关.tf`：`vpc.tf`、`network.tf`
- `安全相关.tf`：`security.tf`、`sg.tf`
- `计算相关.tf`：`ecs.tf`、`compute.tf`
- `存储相关.tf`：`rds.tf`、`storage.tf`
- `访问相关.tf`：`alb.tf`、`lb.tf`

## 💡 文件组织最佳实践

### ✅ 推荐做法

1. **按功能分组**：相关资源放在同一文件
2. **合理拆分**：大文件拆分为多个小文件
3. **统一命名**：使用一致的命名约定
4. **添加注释**：每个文件开头说明作用

### ❌ 避免的做法

1. **所有资源在一个文件**：难以维护
2. **文件命名不清晰**：`stuff.tf`、`things.tf`
3. **缺少注释**：不知道文件作用
4. **硬编码值**：应该使用变量

## 🔧 如何修改文件

### 添加新资源

1. **确定放在哪个文件**：按功能分组
2. **添加资源定义**：使用正确的语法
3. **添加变量**：如果需要配置
4. **添加输出**：如果需要输出信息

### 修改现有资源

1. **找到资源定义**：使用 `grep` 搜索
2. **修改参数**：保持语法正确
3. **运行 plan**：检查变更
4. **应用变更**：`terraform apply`

## 📚 学习建议

### 初学者

1. ✅ 先理解 `variables.tf` 和 `main.tf`
2. ✅ 然后看 `vpc.tf`（最简单的资源）
3. ✅ 逐步理解其他文件
4. ✅ 运行 `terraform plan` 查看效果

### 进阶

1. 理解资源之间的依赖
2. 学习使用 `locals` 和 `data`
3. 学习模块化组织
4. 学习使用工作空间

## ✅ 检查清单

创建文件后检查：

- [ ] 文件命名清晰
- [ ] 文件开头有注释说明
- [ ] 资源按功能分组
- [ ] 使用变量而不是硬编码
- [ ] 使用 `terraform fmt` 格式化
- [ ] 使用 `terraform validate` 验证

## 🎓 总结

**文件组织原则**：
1. ✅ 按功能分组
2. ✅ 合理拆分
3. ✅ 统一命名
4. ✅ 添加注释

**阅读顺序**：
1. `variables.tf` → 了解需要什么
2. `main.tf` → 了解如何连接
3. 资源文件 → 了解创建什么
4. `outputs.tf` → 了解输出什么

**修改原则**：
1. ✅ 先理解再修改
2. ✅ 使用 `terraform plan` 预览
3. ✅ 小步修改，逐步验证

现在你已经理解了文件结构，可以开始使用了！🚀

