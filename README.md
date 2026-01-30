# Simple Blog (React + Vite + FastAPI + Postgres + Docker + CI/CD)

一个前后端分离的个人博客项目，展示从开发到部署的完整 DevOps 流程。

## 🚀 快速开始

### 方法一：使用 Makefile（推荐）

最简单的方式，一键启动所有服务：

```bash
# 1. 初始化项目（创建 .env 文件）
make install

# 2. 编辑 .env 文件配置环境变量（可选，有默认值）
vim .env

# 3. 启动开发环境（后台运行）
make up

# 4. 查看服务状态
make ps

# 5. 查看日志
make logs

# 生产环境部署
make prod-deploy  # 或 ./deploy.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME
```

访问服务：
- 🌐 前端: http://localhost:5173
- 🔧 后端 API: http://localhost:8000
- 📖 API 文档: http://localhost:8000/docs
- ❤️ 健康检查: http://localhost:8000/healthz

### 方法二：使用 Docker Compose

使用 Docker Compose 启动所有服务（数据库、后端、前端）：

#### 本地开发环境

```bash
# 1. 进入项目目录
cd /Users/xiaotongchen/aiTools/simple-devops

# 2. 启动所有服务（前台运行，可以看到日志）
docker compose up

# 或者后台运行
docker compose up -d

# 3. 查看服务状态
docker compose ps

# 4. 查看日志
docker compose logs -f              # 所有服务日志
docker compose logs -f backend      # 后端日志
docker compose logs -f frontend     # 前端日志
docker compose logs -f postgres     # 数据库日志

# 5. 停止服务
docker compose down                 # 停止并删除容器
docker compose down -v             # 停止并删除容器和数据卷（⚠️ 会删除数据库数据）
```

**说明**：
- Docker Compose 会自动构建镜像（如果不存在）
- 数据库端口映射为 `5433:5432`（宿主机:容器），避免与本地 PostgreSQL 冲突
- 后端端口：`8000:8000`
- 前端端口：`5173:80`
- **首次启动会自动初始化数据库**，填充 100 条测试文章

#### 生产环境部署

```bash
# 方法一：使用 Makefile（推荐）
make prod-deploy

# 方法二：使用部署脚本
./deploy.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME

# 方法三：手动部署
# 1. 配置 .env 文件
vim .env  # 设置 GITHUB_USERNAME 和 GITHUB_REPO

# 2. 拉取镜像并启动
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# 3. 查看状态
docker compose -f docker-compose.prod.yml ps
```

### 方法三：本地命令行手动启动（开发调试）

适合需要热重载和调试的开发场景。

#### 前置准备

1. **安装依赖工具**：
   ```bash
   # 安装 uv（Python 包管理器）
   curl -LsSf https://astral.sh/uv/install.sh | sh
   export PATH="$HOME/.local/bin:$PATH"
   
   # 安装 Node.js（如果还没有）
   # macOS: brew install node
   # 或访问 https://nodejs.org/ 下载安装
   ```

2. **启动 PostgreSQL 数据库**：

   方式 A：使用 Docker（推荐）
   ```bash
   # 启动 PostgreSQL 容器
   docker run -d --name demo-postgres \
     -e POSTGRES_USER=demo \
     -e POSTGRES_PASSWORD=demo \
     -e POSTGRES_DB=demo \
     -p 5433:5432 \
     postgres:15-alpine
   
   # 验证数据库是否运行
   docker ps | grep demo-postgres
   ```

   方式 B：使用本地 PostgreSQL
   ```bash
   # macOS: brew services start postgresql@15
   # 或使用系统自带的 PostgreSQL
   # 确保端口为 5433（或修改下面的连接字符串）
   ```

#### 启动后端服务

```bash
# 1. 进入后端目录
cd /Users/xiaotongchen/aiTools/simple-devops/backend-fastapi

# 2. 安装 Python 3.13（如果还没有）
uv python install 3.13

# 3. 安装项目依赖（自动创建虚拟环境）
uv sync

# 4. 设置数据库连接环境变量
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"

# 5. 初始化数据库（首次运行）
# 创建表
uv run python -c "from app.models import Base, engine; Base.metadata.create_all(bind=engine)"

# 填充测试数据（如果数据库为空）
uv run python seed_db.py

# 6. 启动后端服务（开发模式，支持热重载）
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 或者使用传统方式
# source .venv/bin/activate
# uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**验证后端**：
- 访问 http://localhost:8000/healthz 应该返回 `{"status":"ok"}`
- 访问 http://localhost:8000/docs 查看 API 文档

#### 启动前端服务

**新开一个终端窗口**，执行：

```bash
# 1. 进入前端目录
cd /Users/xiaotongchen/aiTools/simple-devops/frontend-react

