# Simple Blog (React + Vite + FastAPI + Postgres + Docker + CI/CD)

## 架构与目录
- 前端 `frontend-react`：React + Vite，打包后静态资源由 Nginx 提供。
- 后端 `backend-fastapi`：FastAPI + SQLAlchemy，提供 `/search` 与 `/posts`。
- 数据库：Postgres。
- 基础设施：Dockerfile（前后端）、docker-compose（本地多容器），GitHub Actions（CI + GHCR 推送）。

目录速览：
- `backend-fastapi/app/main.py`：FastAPI 入口，CORS、路由注册、健康检查。
- `backend-fastapi/app/routes.py`：搜索/创建接口。
- `backend-fastapi/app/models.py`：SQLAlchemy 模型与 Pydantic schema。
- `backend-fastapi/seed_db.py`：生成 100 条测试文章。
- `backend-fastapi/tests/`：简单健康检查测试。
- `frontend-react/src/pages/*`：搜索、创建页面。
- `frontend-react/src/api.js`：统一 API 调用。
- `docker-compose.yml`：本地开发环境（构建镜像）。
- `docker-compose.prod.yml`：生产环境（使用 GHCR 镜像）。
- `deploy.sh`：一键部署脚本。
- `Makefile`：统一管理常用命令（推荐使用）。
- `.env.example`：环境变量配置模板。
- `.github/workflows/*.yml`：CI 构建、推送镜像到 GHCR。

## 🚀 一键部署（推荐 - 使用 GitHub Actions 构建的镜像）

**无需手动设置环境变量，自动配置数据库连接，自动初始化测试数据！**

**✨ 自动初始化数据库：首次部署时会自动运行 `seed_db.py`，填充 100 条测试文章！**

### 前提条件
1. 确保 GitHub Actions 已成功构建并推送镜像到 GHCR
2. 如果镜像是私有的，需要先登录 GHCR：
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
   ```

### 一键部署
```bash
cd /Users/xiaotongchen/aiTools/simple-devops

# 方法一：使用部署脚本（推荐）
./deploy.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME
# 例如: ./deploy.sh thomaschen-tw simple-devops

# 方法二：手动使用 docker-compose
# 1. 编辑 docker-compose.prod.yml，替换 YOUR_GITHUB_USERNAME 和 YOUR_REPO
# 2. 运行：
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

部署完成后：
- 🌐 前端: http://localhost:5173
- 🔧 后端 API: http://localhost:8000
- 📖 API 文档: http://localhost:8000/docs
- ❤️ 健康检查: http://localhost:8000/healthz

**管理命令：**
```bash
# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 停止服务
docker compose -f docker-compose.prod.yml down

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 查看状态
docker compose -f docker-compose.prod.yml ps
```

## 本地开发启动（docker-compose，使用 demo/demo 账号）

**✨ 自动初始化数据库：首次启动时会自动运行 `seed_db.py`，填充 100 条测试文章！**

```bash
cd /Users/xiaotongchen/aiTools/simple-devops
docker compose up --build
# 前端: http://localhost:5173
# 后端: http://localhost:8000 (健康检查 /healthz)
```

说明：
- 内置 Postgres 版本为 15-alpine，账号/密码/库均为 demo，宿主机映射端口 5433
- 后端启动脚本会自动检测数据库是否为空，如果为空则自动运行 `seed_db.py` 初始化 100 条测试文章
- 如果数据库已有数据，则跳过初始化，不会覆盖现有数据

## 后端单独运行（本地开发，Python 3.13，使用 uv）

**项目使用 uv 包管理器，Python 3.13 版本**

### 方法一：使用 docker-compose（推荐，自动配置环境变量）
```bash
cd /Users/xiaotongchen/aiTools/simple-devops
docker compose up backend postgres
# 数据库连接自动配置，无需手动设置 DATABASE_URL
```

### 方法二：使用 uv（推荐，快速且自动管理虚拟环境）
```bash
# 1. 确保 Postgres 已启动
docker start demo-postgres  # 或使用 docker-compose

# 2. 进入后端目录
cd /Users/xiaotongchen/aiTools/simple-devops/backend-fastapi

# 3. 安装 uv（如果还没有）
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# 4. 安装 Python 3.13 和依赖（自动创建虚拟环境）
uv python install 3.13
uv sync

# 5. 设置数据库连接
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"

# 6. 启动服务
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 其他操作：
# 生成 100 条测试文章
uv run python seed_db.py
# 运行测试
uv run pytest -v
```

