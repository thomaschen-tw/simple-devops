# Terraform 文件构建指南（初学者版）

## 🎯 目标

理解每个 Terraform 文件是如何构建的，以及为什么要这样组织。

## 📋 构建顺序（推荐）

按照以下顺序创建和理解文件，从简单到复杂：

1. **versions.tf** - 版本约束（最简单）
2. **variables.tf** - 变量定义（输入）
3. **main.tf** - Provider 配置（连接 AWS）
4. **terraform.tfvars** - 变量值（配置）
5. **vpc.tf** - 网络基础（VPC、子网）
6. **security.tf** - 安全规则（安全组）
7. **rds.tf** - 数据库（数据层）
8. **ecr-sync.tf** - 镜像仓库（存储）
9. **ecs.tf** - 容器服务（计算层）
10. **alb.tf** - 负载均衡（访问层）
11. **outputs.tf** - 输出结果（信息）

## 🔨 逐步构建说明

### 步骤 1: 创建版本约束文件（versions.tf）

**目的**：确保使用兼容的 Terraform 版本

```hcl
terraform {
  required_version = ">= 1.0"  # 最低版本要求
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Provider 来源
      version = "~> 5.0"         # 版本范围（5.0.x）
    }
  }
}
```

**为什么需要**：
- 防止版本不兼容问题
- 确保团队使用相同版本
- 锁定 Provider 版本

### 步骤 2: 定义变量（variables.tf）

**目的**：定义所有可配置的参数

**构建思路**：
1. 列出所有需要配置的值
2. 为每个值定义变量
3. 设置默认值（可选）
4. 添加描述说明

```hcl
# AWS 配置
variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile 名称"
  type        = string
  default     = "company"
}

# 项目配置
variable "project_name" {
  description = "项目名称"
  type        = string
}

# 数据库配置
variable "db_password" {
  description = "数据库密码"
  type        = string
  sensitive   = true  # 标记为敏感信息
}
```

**变量类型说明**：
- `string`：文本（如 "ap-southeast-1"）
- `number`：数字（如 512）
- `bool`：布尔值（true/false）
- `list(string)`：字符串列表
- `map(string)`：键值对

### 步骤 3: 配置 Provider（main.tf）

**目的**：告诉 Terraform 如何连接 AWS

```hcl
provider "aws" {
  region  = var.aws_region   # 使用变量中的区域
  profile = var.aws_profile # 使用 AWS CLI profile
}
```

**关键点**：
- `region`：AWS 区域（如 ap-southeast-1）
- `profile`：AWS CLI profile 名称（如 "company"）
- Provider 会使用 `~/.aws/credentials` 中的 profile 配置

**如何工作**：
1. Terraform 读取 `profile = "company"`
2. 查找 `~/.aws/credentials` 中的 `[company]` 部分
3. 使用其中的 Access Key 和 Secret Key
4. 连接到指定的 AWS 区域

### 步骤 4: 创建变量值文件（terraform.tfvars）

**目的**：为变量提供实际值

```hcl
aws_region   = "ap-southeast-1"
aws_profile  = "company"
project_name = "simple-blog"
db_password  = "YourSecurePassword123!"
```

**为什么单独文件**：
- 包含敏感信息（密码、密钥）
- 不同环境使用不同值
- 不提交到 Git（在 .gitignore 中）

### 步骤 5: 构建网络层（vpc.tf）

**目的**：创建虚拟网络

**构建思路**：
1. 先创建 VPC（网络容器）
2. 创建子网（网络分区）
3. 创建网关（连接外网）
4. 配置路由（流量方向）

```hcl
# 1. 创建 VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr  # 使用变量
  # ...
}

# 2. 创建子网（循环创建多个）
resource "aws_subnet" "public" {
  count = 2  # 创建 2 个子网
  vpc_id = aws_vpc.main.id  # 引用 VPC
  # ...
}

# 3. 创建 Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # 关联到 VPC
}
```

**资源引用**：
- `aws_vpc.main.id`：引用名为 "main" 的 VPC 的 ID
- 使用 `count` 或 `for_each` 创建多个资源

