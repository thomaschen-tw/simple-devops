# 📚 Simple DevOps 项目完整指南

## 项目概述

这是一个前后端分离的个人博客项目，展示了从开发到部署的完整 DevOps 流程。项目使用 React + Vite 作为前端，FastAPI + PostgreSQL 作为后端，并包含 Docker、Kubernetes 和 CI/CD 的完整实践。

## 架构设计

### 技术栈

- **前端**: React 18 + Vite + Nginx
- **后端**: FastAPI + SQLAlchemy + psycopg3
- **数据库**: PostgreSQL 15
- **容器化**: Docker + Docker Compose
- **编排**: Kubernetes (kind)
- **CI/CD**: GitHub Actions + GHCR

### 项目结构

```
simple-devops/
├── backend-fastapi/          # 后端服务
│   ├── app/                 # 应用代码
│   │   ├── main.py         # FastAPI 应用入口
│   │   ├── models.py       # 数据模型和数据库配置
│   │   ├── routes.py       # API 路由定义
│   │   └── __init__.py     # Python 包标识
│   ├── tests/              # 测试代码
│   │   └── test_health.py # 健康检查测试
│   ├── Dockerfile          # 后端镜像构建文件
│   ├── start.sh            # 启动脚本（自动初始化数据库）
│   ├── seed_db.py          # 数据库种子数据脚本
│   └── requirements.txt    # Python 依赖
├── frontend-react/          # 前端服务
│   ├── src/                # 源代码
│   │   ├── App.jsx         # 主应用组件
│   │   ├── api.js          # API 调用封装
│   │   ├── pages/          # 页面组件
│   │   │   ├── HomePage.jsx
│   │   │   ├── SearchPage.jsx
│   │   │   └── CreatePage.jsx
│   │   └── main.jsx        # 入口文件
│   ├── Dockerfile          # 前端镜像构建文件（多阶段构建）
│   ├── nginx.conf          # Nginx 配置
│   └── package.json        # Node.js 依赖
├── k8s/                    # Kubernetes 配置
│   ├── namespace.yaml      # 命名空间
│   ├── postgres.yaml       # PostgreSQL 部署
│   ├── backend.yaml        # 后端部署
│   ├── frontend.yaml        # 前端部署
│   └── kind-config.yaml    # Kind 集群配置
├── .github/workflows/      # GitHub Actions
│   ├── backend.yml         # 后端 CI/CD
│   ├── frontend.yml        # 前端 CI/CD
│   ├── docs.yml           # 文档更新工作流
│   └── CI_SUMMARY.md      # CI/CD 说明文档
├── docker-compose.yml      # 本地开发环境
├── docker-compose.prod.yml # 生产环境（使用 GHCR 镜像）
├── deploy.sh               # 一键部署脚本
└── README.md               # 项目说明

```

## 核心文件详解

### 后端文件

#### `backend-fastapi/app/main.py`
**作用**: FastAPI 应用入口点
**设计思路**: 
- 创建 FastAPI 应用实例
- 配置 CORS 中间件，允许前端跨域访问
- 注册路由（通过 `include_router`）
- **不在这里创建数据库表**（避免导入时连接数据库，影响测试）

**关键方法**:
- `app = FastAPI()` - 创建应用实例
- `app.add_middleware(CORSMiddleware)` - 添加 CORS 支持
- `app.include_router(router)` - 挂载路由
- `@app.get("/healthz")` - 健康检查端点

#### `backend-fastapi/app/models.py`
**作用**: 数据模型和数据库配置
**设计思路**:
- 使用 SQLAlchemy ORM 定义数据模型
- 使用 Pydantic 定义请求/响应模型
- 环境变量配置数据库连接（支持 Docker/K8s）
- 使用 psycopg3 驱动（纯二进制，无需编译）

**关键组件**:
- `Article` - SQLAlchemy 模型（对应数据库表）
- `ArticleCreate` - 创建请求的 Pydantic 模型
- `ArticleOut` - 响应数据的 Pydantic 模型
- `engine` - SQLAlchemy 引擎
- `SessionLocal` - 数据库会话工厂

#### `backend-fastapi/app/routes.py`
**作用**: API 路由定义
**设计思路**:
- 使用 `APIRouter` 模块化路由（而非直接在 main.py 中定义）
- 通过 `Depends(get_db)` 实现依赖注入，自动管理数据库会话
- 使用 SQLAlchemy 的 `ilike` 实现不区分大小写的搜索

