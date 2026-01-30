# Makefile 和 .env 使用指南

> **📘 深入学习**: 想了解 Makefile 的设计原理和高级用法？查看 [Makefile 学习指南](./MAKEFILE_LEARNING_GUIDE.md)

本文档介绍如何使用 Makefile 和 .env 文件来简化项目的开发、部署和管理。

## 📋 目录

- [快速开始](#快速开始)
- [环境变量配置](#环境变量配置)
- [Makefile 命令](#makefile-命令)
- [文件整理说明](#文件整理说明)
- [最佳实践](#最佳实践)

## 🚀 快速开始

### 1. 初始化项目

首次使用项目时，运行以下命令初始化环境：

```bash
# 创建 .env 文件（从模板复制）
make install

# 编辑 .env 文件，配置你的环境变量
vim .env  # 或使用你喜欢的编辑器
```

### 2. 启动开发环境

```bash
# 启动所有服务（Docker Compose）
make up

# 或者启动开发模式（热重载）
make dev
```

### 3. 查看帮助

```bash
# 查看所有可用命令
make help
```

## 🔐 环境变量配置

### .env 文件说明

`.env` 文件用于存储敏感信息和环境配置，**不会被提交到 Git**（已在 `.gitignore` 中排除）。

### 创建 .env 文件

```bash
# 方法 1: 使用 Makefile（推荐）
make install

# 方法 2: 手动复制
cp .env.example .env
```

### 必需的环境变量

#### 基础配置

```bash
# 数据库配置
POSTGRES_USER=demo
POSTGRES_PASSWORD=demo          # ⚠️ 生产环境请修改为强密码
POSTGRES_DB=demo
DATABASE_URL=postgresql+psycopg://demo:demo@postgres:5432/demo

# 后端配置
BACKEND_PORT=8000
N8N_WEBHOOK_URL=http://localhost:5678/webhook-test/new-ticket

# 前端配置
FRONTEND_PORT=5173
VITE_API_BASE_URL=http://localhost:8000
```

#### 生产部署配置

```bash
# GitHub Container Registry 配置
GITHUB_USERNAME=your_github_username
GITHUB_REPO=your_repo_name
GITHUB_TOKEN=your_github_token  # 可选，仅私有镜像需要
```

### 环境变量优先级

1. **命令行环境变量**（最高优先级）
2. **.env 文件**
3. **docker-compose.yml 中的默认值**（最低优先级）

### 检查环境变量

```bash
# 检查 .env 文件是否存在以及关键变量是否配置
make check-env
```

## 📝 Makefile 命令

### 环境配置

| 命令 | 说明 |
|------|------|
| `make install` | 初始化项目（创建 .env 文件） |
| `make check-env` | 检查环境变量配置 |

### 开发环境

| 命令 | 说明 |
|------|------|
| `make dev` | 启动开发环境（docker-compose up，前台运行） |
| `make dev-backend` | 仅启动后端服务（开发模式，热重载） |
| `make dev-frontend` | 仅启动前端服务（开发模式，热重载） |

### Docker 管理

| 命令 | 说明 |
|------|------|
| `make build` | 构建 Docker 镜像 |
| `make up` | 启动所有服务（后台运行） |
| `make down` | 停止所有服务 |
| `make restart` | 重启所有服务 |
| `make logs` | 查看所有服务日志 |
| `make logs-backend` | 查看后端日志 |
| `make logs-frontend` | 查看前端日志 |
| `make logs-db` | 查看数据库日志 |
| `make ps` | 查看服务状态 |

### 数据库管理

| 命令 | 说明 |
|------|------|
| `make db-shell` | 进入 PostgreSQL 命令行 |
| `make db-reset` | 重置数据库（删除并重新创建）⚠️ 会删除所有数据 |
| `make db-seed` | 填充测试数据 |

### 测试

| 命令 | 说明 |
|------|------|
| `make test` | 运行所有测试 |
| `make test-backend` | 运行后端测试 |

### 生产部署

| 命令 | 说明 |
|------|------|
| `make prod-deploy` | 生产环境部署（拉取镜像并启动） |
| `make prod-pull` | 拉取最新生产镜像 |
| `make prod-up` | 启动生产环境服务 |
| `make prod-down` | 停止生产环境服务 |

### 清理

| 命令 | 说明 |
|------|------|
| `make clean` | 清理 Docker 资源（容器、镜像、卷） |
| `make clean-all` | 清理所有资源（包括数据卷）⚠️ 会删除数据库数据 |

## 📁 文件整理说明

### 已整理的文件

#### 1. **docker-compose.yml** ✅
- **更新内容**: 使用环境变量替代硬编码值
- **改进**: 
  - 数据库配置从 `.env` 读取
  - 端口配置可自定义
  - 支持不同环境的配置

#### 2. **docker-compose.prod.yml** ✅
- **更新内容**: 使用环境变量配置 GitHub 镜像地址
- **改进**:
  - 不再需要手动修改镜像名称
  - 通过 `.env` 文件统一管理
  - 支持 `BACKEND_IMAGE` 和 `FRONTEND_IMAGE` 环境变量

#### 3. **deploy.sh** ✅
- **更新内容**: 支持从 `.env` 文件读取配置
- **改进**:
  - 可以省略命令行参数（从 `.env` 读取）
  - 不再创建临时文件
  - 与 Makefile 保持一致

### 新增文件

#### 1. **.env.example** ✅
- **用途**: 环境变量配置模板
- **说明**: 包含所有需要的环境变量及其说明
- **使用方法**: `cp .env.example .env` 然后编辑

#### 2. **Makefile** ✅
- **用途**: 统一管理所有常用命令
- **优势**:
  - 简化命令输入
  - 统一接口
  - 自动检查环境变量
  - 提供帮助信息

### 可以进一步整理的文件（可选）

#### 1. **backend-fastapi/start.sh**
- **当前状态**: 已使用环境变量 `DATABASE_URL`
- **建议**: 保持现状，无需修改



## 🎯 最佳实践

### 1. 环境变量管理

```bash
# ✅ 推荐：使用 .env 文件
# 1. 复制模板
cp .env.example .env

# 2. 编辑配置
vim .env

# 3. 检查配置
make check-env
```

### 2. 开发流程

```bash
# 1. 初始化项目
make install

# 2. 启动开发环境
make up

# 3. 查看日志
make logs

# 4. 运行测试
make test

# 5. 停止服务
make down
```

### 3. 生产部署流程

```bash
# 1. 配置 .env 文件
vim .env  # 设置 GITHUB_USERNAME 和 GITHUB_REPO

# 2. 部署
make prod-deploy

# 3. 查看状态
make ps

# 4. 查看日志
make logs
```

### 4. 安全建议

1. **永远不要提交 .env 文件**
   - ✅ `.env` 已在 `.gitignore` 中
   - ✅ 只提交 `.env.example`

2. **使用强密码**
   - ⚠️ 生产环境必须修改默认密码
   - ✅ 使用密码生成器生成强密码

3. **保护敏感信息**
   - ✅ 使用环境变量而不是硬编码
   - ✅ 定期轮换密钥和密码

4. **不同环境使用不同的 .env 文件**
   - 开发环境: `.env.dev`
   - 生产环境: `.env.prod`
   - 使用 `--env-file` 参数指定

## 🔄 迁移指南

### 从旧方式迁移到 Makefile

#### 旧方式
```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 部署生产环境
./deploy.sh username repo-name
```

#### 新方式（推荐）
```bash
# 启动服务
make up

# 查看日志
make logs

# 部署生产环境
make prod-deploy  # 需要先在 .env 中配置 GITHUB_USERNAME 和 GITHUB_REPO
```

## ❓ 常见问题

### Q: .env 文件应该放在哪里？
A: 放在项目根目录，与 `docker-compose.yml` 同级。

### Q: 如何在不同环境使用不同的配置？
A: 可以创建多个 .env 文件（如 `.env.dev`, `.env.prod`），然后使用：
```bash
# 开发环境
docker-compose --env-file .env.dev up

# 生产环境
docker-compose --env-file .env.prod -f docker-compose.prod.yml up
```

### Q: Makefile 命令失败怎么办？
A: 
1. 检查 `.env` 文件是否存在：`make check-env`
2. 查看错误信息
3. 确保 Docker 正在运行：`docker info`

### Q: 如何添加新的 Makefile 命令？
A: 编辑 `Makefile`，添加新的 target：
```makefile
my-command: ## 我的自定义命令
    @echo "执行自定义命令"
```

## 📚 相关文档

- [DEPLOY.md](./DEPLOY.md) - 部署文档
- [LOCAL_DEPLOY.md](./LOCAL_DEPLOY.md) - 本地部署文档
- [README.md](./README.md) - 项目说明

## 🤝 贡献

如果你有改进建议，欢迎提交 Issue 或 Pull Request！