### 步骤 6: 配置安全（security.tf）

**目的**：定义防火墙规则

**构建思路**：
1. 为每层服务创建安全组
2. 定义入站规则（允许哪些流量进入）
3. 定义出站规则（允许哪些流量出去）

```hcl
# ALB 安全组（允许公网访问）
resource "aws_security_group" "alb" {
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 允许所有 IP
  }
}

# ECS 安全组（只允许 ALB 访问）
resource "aws_security_group" "ecs_tasks" {
  ingress {
    security_groups = [aws_security_group.alb.id]  # 引用 ALB 安全组
  }
}
```

### 步骤 7: 创建数据库（rds.tf）

**目的**：创建 PostgreSQL 数据库

**构建思路**：
1. 创建子网组（数据库放在哪些子网）
2. 创建参数组（数据库配置）
3. 创建数据库实例

```hcl
# 数据库子网组
resource "aws_db_subnet_group" "main" {
  subnet_ids = aws_subnet.private[*].id  # 使用所有私有子网
}

# 数据库实例
resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = var.db_instance_class
  db_name        = var.db_name
  username       = var.db_username
  password       = var.db_password
  # ...
}
```

### 步骤 8: 创建镜像仓库（ecr-sync.tf）

**目的**：创建 ECR 仓库存储 Docker 镜像

```hcl
resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}/${var.environment}/backend"
}
```

**为什么需要**：
- ECS 需要从某个地方拉取镜像
- ECR 是 AWS 的 Docker 镜像仓库
- 与 AWS 集成更好

### 步骤 9: 配置容器服务（ecs.tf）

**目的**：创建 ECS 集群和任务

**构建思路**：
1. 创建 ECS 集群（容器运行环境）
2. 创建任务定义（容器配置）
3. 创建服务（运行任务）

```hcl
# 1. ECS 集群
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
}

# 2. 任务定义（容器配置）
resource "aws_ecs_task_definition" "backend" {
  container_definitions = jsonencode([{
    name  = "backend"
    image = local.backend_image  # 使用本地变量
    # ...
  }])
}

# 3. ECS 服务（运行任务）
resource "aws_ecs_service" "backend" {
  cluster        = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  # ...
}
```

**关键概念**：
- **集群**：容器运行的环境
- **任务定义**：容器的配置（镜像、CPU、内存等）
- **服务**：实际运行的任务实例

### 步骤 10: 配置负载均衡（alb.tf）

**目的**：创建负载均衡器分发流量

**构建思路**：
1. 创建 ALB（负载均衡器）
2. 创建目标组（后端服务组）
3. 创建监听器（接收请求）
4. 配置路由规则（路径路由）

```hcl
# ALB
resource "aws_lb" "main" {
  subnets = aws_subnet.public[*].id  # 放在公网子网
}

# 目标组（后端）
resource "aws_lb_target_group" "backend" {
  port = 8000
  # ...
}

# 监听器（Port 80）
resource "aws_lb_listener" "frontend" {
  port = 80
  default_action {
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# 路由规则（API 路径 → 后端）
resource "aws_lb_listener_rule" "api" {
  condition {
    path_pattern {
      values = ["/search", "/posts*"]
    }
  }
  action {
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
```

### 步骤 11: 定义输出（outputs.tf）

**目的**：输出重要信息

```hcl
output "frontend_url" {
  value = "http://${aws_lb.main.dns_name}"
}
```

## 🔗 资源之间的依赖关系

### 依赖链

```
VPC
  ↓
Subnets (依赖 VPC)
  ↓
Security Groups (依赖 VPC)
  ↓
RDS (依赖 Subnets + Security Groups)
  ↓
ECS Tasks (依赖 Subnets + Security Groups)
  ↓
ALB (依赖 Subnets + Security Groups)
  ↓
ECS Services (依赖 ECS Cluster + Task Definition + ALB)
```

### 如何 Terraform 自动处理依赖？

Terraform 通过**资源引用**自动识别依赖：

```hcl
# VPC
resource "aws_vpc" "main" { ... }

# Subnet 引用 VPC（自动依赖）
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id  # ← 这里创建了依赖关系
}

# Security Group 引用 VPC（自动依赖）
resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.main.id  # ← 这里创建了依赖关系
}
```

