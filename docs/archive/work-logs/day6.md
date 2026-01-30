# Day 6 工作总结：Dockerfile 编写与多环境配置

## 📋 工作内容
- 编写 `backend-fastapi/Dockerfile`（多阶段构建，Python 3.13 + psycopg3）
- 编写 `frontend-react/Dockerfile`（多阶段构建：Node 构建 + Nginx 运行）
- 创建 `docker-compose.yml`（本地开发环境，自动构建镜像）
- 创建 `docker-compose.prod.yml`（生产环境，使用 GHCR 镜像）
- 编写 `backend-fastapi/start.sh` 启动脚本（自动初始化数据库）
- 配置环境变量支持（DATABASE_URL, VITE_API_BASE_URL）

## 💭 思考过程

### 1. Dockerfile 设计策略
**思考**：单阶段构建还是多阶段构建？

**决策**：使用多阶段构建
- **原因**：
  - **后端**：构建阶段安装依赖，运行阶段只复制虚拟环境（减小镜像体积）
  - **前端**：构建阶段使用 Node.js 构建，运行阶段使用 Nginx（运行时不需要 Node.js）
  - 最终镜像更小，更安全（运行时不需要构建工具）

### 2. 后端 Dockerfile 设计
**思考**：如何优化 Python 应用的 Docker 镜像？

**设计决策**：
```dockerfile
# 构建阶段
FROM python:3.13-slim AS builder
RUN python -m venv /venv
COPY requirements.txt .
RUN pip install -r requirements.txt

# 运行阶段
FROM python:3.13-slim AS runtime
COPY --from=builder /venv /venv
COPY app ./app
```

**优势**：
- 构建工具（build-essential）只在构建阶段，运行阶段不包含
- 虚拟环境独立，便于缓存
- 最终镜像只包含运行时需要的文件

### 3. 前端 Dockerfile 设计
**思考**：如何构建和运行前端应用？

**设计决策**：
```dockerfile
# 构建阶段：使用 Node.js 构建
FROM node:20-alpine AS build
RUN npm install
RUN npm run build

# 运行阶段：使用 Nginx 提供静态文件
FROM nginx:1.27-alpine AS runtime
COPY --from=build /app/dist /usr/share/nginx/html
```

**优势**：
- 运行时不需要 Node.js（镜像更小）
- Nginx 性能好，适合静态文件
- 可以配置 Nginx（如路由、压缩等）

### 4. 环境变量设计
**思考**：如何支持不同环境（开发/生产）？

**设计决策**：
- **后端**：`DATABASE_URL` 环境变量，默认值用于本地开发
- **前端**：`VITE_API_BASE_URL` 构建时注入（Vite 需要构建时知道）

**实现**：
```dockerfile
# 后端
ENV DATABASE_URL="postgresql+psycopg://demo:demo@postgres:5432/demo"

# 前端
ARG VITE_API_BASE_URL=http://localhost:8000
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
```

### 5. 启动脚本设计
**思考**：如何自动化数据库初始化？

**设计决策**：创建 `start.sh` 脚本
- 等待数据库就绪
- 创建数据库表
- 检查数据，如果为空则初始化
- 启动应用

**好处**：
- 完全自动化，无需手动操作
- 新环境友好（自动初始化）
- 已有数据时不会重复初始化

## 🎨 设计要点

### 1. 多阶段构建优化
**后端优化**：
- 构建阶段：安装系统依赖（build-essential, libpq-dev）
- 运行阶段：只复制虚拟环境，不包含构建工具

**前端优化**：
- 构建阶段：Node.js 环境，安装依赖并构建
- 运行阶段：Nginx，只包含构建产物

### 2. 数据库连接等待
**设计考虑**：容器启动顺序问题

**实现**：
```bash
# 等待数据库就绪（最多 30 秒）
for i in {1..30}; do
    if python -c "from app.models import engine; engine.connect()" 2>/dev/null; then
        break
    fi
    sleep 1
done
```

### 3. 数据初始化检查
**设计考虑**：避免重复初始化