# 2. 安装依赖（首次运行）
npm install

# 3. 启动开发服务器（支持热重载）
npm run dev

# 如果后端不在 localhost:8000，需要配置 API 地址
# 创建 .env 文件：
# echo 'VITE_API_BASE_URL=http://your-backend-url:8000' > .env
# 然后重新运行 npm run dev
```

**验证前端**：
- 前端会在 http://localhost:5173 启动
- 浏览器会自动打开，或手动访问 http://localhost:5173

#### 完整启动流程总结

```bash
# 终端 1: 启动数据库
docker run -d --name demo-postgres \
  -e POSTGRES_USER=demo -e POSTGRES_PASSWORD=demo -e POSTGRES_DB=demo \
  -p 5433:5432 postgres:15-alpine

# 终端 2: 启动后端
cd backend-fastapi
uv sync
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"
uv run python -c "from app.models import Base, engine; Base.metadata.create_all(bind=engine)"
uv run python seed_db.py  # 首次运行
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 终端 3: 启动前端
cd frontend-react
npm install  # 首次运行
npm run dev
```

#### 常见问题排查

**后端无法连接数据库**：
```bash
# 检查数据库是否运行
docker ps | grep demo-postgres

# 检查端口是否正确
lsof -i :5433

# 测试数据库连接
docker exec -it demo-postgres psql -U demo -d demo -c "SELECT 1;"
```

**前端无法连接后端**：
- 确认后端正在运行：访问 http://localhost:8000/healthz
- 检查浏览器控制台错误信息
- 确认 CORS 配置正确（代码中已配置允许 localhost:5173）

**端口冲突**：
```bash
# 检查端口占用
lsof -i :8000  # 后端端口
lsof -i :5173  # 前端端口
lsof -i :5433  # 数据库端口

# 停止占用端口的进程或修改配置
```

## 📁 项目结构

```
simple-devops/
├── backend-fastapi/      # 后端服务（FastAPI + SQLAlchemy）
├── frontend-react/       # 前端服务（React + Vite）
├── docs/                 # 详细文档
├── docker-compose.yml    # 本地开发环境
├── docker-compose.prod.yml # 生产环境
├── Makefile              # 统一命令管理
├── .env.example          # 环境变量模板
└── README.md             # 本文件
```

## 🛠️ 技术栈

- **前端**: React 18 + Vite + Nginx
- **后端**: FastAPI + SQLAlchemy + psycopg3
- **数据库**: PostgreSQL 15
- **容器化**: Docker + Docker Compose
- **CI/CD**: GitHub Actions + GHCR

## 📚 文档

详细文档请查看 [docs/](./docs/) 目录：

- [部署指南](./docs/DEPLOYMENT.md) - 本地开发和生产环境部署说明
- [Makefile 使用指南](./docs/MAKEFILE_GUIDE.md) - Makefile 命令详解
- [项目指南](./docs/PROJECT_GUIDE.md) - 项目架构和设计说明
- [工作日志](./docs/README.md) - 开发过程记录

## 🔧 常用命令

```bash
# 查看所有可用命令
make help

# 开发环境
make dev            # 启动开发环境
make up             # 启动所有服务（后台）
make down           # 停止所有服务
make logs           # 查看日志

# 生产部署
make prod-deploy    # 生产环境部署
make prod-up        # 启动生产环境
make prod-down      # 停止生产环境

# 数据库管理
make db-shell       # 进入数据库命令行
make db-reset       # 重置数据库
make db-seed        # 填充测试数据

# 测试
make test           # 运行所有测试
```

## ✨ 特性

- ✅ 自动数据库初始化（首次启动自动填充测试数据）
- ✅ 环境变量配置（使用 .env 文件）
- ✅ Docker Compose 一键部署
- ✅ GitHub Actions CI/CD
- ✅ Makefile 统一命令管理
- ✅ 健康检查端点
- ✅ API 文档自动生成

## 📖 更多信息

- **部署问题？** 查看 [部署指南](./docs/DEPLOYMENT.md)
- **Makefile 使用？** 查看 [Makefile 指南](./docs/MAKEFILE_GUIDE.md)
- **项目架构？** 查看 [项目指南](./docs/PROJECT_GUIDE.md)
- **所有文档？** 查看 [文档索引](./docs/README.md)
- **开发历史？** 查看 [归档日志](./docs/archive/)

## 🤝 贡献

欢迎提交 Issue 或 Pull Request！

## 📄 许可证

MIT License
