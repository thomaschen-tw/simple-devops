# 多平台镜像构建说明

## 已完成的更新

### 1. GitHub Actions 多平台构建

**后端** (`backend.yml`):
- ✅ 添加了 `docker/setup-buildx-action@v3` 设置构建器
- ✅ 添加了 `platforms: linux/amd64,linux/arm64` 支持多平台
- ✅ 添加了构建缓存加速（`cache-from` 和 `cache-to`）

**前端** (`frontend.yml`):
- ✅ 添加了 `docker/setup-buildx-action@v3` 设置构建器
- ✅ 添加了 `platforms: linux/amd64,linux/arm64` 支持多平台
- ✅ 修复了 API 地址配置（`http://localhost:8000` 而不是 `http://backend:8000`）
- ✅ 添加了构建缓存加速

### 2. 前端 API 配置修复

**问题**: 前端在浏览器中运行，无法访问 Docker 容器内的服务名 `backend`

**解决方案**:
- 修改 `frontend-react/Dockerfile`，使用 `http://localhost:8000` 作为默认 API 地址
- 浏览器从宿主机访问，使用 `localhost` 是正确的

### 3. CORS 配置更新

**更新**: `backend-fastapi/app/main.py`
- ✅ 添加了 `http://localhost:30080`（K8s NodePort）支持
- ✅ 保持了 `localhost:5173` 支持

### 4. Docker Compose 配置

**更新**: `docker-compose.prod.yml`
- ✅ 注释掉了 `platform: linux/amd64` 限制
- ✅ Docker 会自动选择匹配的平台镜像（arm64 在 Apple Silicon 上）

## 使用方式

### 等待 GitHub Actions 构建完成

1. **推送代码到 GitHub**:
   ```bash
   git add .
   git commit -m "Add multi-platform build support and fix API config"
   git push
   ```

2. **等待构建完成**:
   - 访问 GitHub Actions 页面查看构建进度
   - 多平台构建需要更长时间（约 10-15 分钟）

3. **拉取新镜像**:
   ```bash
   docker-compose -f docker-compose.prod.yml pull
   docker-compose -f docker-compose.prod.yml up -d
   ```

### 临时解决方案（本地构建测试）

如果想立即测试修复，可以本地构建前端镜像：

```bash
# 构建前端镜像（使用修复后的配置）
cd frontend-react
docker build -t ghcr.io/thomaschen-tw/simple-devops/frontend:local \
  --build-arg VITE_API_BASE_URL=http://localhost:8000 .

# 修改 docker-compose.prod.yml，临时使用本地镜像
# 将 frontend image 改为: ghcr.io/thomaschen-tw/simple-devops/frontend:local

# 启动服务
cd ..
docker-compose -f docker-compose.prod.yml up -d
```

## 多平台构建的优势

### 之前（单平台 amd64）
- ❌ 在 Apple Silicon 上需要模拟运行（性能损失）
- ❌ 启动较慢
- ❌ 资源消耗更高

### 现在（多平台 amd64 + arm64）
- ✅ Apple Silicon 上使用原生 arm64 镜像（性能最佳）
- ✅ 启动更快
- ✅ 资源消耗更低
- ✅ 自动选择匹配的平台

## 验证多平台镜像

构建完成后，可以验证镜像支持的平台：

```bash
# 查看镜像支持的平台
docker manifest inspect ghcr.io/thomaschen-tw/simple-devops/backend:latest

# 应该看到 platforms: ["linux/amd64", "linux/arm64"]
```

## 注意事项

1. **构建时间**: 多平台构建需要构建两个架构的镜像，时间会翻倍
2. **缓存**: 使用了 GitHub Actions 缓存，后续构建会更快
3. **存储**: 多平台镜像占用更多存储空间（GHCR 限制）
4. **自动选择**: Docker 会自动选择匹配的平台，无需手动指定

## 故障排查

### 如果构建失败

1. **检查构建日志**: GitHub Actions 页面查看详细错误
2. **平台特定问题**: 某些依赖可能在特定平台上有问题
3. **缓存问题**: 可以清除缓存重新构建

### 如果拉取后仍使用 amd64

```bash
# 强制拉取 arm64 版本
docker pull --platform linux/arm64 ghcr.io/thomaschen-tw/simple-devops/backend:latest

# 或者删除本地镜像重新拉取
docker rmi ghcr.io/thomaschen-tw/simple-devops/backend:latest
docker-compose -f docker-compose.prod.yml pull
```

## 总结

- ✅ GitHub Actions 已配置多平台构建
- ✅ 前端 API 配置已修复
- ✅ CORS 配置已更新
- ✅ Docker Compose 已优化平台选择

**下一步**: 推送代码，等待 GitHub Actions 构建完成，然后拉取新镜像即可。

