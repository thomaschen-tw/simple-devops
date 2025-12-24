# 🚀 本地 Docker 部署指南

## 前提条件

1. ✅ Docker 已安装并运行
2. ✅ GitHub Actions 已成功构建镜像
3. ✅ （可选）如果镜像是私有的，需要登录 GHCR

## 关于现有 Postgres 容器

### 情况 1: 使用 docker-compose.prod.yml 中的 Postgres（推荐）

**docker-compose.prod.yml 会启动自己的 Postgres 容器**，端口映射为 `5433:5432`，不会与现有容器冲突。

**现有 Postgres 容器处理方式：**
- ✅ **不需要停止**：docker-compose.prod.yml 使用端口 5433，不会冲突
- ✅ 如果现有容器使用 5433 端口，可以：
  - 停止现有容器：`docker stop <container_name>`
  - 或者修改 docker-compose.prod.yml 中的端口映射

### 情况 2: 使用现有 Postgres 容器

如果你想使用现有的 Postgres 容器，需要：

1. **确保现有容器配置匹配：**
   - 用户：`demo`
   - 密码：`demo`
   - 数据库：`demo`
   - 端口：`5433`（宿主机）

2. **修改 docker-compose.prod.yml：**
   ```yaml
   services:
     # 注释掉 postgres 服务
     # postgres:
     #   ...
     
     backend:
       # 修改 DATABASE_URL 指向现有容器
       environment:
         DATABASE_URL: postgresql+psycopg://demo:demo@host.docker.internal:5433/demo
       # 移除 depends_on postgres
   ```

## 快速部署（方法一：使用部署脚本）

```bash
cd /Users/xiaotongchen/aiTools/simple-devops

# 一键部署
./deploy.sh thomaschen-tw simple-devops
```

脚本会自动：
- ✅ 拉取最新镜像
- ✅ 启动所有服务（包括 Postgres）
- ✅ 自动初始化数据库

## 快速部署（方法二：手动部署）

### 1. 登录 GHCR（如果镜像是私有的）

```bash
# 生成 Personal Access Token: https://github.com/settings/tokens
# 选择权限：repo, read:packages, write:packages

echo $GITHUB_TOKEN | docker login ghcr.io -u thomaschen-tw --password-stdin
```

### 2. 拉取镜像

```bash
# 拉取后端镜像
docker pull ghcr.io/thomaschen-tw/simple-devops/backend:latest

# 拉取前端镜像
docker pull ghcr.io/thomaschen-tw/simple-devops/frontend:latest
```

### 3. 启动服务

```bash
cd /Users/xiaotongchen/aiTools/simple-devops

# 使用生产环境配置启动
docker compose -f docker-compose.prod.yml up -d
```

### 4. 查看服务状态

```bash
docker compose -f docker-compose.prod.yml ps
```

### 5. 查看日志

```bash
# 查看所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
docker compose -f docker-compose.prod.yml logs -f postgres
```

## 访问服务

部署成功后，访问以下地址：

- 🌐 **前端**: http://localhost:5173
- 🔧 **后端 API**: http://localhost:8000
- 📖 **API 文档**: http://localhost:8000/docs
- ❤️ **健康检查**: http://localhost:8000/healthz

## 管理命令

### 停止服务

```bash
docker compose -f docker-compose.prod.yml down
```

### 停止并删除数据卷（⚠️ 会删除数据库数据）

```bash
docker compose -f docker-compose.prod.yml down -v
```

### 重启服务

```bash
docker compose -f docker-compose.prod.yml restart
```

### 更新镜像并重启

```bash
# 拉取最新镜像
docker compose -f docker-compose.prod.yml pull

# 重启服务
docker compose -f docker-compose.prod.yml up -d
```

## 端口说明

| 服务 | 容器端口 | 宿主机端口 | 说明 |
|------|---------|-----------|------|
| Postgres | 5432 | 5433 | 避免与现有 Postgres 冲突 |
| Backend | 8000 | 8000 | FastAPI 服务 |
| Frontend | 80 | 5173 | Nginx 服务 |

## 故障排查

### 1. 无法拉取镜像

**错误**: `pull access denied` 或 `unauthorized`

**解决**:
```bash
# 登录 GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u thomaschen-tw --password-stdin

# 或者检查镜像是否为公开
# 访问: https://github.com/thomaschen-tw/simple-devops/pkgs/container/backend
```

### 2. 端口冲突

**错误**: `port is already allocated`

**解决**:
```bash
# 检查占用端口的容器
docker ps | grep -E '5433|8000|5173'

# 停止冲突的容器
docker stop <container_id>

# 或修改 docker-compose.prod.yml 中的端口映射
```

### 3. 数据库连接失败

**检查**:
```bash
# 检查 Postgres 容器是否运行
docker compose -f docker-compose.prod.yml ps postgres

# 查看 Postgres 日志
docker compose -f docker-compose.prod.yml logs postgres

# 检查后端日志
docker compose -f docker-compose.prod.yml logs backend
```

### 4. 前端无法连接后端

**检查**:
- 后端是否正常运行：访问 http://localhost:8000/healthz
- 查看后端日志：`docker compose -f docker-compose.prod.yml logs backend`

## 使用现有 Postgres 容器的完整示例

如果你想使用现有的 Postgres 容器（例如 `demo-postgres`）：

### 1. 创建自定义配置

```bash
# 复制配置
cp docker-compose.prod.yml docker-compose.custom.yml
```

### 2. 编辑 docker-compose.custom.yml

```yaml
services:
  # 注释掉 postgres 服务
  # postgres:
  #   ...

  backend:
    image: ghcr.io/thomaschen-tw/simple-devops/backend:latest
    environment:
      # 使用 host.docker.internal 访问宿主机上的容器
      DATABASE_URL: postgresql+psycopg://demo:demo@host.docker.internal:5433/demo
    # 移除 depends_on postgres
    ports:
      - "8000:8000"

  frontend:
    image: ghcr.io/thomaschen-tw/simple-devops/frontend:latest
    ports:
      - "5173:80"
    depends_on:
      - backend
```

### 3. 启动服务

```bash
docker compose -f docker-compose.custom.yml up -d
```

## 验证部署

```bash
# 1. 检查所有容器运行状态
docker compose -f docker-compose.prod.yml ps

# 2. 检查健康状态
curl http://localhost:8000/healthz

# 3. 访问前端
open http://localhost:5173
```

## 总结

**推荐方式：**
- ✅ 使用 `docker-compose.prod.yml`（包含 Postgres）
- ✅ 端口映射为 5433，不会与现有容器冲突
- ✅ **不需要停止现有 Postgres 容器**

**如果现有容器使用 5433 端口：**
- 停止现有容器，或
- 修改 docker-compose.prod.yml 中的端口映射