**关键路由**:
- `GET /search?q=keyword` - 搜索文章（按标题升序）
- `POST /posts` - 创建文章

**关键方法**:
- `get_db()` - 数据库会话依赖注入
- `search_articles()` - 搜索逻辑
- `create_post()` - 创建逻辑

#### `backend-fastapi/start.sh`
**作用**: 容器启动脚本，自动初始化数据库
**设计思路**:
- 等待数据库就绪（最多 30 秒）
- 自动创建数据库表
- 检查数据库是否为空，如果为空则运行 `seed_db.py`
- 启动 FastAPI 应用

**为什么需要**: 
- 确保数据库就绪后再启动应用
- 新环境自动初始化，无需手动操作
- 避免重复初始化（检查现有数据）

#### `backend-fastapi/seed_db.py`
**作用**: 生成测试数据
**设计思路**:
- 创建 100 条测试文章
- 使用 UTC 时间，时间间隔递减（模拟不同创建时间）
- 清空现有数据后重新填充（保持数据一致性）

### 前端文件

#### `frontend-react/src/App.jsx`
**作用**: 主应用组件，管理页面导航
**设计思路**:
- 使用 React Hooks (`useState`) 管理页面状态
- 三个页面：主页、搜索页、创建页
- 顶部导航栏始终显示，方便切换

**关键状态**:
- `currentPage` - 当前页面（'home' | 'search' | 'create'）

#### `frontend-react/src/api.js`
**作用**: API 调用封装
**设计思路**:
- 统一管理 API 基础地址（通过环境变量配置）
- 封装 fetch 调用，统一错误处理
- 支持不同环境（开发/Docker/K8s）

**关键函数**:
- `searchArticles(query)` - 搜索文章
- `createArticle(payload)` - 创建文章

#### `frontend-react/src/pages/HomePage.jsx`
**作用**: 主页，提供导航入口
**设计思路**: 
- 友好的欢迎界面
- 大按钮引导用户进入搜索或创建页面
- 通过 `onNavigate` 回调切换页面

#### `frontend-react/src/pages/SearchPage.jsx`
**作用**: 搜索页面
**设计思路**:
- 受控表单组件（React 最佳实践）
- 加载状态和错误处理
- 实时显示搜索结果

**关键状态**:
- `query` - 搜索关键词
- `results` - 搜索结果
- `loading` - 加载状态
- `error` - 错误信息

#### `frontend-react/src/pages/CreatePage.jsx`
**作用**: 创建文章页面
**设计思路**:
- 表单验证（required 字段）
- 提交后清空表单
- 成功/错误提示
- 创建成功后可选跳转

### Docker 配置

#### `docker-compose.yml` vs `docker-compose.prod.yml`

**docker-compose.yml（本地开发）**:
- **用途**: 本地开发环境
- **构建方式**: `build` - 从源码构建镜像
- **适用场景**: 
  - 开发时修改代码
  - 需要热重载
  - 调试和测试
- **特点**:
  - 每次启动都会重新构建
  - 使用本地代码
  - 适合频繁修改代码的场景

**docker-compose.prod.yml（生产环境）**:
- **用途**: 生产环境部署
- **构建方式**: `image` - 使用 GitHub Actions 构建的镜像
- **适用场景**:
  - 使用已构建好的镜像
  - 快速部署
  - 生产环境
- **特点**:
  - 直接拉取镜像，无需构建
  - 使用 GHCR 上的镜像
  - 部署速度快
  - 包含健康检查和自动重启

**对比表**:

| 特性 | docker-compose.yml | docker-compose.prod.yml |
|------|-------------------|------------------------|
| 镜像来源 | 本地构建 | GHCR 拉取 |
| 构建时间 | 每次启动都构建 | 只拉取，不构建 |
| 适用场景 | 开发环境 | 生产环境 |
| 代码更新 | 修改代码后需重建 | 拉取新镜像即可 |
| 启动速度 | 较慢（需构建） | 较快（只拉取） |

### CI/CD 配置