**实现**：
```bash
ARTICLE_COUNT=$(python -c "from app.models import Article, SessionLocal; ...")
if [ "$ARTICLE_COUNT" -eq "0" ]; then
    python seed_db.py
fi
```

### 4. Docker Compose 配置
**设计考虑**：开发和生产环境分离

**开发环境** (`docker-compose.yml`)：
- 使用 `build`，从源码构建
- 适合开发时频繁修改代码

**生产环境** (`docker-compose.prod.yml`)：
- 使用 `image`，从 GHCR 拉取
- 快速部署，无需构建

## ⚠️ 遇到的问题

### 问题 1：psycopg3 编译问题
**现象**：构建 Docker 镜像时，psycopg3 安装失败

**原因**：
- psycopg3 需要 libpq-dev（PostgreSQL 开发库）
- Python 3.13-slim 镜像不包含编译工具

**解决方案**：
```dockerfile
# 构建阶段安装构建工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*
```

**注意**：虽然 psycopg[binary] 是二进制包，但某些情况下仍需要 libpq-dev

### 问题 2：前端 API 地址配置
**现象**：Docker 环境中，前端无法访问后端

**原因**：
- 浏览器访问：`http://localhost:8000`（宿主机）
- 容器内访问：`http://backend:8000`（服务名）
- Vite 构建时注入，运行时无法修改

**解决方案**：
- 构建时使用 `http://localhost:8000`（浏览器访问）
- Docker Compose 中通过 `build-args` 传入：
```yaml
frontend:
  build:
    args:
      VITE_API_BASE_URL: http://backend:8000  # 错误！应该是 localhost
      VITE_API_BASE_URL: http://localhost:8000  # 正确
```

**关键理解**：
- Vite 的环境变量在**构建时**注入到代码中
- 浏览器从宿主机访问，所以用 `localhost`
- 容器内的服务名只在容器间通信时使用

### 问题 3：数据库连接超时
**现象**：后端启动时，数据库连接失败

**原因**：
- 数据库容器还未完全启动
- 网络未就绪

**解决方案**：
1. Docker Compose 使用 `depends_on` + `healthcheck`
2. 启动脚本添加重试逻辑（最多 30 秒）

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

### 问题 4：镜像体积过大
**现象**：构建的镜像体积很大（几百 MB）

**原因**：
- 包含构建工具和依赖
- 没有清理缓存

**解决方案**：
- 多阶段构建，运行阶段不包含构建工具
- 使用 `.dockerignore` 排除不需要的文件
- 合并 RUN 命令，减少层数

```dockerfile
RUN apt-get update && apt-get install -y ... && rm -rf /var/lib/apt/lists/*
```

### 问题 5：启动脚本权限
**现象**：容器启动时，`start.sh` 无法执行

**原因**：
- 文件没有执行权限

**解决方案**：
```dockerfile
COPY start.sh .
RUN chmod +x start.sh
```

### 问题 6：环境变量覆盖
**现象**：Dockerfile 中的环境变量无法被 docker-compose 覆盖

**原因**：
- Dockerfile 的 ENV 会被 docker-compose 的 environment 覆盖
- 但 ARG 不会（构建时变量）

**解决方案**：
- 使用 ENV 设置默认值
- docker-compose 中通过 `environment` 覆盖

```yaml
environment:
  DATABASE_URL: postgresql+psycopg://demo:demo@postgres:5432/demo
```

## ✅ 解决方案总结

1. **多阶段构建**：减小镜像体积，提升安全性
2. **依赖安装**：构建阶段安装构建工具，运行阶段不包含
3. **API 地址**：浏览器访问用 localhost，容器间用服务名
4. **启动顺序**：使用 healthcheck 和重试逻辑
5. **权限管理**：确保脚本有执行权限
6. **环境变量**：ENV 设置默认值，docker-compose 可以覆盖

## 📚 学到的经验

1. **多阶段构建是标准做法**：减小镜像，提升安全性
2. **理解构建时 vs 运行时**：Vite 环境变量是构建时注入
3. **容器启动顺序很重要**：使用 healthcheck 和重试
4. **镜像优化**：多阶段构建、清理缓存、合并命令
5. **自动化是关键**：启动脚本自动化，减少手动操作

