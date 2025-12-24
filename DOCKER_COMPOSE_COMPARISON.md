# Docker Compose 文件对比说明

## 文件概览

项目包含两个 Docker Compose 配置文件，用于不同的使用场景：

- **`docker-compose.yml`** - 本地开发环境
- **`docker-compose.prod.yml`** - 生产环境部署

## 核心区别

### 1. 镜像来源

#### docker-compose.yml（开发环境）
```yaml
backend:
  build:
    context: ./backend-fastapi
  # 从源码构建镜像
```

**特点**:
- 使用 `build` 指令
- 每次启动都会重新构建
- 使用本地代码
- 适合开发时频繁修改代码

#### docker-compose.prod.yml（生产环境）
```yaml
backend:
  image: ghcr.io/thomaschen-tw/simple-devops/backend:latest
  # 使用预构建的镜像
```

**特点**:
- 使用 `image` 指令
- 从 GHCR 拉取镜像
- 无需构建，启动快
- 使用 GitHub Actions 构建的镜像

### 2. 容器命名

#### docker-compose.yml
- 不指定容器名（使用默认命名）
- 格式：`项目名-服务名-序号`

#### docker-compose.prod.yml
- 明确指定容器名
- `blog-postgres`、`blog-backend`、`blog-frontend`
- 便于管理和识别

### 3. 重启策略

#### docker-compose.yml
- 不设置重启策略
- 容器停止后不会自动重启
- 适合开发调试

#### docker-compose.prod.yml
```yaml
restart: unless-stopped
```
- 自动重启策略
- 容器异常退出时自动重启
- 适合生产环境

### 4. 健康检查配置

#### docker-compose.yml
```yaml
healthcheck:
  interval: 5s  # 检查间隔较短
```

#### docker-compose.prod.yml
```yaml
healthcheck:
  interval: 10s  # 检查间隔较长
  # 后端还有额外的健康检查
```

**区别**:
- 开发环境：检查更频繁（快速发现问题）
- 生产环境：检查间隔较长（减少资源消耗）

### 5. 前端构建参数

#### docker-compose.yml
```yaml
frontend:
  build:
    args:
      VITE_API_BASE_URL: http://backend:8000
```
- 构建时注入 API 地址
- 使用 Docker 内部网络地址

#### docker-compose.prod.yml
- 镜像已构建好，无需构建参数
- API 地址在构建时已固定

## 使用场景对比

| 场景 | 使用文件 | 原因 |
|------|---------|------|
| 本地开发，修改代码 | `docker-compose.yml` | 需要重新构建镜像 |
| 快速测试功能 | `docker-compose.prod.yml` | 直接拉取镜像，无需构建 |
| CI/CD 验证 | `docker-compose.prod.yml` | 使用构建好的镜像 |
| 生产部署 | `docker-compose.prod.yml` | 使用稳定镜像 |
| 调试问题 | `docker-compose.yml` | 可以修改代码并重建 |

## 执行命令对比

### 开发环境
```bash
# 构建并启动（每次都会重新构建）
docker compose up --build

# 只启动（如果镜像已存在）
docker compose up
```

### 生产环境
```bash
# 拉取最新镜像
docker compose -f docker-compose.prod.yml pull

# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 查看状态
docker compose -f docker-compose.prod.yml ps
```

## 启动时间对比

### docker-compose.yml
- **首次启动**: ~3-5 分钟（需要构建镜像）
- **后续启动**: ~1-2 分钟（如果代码未变更，使用缓存）
- **代码变更后**: ~3-5 分钟（重新构建）

### docker-compose.prod.yml
- **首次启动**: ~1-2 分钟（拉取镜像）
- **后续启动**: ~30 秒（镜像已存在）
- **更新镜像**: ~1-2 分钟（拉取新镜像）

## 数据持久化

两个文件都使用相同的卷配置：
```yaml
volumes:
  pgdata:
    driver: local
```

**注意**: 
- 两个文件使用**不同的卷名**（通过项目名区分）
- 开发环境和生产环境的数据是**隔离的**
- 如果需要共享数据，需要手动配置卷名

## 网络配置

两个文件都使用默认网络：
- 服务间通过服务名通信（如 `postgres`、`backend`）
- 端口映射相同（避免冲突）
- 前端通过 `http://backend:8000` 访问后端

## 推荐使用方式

### 开发阶段
1. 使用 `docker-compose.yml` 进行开发
2. 修改代码后重新构建测试
3. 提交代码到 GitHub

### 部署阶段
1. GitHub Actions 自动构建镜像
2. 使用 `docker-compose.prod.yml` 部署
3. 拉取最新镜像并启动

### 快速验证
1. 使用 `docker-compose.prod.yml`
2. 无需等待构建
3. 快速验证功能

## 切换使用

### 从开发环境切换到生产环境
```bash
# 停止开发环境
docker compose down

# 启动生产环境
docker compose -f docker-compose.prod.yml up -d
```

### 从生产环境切换到开发环境
```bash
# 停止生产环境
docker compose -f docker-compose.prod.yml down

# 启动开发环境
docker compose up --build
```

## 总结

- **docker-compose.yml**: 开发专用，从源码构建，适合频繁修改
- **docker-compose.prod.yml**: 生产专用，使用预构建镜像，快速部署

两者配置基本相同，主要区别在于镜像来源和重启策略。根据使用场景选择合适的文件即可。