#### `.github/workflows/backend.yml`
**作用**: 后端 CI/CD 流程
**触发条件**: `backend-fastapi/**` 目录变更
**执行流程**:
1. **测试阶段**: 
   - 设置 Python 3.13
   - 安装依赖
   - 运行 pytest（设置 PYTHONPATH 避免导入错误）
2. **构建和推送阶段**:
   - 登录 GHCR
   - 构建 Docker 镜像
   - 推送镜像（`:latest` 和 `:${{ github.sha }}`）
   - 删除旧版本（保留最新 10 个）

**关键设计**:
- 路径过滤：只在后端代码变更时触发
- 测试优先：先测试再构建
- 版本管理：自动清理旧镜像

#### `.github/workflows/frontend.yml`
**作用**: 前端 CI/CD 流程
**触发条件**: `frontend-react/**` 目录变更
**执行流程**:
1. **构建和测试阶段**:
   - 设置 Node.js 20
   - 安装依赖（使用缓存）
   - 构建项目（`npm run build`）
2. **构建和推送阶段**:
   - 构建 Docker 镜像（多阶段构建）
   - 推送镜像
   - 删除旧版本

**关键设计**:
- 多阶段构建：Node 构建 + Nginx 运行
- 构建参数：`VITE_API_BASE_URL` 在构建时注入

#### `.github/workflows/docs.yml`
**作用**: 文档更新工作流
**触发条件**: `*.md` 文件变更
**设计思路**:
- 只更新文档时不触发前后端构建
- 节省 CI 资源
- 显示更新的文档列表

### Kubernetes 配置

#### `k8s/` 目录
**作用**: Kubernetes 部署配置
**设计思路**:
- 使用 Kind 本地 K8s 集群
- 分离配置：namespace、数据库、后端、前端
- 使用 NodePort 暴露服务（前端 30080）

**关键文件**:
- `namespace.yaml` - 创建独立的命名空间
- `postgres.yaml` - PostgreSQL StatefulSet + Service
- `backend.yaml` - 后端 Deployment + Service
- `frontend.yaml` - 前端 Deployment + Service + NodePort
- `kind-config.yaml` - Kind 集群配置（端口映射）

## 数据流设计

### 请求流程

1. **用户操作** → 前端页面（`SearchPage.jsx` 或 `CreatePage.jsx`）
2. **API 调用** → `api.js` 中的函数
3. **HTTP 请求** → 后端 FastAPI（`routes.py`）
4. **数据库操作** → SQLAlchemy（`models.py`）
5. **响应返回** → 前端展示结果

### 数据库初始化流程

1. **容器启动** → `start.sh` 执行
2. **等待数据库** → 检查连接（最多 30 秒）
3. **创建表** → `Base.metadata.create_all()`
4. **检查数据** → 查询文章数量
5. **初始化数据** → 如果为空，运行 `seed_db.py`
6. **启动应用** → `uvicorn app.main:app`

## 设计决策说明

### 1. 为什么使用 APIRouter 而不是直接在 main.py 定义路由？

**原因**:
- 代码模块化，易于维护
- 可以在 `include_router` 时统一添加前缀（如 `/api`）
- 支持多个 router，每个可以有不同的前缀和标签
- 符合 FastAPI 最佳实践

**参考**: `ROUTING_GUIDE.md`

### 2. 为什么不在 main.py 导入时创建数据库表？

**原因**:
- 避免测试时连接数据库（测试环境可能没有数据库）
- 延迟初始化，由启动脚本控制
- 更好的错误处理（启动脚本可以等待数据库就绪）

**实现**: `start.sh` 负责创建表

### 3. 为什么使用 psycopg3 而不是 psycopg2？

**原因**:
- psycopg3 有纯二进制包（`psycopg[binary]`），无需编译
- Python 3.13 上 psycopg2 需要编译，需要 `pg_config`
- psycopg3 性能更好，API 更现代

### 4. 为什么前端使用多阶段构建？

**原因**:
- 第一阶段：Node.js 构建（需要 Node 环境）
- 第二阶段：Nginx 运行（只需要静态文件）
- 最终镜像更小（不包含 Node.js）
- 更安全（运行时不需要 Node）

### 5. 为什么使用路径过滤触发 CI？

**原因**:
- 只更新文档时不触发构建（节省资源）
- 只更新后端时不构建前端镜像
- 并行构建，提高效率