### 方法三：传统方式（使用 pip，不推荐）
```bash
# 注意：项目已迁移到 uv，此方法仅用于参考
cd /Users/xiaotongchen/aiTools/simple-devops/backend-fastapi
python3.13 -m venv .venv && source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt  # ⚠️ requirements.txt 已弃用
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**推荐使用方法二（uv）**，更快且自动管理虚拟环境。详细说明请参考 [uv 快速开始指南](backend-fastapi/QUICKSTART.md)。

## 前端单独运行（/frontend-react）
```bash
cd /Users/xiaotongchen/aiTools/simple-devops/frontend-react
npm install
npm run dev
# 前端默认连接 http://localhost:8000
# 若后端不在 localhost:8000，请创建 .env 文件：echo 'VITE_API_BASE_URL=http://your-backend-url:8000' > .env
```

**注意**：前端默认连接 `http://localhost:8000`，请确保后端已启动。

## 使用已有 Postgres 容器（非 compose）- 完整启动流程

### 1. 启动 Postgres 容器（如果还没启动）
```bash
docker run -d --name demo-postgres \
  -e POSTGRES_USER=demo -e POSTGRES_PASSWORD=demo -e POSTGRES_DB=demo \
  -p 5433:5432 postgres:15-alpine
```

### 2. 启动后端服务
```bash
# 进入 backend-fastapi 目录（必须！）
cd /Users/xiaotongchen/aiTools/simple-devops/backend-fastapi

# 激活虚拟环境（如果还没创建，先运行：python3.13 -m venv .venv）
source .venv/bin/activate

# 设置数据库连接（使用 psycopg3 驱动）
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"

# 启动服务（必须在 backend-fastapi 目录下运行）
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 验证后端是否启动成功：访问 http://localhost:8000/healthz 应该返回 {"status":"ok"}
```

### 3. 启动前端服务（新开一个终端）
```bash
cd /Users/xiaotongchen/aiTools/simple-devops/frontend-react
npm install  # 首次运行需要
npm run dev
# 前端会在 http://localhost:5173 启动，自动连接后端 http://localhost:8000
```

### 4. 验证连接
- 前端：http://localhost:5173
- 后端健康检查：http://localhost:8000/healthz
- 后端 API 文档：http://localhost:8000/docs

如果前端仍然提示 "failed to fetch"，请检查：
1. ✅ 后端是否在运行（访问 http://localhost:8000/healthz）
2. ✅ 后端 CORS 配置是否允许 `http://localhost:5173`（已在代码中配置）
3. ✅ 浏览器控制台是否有具体错误信息

## Docker 镜像
- 后端：`backend-fastapi/Dockerfile`（基于 python:3.13-slim，默认 psycopg3 连接 demo:demo@postgres:5432/demo）
- 前端：`frontend-react/Dockerfile`（Node 构建 + Nginx 运行，默认 API 指向 http://backend:8000）
构建示例：
```bash
docker build -t blog-backend:local ./backend-fastapi
docker build -t blog-frontend:local ./frontend-react --build-arg VITE_API_BASE_URL=http://localhost:8000
```

## GitHub Actions（CI/CD）
- `backend.yml`：安装依赖、运行 pytest、构建并推送镜像到 GHCR（`ghcr.io/<owner>/<repo>/backend`）。
- `frontend.yml`：构建 Vite 产物、构建并推送镜像到 GHCR（`ghcr.io/<owner>/<repo>/frontend`）。
- 使用默认 `GITHUB_TOKEN` 推送；替换 `<owner>/<repo>` 为你的仓库路径（或在 workflow 中利用 `${{ github.repository }}` 已自动拼接）。

## 使用 Makefile（推荐）

项目提供了 Makefile 来简化常用操作：

```bash
# 初始化项目（创建 .env 文件）
make install

# 启动开发环境
make up

# 查看所有可用命令
make help
```

更多信息请参考 [MAKEFILE_GUIDE.md](./MAKEFILE_GUIDE.md)。

## 技术要点与学习提示
- FastAPI + SQLAlchemy：见 `app/models.py` 和 `app/routes.py`，包含依赖注入、会话管理、ILike 搜索和 Pydantic schema。
- 数据填充：`seed_db.py` 采用 UTC 时间和批量插入示例，方便搜索验证。
- 测试：`tests/test_health.py` 演示使用 TestClient 做接口探测，可照此扩展。
- 前端：`src/pages/SearchPage.jsx` / `CreatePage.jsx` 展示受控表单、加载态与错误提示；`src/api.js` 使用统一 fetch 封装。
- 部署：Dockerfile 分层构建；docker-compose 一键联调；GH Actions 自动化测试与镜像推送。

## 后续可扩展方向
- 增加分页、标签、作者字段与鉴权。
- 引入 Alembic 迁移而非启动时自动建表。
- 前端添加路由、全局状态、组件测试。


