# 🚀 部署指南

本文档包含本地开发和生产环境的完整部署说明。

## 📋 目录

- [快速开始](#快速开始)
- [本地开发环境](#本地开发环境)
- [生产环境部署](#生产环境部署)
- [使用 Makefile](#使用-makefile)
- [故障排查](#故障排查)

## 🚀 快速开始

### 使用 Makefile（推荐）

```bash
# 1. 初始化项目
make install

# 2. 编辑 .env 文件配置环境变量
vim .env

# 3. 启动开发环境
make up

# 4. 查看服务状态
make ps
```

更多 Makefile 命令请参考 [MAKEFILE_GUIDE.md](./MAKEFILE_GUIDE.md)。

## 本地开发环境

### 前提条件

1. ✅ Docker 已安装并运行
2. ✅ （可选）如果使用 GitHub Actions 构建的镜像，需要先登录 GHCR

### 方法一：使用 Makefile（推荐）

```bash
# 启动开发环境
make up

# 查看日志
make logs

# 停止服务
make down
```

### 方法二：使用 docker-compose

```bash
# 启动所有服务
docker compose up

# 后台运行
docker compose up -d

# 停止服务
docker compose down
```

### 关于现有 Postgres 容器

**docker-compose.yml 会启动自己的 Postgres 容器**，端口映射为 `5433:5432`，不会与现有容器冲突。

**现有 Postgres 容器处理方式：**
- ✅ **不需要停止**：docker-compose.yml 使用端口 5433，不会冲突
- ✅ 如果现有容器使用 5433 端口，可以：
  - 停止现有容器：`docker stop <container_name>`
  - 或者修改 docker-compose.yml 中的端口映射

### 访问服务

部署成功后，访问以下地址：

- 🌐 **前端**: http://localhost:5173
- 🔧 **后端 API**: http://localhost:8000
- 📖 **API 文档**: http://localhost:8000/docs
- ❤️ **健康检查**: http://localhost:8000/healthz

### 自动数据库初始化

**✨ 首次启动时会自动初始化数据库！**

后端启动脚本 (`backend-fastapi/start.sh`) 会自动：
1. 等待数据库就绪
2. 创建数据库表（如果不存在）
3. 检查数据库是否已有数据
4. **如果数据库为空，自动运行 `seed_db.py` 填充 100 条测试文章**
5. 如果数据库已有数据，跳过初始化（不会覆盖现有数据）

## 生产环境部署

### 前提条件

1. ✅ GitHub Actions 已成功构建并推送镜像到 GHCR
2. ✅ Docker 已安装并运行
3. ✅ （可选）如果镜像是私有的，需要先登录 GHCR

### 方法一：使用 Makefile（推荐）

```bash
# 1. 配置 .env 文件
vim .env  # 设置 GITHUB_USERNAME 和 GITHUB_REPO

# 2. 部署
make prod-deploy
```

### 方法二：使用部署脚本

```bash
# 一键部署（替换为你的 GitHub 用户名和仓库名）
./deploy.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME

# 例如：
./deploy.sh xiaotongchen simple-devops
```

脚本会自动：
- ✅ 拉取最新的后端和前端镜像
- ✅ 启动 Postgres 数据库
- ✅ 配置所有环境变量（无需手动 export）
- ✅ **自动初始化数据库**：如果数据库为空，会自动运行 `seed_db.py` 填充 100 条测试文章
- ✅ 启动所有服务

### 方法三：手动部署

#### 1. 登录 GHCR（如果镜像是私有的）

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

#### 2. 配置环境变量

编辑 `.env` 文件，设置：
```bash
GITHUB_USERNAME=your_github_username
GITHUB_REPO=your_repo_name
```

#### 3. 拉取并启动

```bash
# 拉取最新镜像
docker compose -f docker-compose.prod.yml pull

# 启动所有服务
docker compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker compose -f docker-compose.prod.yml ps
```

### 访问服务

部署成功后，访问以下地址：

- 🌐 **前端**: http://localhost:5173
- 🔧 **后端 API**: http://localhost:8000
- 📖 **API 文档**: http://localhost:8000/docs
- ❤️ **健康检查**: http://localhost:8000/healthz

## 使用 Makefile

项目提供了 Makefile 来简化常用操作。详细说明请参考 [MAKEFILE_GUIDE.md](./MAKEFILE_GUIDE.md)。

### 常用命令

```bash
# 环境配置
make install        # 初始化项目（创建 .env 文件）
make check-env      # 检查环境变量配置

# 开发环境
make dev            # 启动开发环境
make up             # 启动所有服务（后台运行）
make down           # 停止所有服务
make logs           # 查看日志

# 生产部署
make prod-deploy    # 生产环境部署
make prod-up        # 启动生产环境服务
make prod-down      # 停止生产环境服务

# 数据库管理
make db-shell       # 进入 PostgreSQL 命令行
make db-reset       # 重置数据库
make db-seed        # 填充测试数据

# 测试
make test           # 运行所有测试
```

## 管理命令

### 查看日志

```bash
# 查看所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
docker compose -f docker-compose.prod.yml logs -f postgres

# 使用 Makefile
make logs
make logs-backend
make logs-frontend
make logs-db
```

### 停止服务

```bash
# 停止所有服务
docker compose -f docker-compose.prod.yml down

# 停止并删除数据卷（⚠️ 会删除数据库数据）
docker compose -f docker-compose.prod.yml down -v

# 使用 Makefile
make down
```

### 重启服务

```bash
# 重启所有服务
docker compose -f docker-compose.prod.yml restart

# 使用 Makefile
make restart
```

### 更新部署

当 GitHub Actions 构建了新镜像后：

```bash
# 方法一：使用 Makefile
make prod-deploy

# 方法二：手动更新
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## 环境变量说明

所有环境变量都在 `docker-compose.prod.yml` 中自动配置，**无需手动设置**：

- `DATABASE_URL`: 自动配置为 `postgresql+psycopg://demo:demo@postgres:5432/demo`
- `POSTGRES_USER`: demo
- `POSTGRES_PASSWORD`: demo
- `POSTGRES_DB`: demo

详细环境变量配置请参考 `.env.example` 文件。

## 数据持久化

数据库数据存储在 Docker volume `pgdata` 中，即使容器删除，数据也会保留。

### 查看 volumes

```bash
docker volume ls | grep pgdata
```

### 备份数据

```bash
docker exec blog-postgres pg_dump -U demo demo > backup.sql
```

### 恢复数据

```bash
docker exec -i blog-postgres psql -U demo demo < backup.sql
```

## 故障排查

### 1. 无法拉取镜像

**错误**: `Error response from daemon: pull access denied`

**解决**:
- 检查镜像名称是否正确
- 如果镜像是私有的，先登录 GHCR：
  ```bash
  echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
  ```

### 2. 后端无法连接数据库

**错误**: `could not connect to server`

**解决**:
- 检查 Postgres 容器是否正常运行：`docker compose -f docker-compose.prod.yml ps`
- 查看 Postgres 日志：`docker compose -f docker-compose.prod.yml logs postgres`
- 确保 `depends_on` 配置正确（已配置健康检查）

### 3. 前端无法连接后端

**检查**:
- 后端是否正常运行：访问 http://localhost:8000/healthz
- 查看后端日志：`docker compose -f docker-compose.prod.yml logs backend`
- 检查 CORS 配置（已在代码中配置允许 localhost:5173）

### 4. 端口冲突

**问题**: 端口已被占用

**解决**:
- 检查端口占用：`lsof -i :8000` 或 `lsof -i :5173`
- 修改 `docker-compose.yml` 或 `docker-compose.prod.yml` 中的端口映射
- 或在 `.env` 文件中设置 `BACKEND_PORT` 和 `FRONTEND_PORT`

## 相关文档

- [Makefile 使用指南](./MAKEFILE_GUIDE.md) - Makefile 详细说明
- [项目指南](./PROJECT_GUIDE.md) - 项目架构和设计说明
- [文档索引](./README.md) - 所有文档索引
- [项目主文档](../README.md) - 项目主 README
