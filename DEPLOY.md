# 🚀 生产环境一键部署指南

## 前提条件

1. ✅ GitHub Actions 已成功构建并推送镜像到 GHCR
2. ✅ Docker 已安装并运行
3. ✅ （可选）如果镜像是私有的，需要先登录 GHCR

## 快速开始

### 方法一：使用部署脚本（推荐）

```bash
cd /Users/xiaotongchen/aiTools/simple-devops

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

### 方法二：手动部署

#### 1. 登录 GHCR（如果镜像是私有的）

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

#### 2. 编辑 docker-compose.prod.yml

将文件中的 `YOUR_GITHUB_USERNAME` 和 `YOUR_REPO` 替换为你的实际值：

```yaml
# 修改前
image: ghcr.io/YOUR_GITHUB_USERNAME/YOUR_REPO/backend:latest

# 修改后（示例）
image: ghcr.io/xiaotongchen/simple-devops/backend:latest
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

## 访问服务

部署成功后，访问以下地址：

- 🌐 **前端**: http://localhost:5173
- 🔧 **后端 API**: http://localhost:8000
- 📖 **API 文档**: http://localhost:8000/docs
- ❤️ **健康检查**: http://localhost:8000/healthz

## 管理命令

```bash
# 查看所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
docker compose -f docker-compose.prod.yml logs -f postgres

# 停止所有服务
docker compose -f docker-compose.prod.yml down

# 停止并删除数据卷（⚠️ 会删除数据库数据）
docker compose -f docker-compose.prod.yml down -v

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 更新镜像并重启
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## 环境变量说明

所有环境变量都在 `docker-compose.prod.yml` 中自动配置，**无需手动设置**：

- `DATABASE_URL`: 自动配置为 `postgresql+psycopg://demo:demo@postgres:5432/demo`
- `POSTGRES_USER`: demo
- `POSTGRES_PASSWORD`: demo
- `POSTGRES_DB`: demo

## 自动数据库初始化

**✨ 首次部署时会自动初始化数据库！**

后端启动脚本 (`backend-fastapi/start.sh`) 会自动：
1. 等待数据库就绪
2. 创建数据库表（如果不存在）
3. 检查数据库是否已有数据
4. **如果数据库为空，自动运行 `seed_db.py` 填充 100 条测试文章**
5. 如果数据库已有数据，跳过初始化（不会覆盖现有数据）

这意味着：
- ✅ 新电脑拉取代码后，直接运行 `docker compose up` 即可，无需手动运行 `seed_db.py`
- ✅ 数据库已有数据时，不会重复初始化
- ✅ 完全自动化，无需任何手动操作

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

## 更新部署

当 GitHub Actions 构建了新镜像后：

```bash
# 方法一：使用部署脚本
./deploy.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME

# 方法二：手动更新
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## 数据持久化

数据库数据存储在 Docker volume `pgdata` 中，即使容器删除，数据也会保留。

查看 volumes：
```bash
docker volume ls | grep pgdata
```

备份数据：
```bash
docker exec blog-postgres pg_dump -U demo demo > backup.sql
```

恢复数据：
```bash
docker exec -i blog-postgres psql -U demo demo < backup.sql
```