### 6. 为什么自动删除旧镜像版本？

**原因**:
- GHCR 有存储限制
- 保留最新 10 个版本足够回滚
- 自动清理，无需手动管理

## 执行流程

### 本地开发流程

1. **启动数据库**:
   ```bash
   docker run -d --name demo-postgres \
     -e POSTGRES_USER=demo -e POSTGRES_PASSWORD=demo -e POSTGRES_DB=demo \
     -p 5433:5432 postgres:15-alpine
   ```

2. **启动后端**:
   ```bash
   cd backend-fastapi
   source .venv/bin/activate
   export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"
   uvicorn app.main:app --reload
   ```

3. **启动前端**:
   ```bash
   cd frontend-react
   npm install
   npm run dev
   ```

### Docker Compose 开发流程

```bash
# 使用本地构建
docker compose up --build
```

**流程**:
1. 构建后端镜像（从 `backend-fastapi/Dockerfile`）
2. 构建前端镜像（从 `frontend-react/Dockerfile`）
3. 启动 Postgres 容器
4. 启动后端容器（自动初始化数据库）
5. 启动前端容器

### 生产部署流程

```bash
# 使用 GHCR 镜像
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

**流程**:
1. 从 GHCR 拉取最新镜像
2. 启动 Postgres 容器
3. 启动后端容器（使用预构建镜像）
4. 启动前端容器（使用预构建镜像）

### CI/CD 流程

1. **代码推送** → GitHub
2. **路径检测** → GitHub Actions 检测变更路径
3. **触发工作流** → 对应的 workflow 运行
4. **运行测试** → pytest 或 npm build
5. **构建镜像** → Docker build
6. **推送镜像** → GHCR
7. **清理旧版本** → 删除超过 10 个的旧版本

## 关键设计模式

### 1. 依赖注入（FastAPI）
- 使用 `Depends(get_db)` 自动管理数据库会话
- 每个请求自动创建和关闭会话
- 避免全局数据库连接

### 2. 模块化路由（APIRouter）
- 路由定义在 `routes.py`
- 在 `main.py` 中统一挂载
- 支持前缀和标签

### 3. 环境变量配置
- 数据库连接通过 `DATABASE_URL` 配置
- 前端 API 地址通过 `VITE_API_BASE_URL` 配置
- 支持不同环境（开发/生产）

### 4. 健康检查
- 后端：`/healthz` 端点
- Docker Compose：`healthcheck` 配置
- Kubernetes：`livenessProbe` 和 `readinessProbe`

### 5. 自动初始化
- 启动脚本自动检测并初始化数据库
- 避免手动操作
- 新环境友好

## 学习要点

### FastAPI 相关
- **依赖注入**: `Depends()` 的使用
- **路由模块化**: `APIRouter` + `include_router`
- **Pydantic 模型**: 请求/响应验证
- **CORS 配置**: 跨域请求处理

### React 相关
- **Hooks**: `useState` 管理状态
- **受控组件**: 表单输入控制
- **异步处理**: `async/await` 和错误处理
- **环境变量**: `import.meta.env`

### Docker 相关
- **多阶段构建**: 减小镜像体积
- **健康检查**: 确保服务就绪
- **卷管理**: 数据持久化
- **网络配置**: 服务间通信

### CI/CD 相关
- **路径过滤**: 智能触发构建
- **并行构建**: 前后端独立构建
- **版本管理**: 自动清理旧版本
- **环境隔离**: 测试和生产分离

## 扩展方向

### 功能扩展
- 添加用户认证（JWT）
- 添加文章标签和分类
- 添加分页功能
- 添加文章编辑和删除

### 技术扩展
- 使用 Alembic 进行数据库迁移
- 添加 Redis 缓存
- 添加 Elasticsearch 全文搜索
- 使用 Helm Chart 管理 K8s 部署

### 监控和日志
- 集成 Prometheus 监控
- 添加日志聚合（ELK）
- 添加 APM（应用性能监控）

## 总结

这个项目展示了现代 Web 应用开发的完整流程：
- ✅ 前后端分离架构
- ✅ 容器化部署
- ✅ CI/CD 自动化
- ✅ Kubernetes 编排
- ✅ 最佳实践应用

每个文件都有其特定的作用，共同构成了一个可维护、可扩展、可部署的完整系统。