**Terraform 会自动**：
1. 先创建 VPC
2. 然后创建 Subnet 和 Security Group
3. 最后创建依赖它们的资源

## 📐 文件组织原则

### 1. 按功能分组

- `vpc.tf`：所有网络相关
- `rds.tf`：所有数据库相关
- `ecs.tf`：所有容器相关

**优点**：易于查找和维护

### 2. 使用 locals 避免重复

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# 使用
resource "aws_vpc" "main" {
  tags = {
    Name = "${local.name_prefix}-vpc"  # 统一命名
  }
}
```

**优点**：修改一处，所有地方更新

### 3. 使用 data 获取信息

```hcl
# 获取当前账户 ID（不需要手动输入）
data "aws_caller_identity" "current" {}

# 使用
locals {
  backend_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr..."
}
```

**优点**：自动获取，无需配置

## 🎓 学习路径

### 阶段 1: 理解基础（当前阶段）

1. ✅ 理解变量和输出
2. ✅ 理解资源定义
3. ✅ 理解资源引用

### 阶段 2: 实践操作

1. 修改现有配置
2. 添加新资源
3. 调试错误

### 阶段 3: 高级特性

1. 模块化（将配置拆分）
2. 工作空间（多环境管理）
3. 远程状态（S3 后端）

## 💡 实用技巧

### 1. 使用 terraform fmt 格式化

```bash
terraform fmt  # 自动格式化所有 .tf 文件
```

### 2. 使用 terraform validate 验证

```bash
terraform validate  # 检查语法错误
```

### 3. 使用 terraform plan 预览

```bash
terraform plan  # 查看将要创建的资源（不实际创建）
```

### 4. 使用注释说明

```hcl
# 这是单行注释

/*
这是多行注释
可以写多行
*/
```

### 5. 使用输出调试

```hcl
# 临时输出调试信息
output "debug" {
  value = aws_vpc.main.id
}
```

## 🚨 常见错误

### 错误 1: 资源引用错误

```hcl
# ❌ 错误：资源不存在
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.other.id  # other 不存在
}

# ✅ 正确：引用已定义的资源
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id  # main 已定义
}
```

### 错误 2: 变量未定义

```hcl
# ❌ 错误：变量未定义
resource "aws_vpc" "main" {
  cidr_block = var.unknown_var
}

# ✅ 正确：先定义变量
variable "vpc_cidr" {
  type = string
}
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
```

### 错误 3: 循环依赖

```hcl
# ❌ 错误：A 依赖 B，B 依赖 A
resource "aws_security_group" "a" {
  ingress {
    security_groups = [aws_security_group.b.id]
  }
}
resource "aws_security_group" "b" {
  ingress {
    security_groups = [aws_security_group.a.id]
  }
}
```

## 📚 参考资源

- **Terraform 语法**：https://www.terraform.io/docs/language/syntax/index.html
- **AWS Provider**：https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Terraform 函数**：https://www.terraform.io/docs/language/functions/index.html

## ✅ 检查清单

创建文件前：

- [ ] 理解每个文件的作用
- [ ] 知道资源之间的依赖关系
- [ ] 准备好所有变量值
- [ ] 配置好 AWS CLI profile

创建文件后：

- [ ] 运行 `terraform fmt` 格式化
- [ ] 运行 `terraform validate` 验证
- [ ] 运行 `terraform plan` 检查
- [ ] 检查资源数量是否合理

## 🎯 总结

**Terraform 文件构建的核心思路**：

1. **定义输入**（variables.tf）
2. **配置连接**（main.tf provider）
3. **创建资源**（vpc.tf, rds.tf, ecs.tf 等）
4. **定义输出**（outputs.tf）

**关键原则**：
- ✅ 按功能分组
- ✅ 使用变量避免硬编码
- ✅ 使用 locals 避免重复
- ✅ 使用 data 自动获取信息
- ✅ 通过引用建立依赖关系

现在你已经理解了 Terraform 文件的构建方式，可以开始部署了！🚀

