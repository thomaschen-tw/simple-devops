# Day 7 工作总结：GitHub Actions CI/CD 配置

## 📋 工作内容
- 创建 `.github/workflows/backend.yml`（测试 + 构建 + 推送后端镜像）
- 创建 `.github/workflows/frontend.yml`（构建测试 + 构建推送前端镜像）
- 配置路径过滤（只在前端/后端代码变更时触发对应工作流）
- 实现多平台构建（linux/amd64, linux/arm64）
- 配置自动清理旧镜像版本（保留最新 10 个）

## 💭 思考过程

### 1. CI/CD 策略选择
**思考**：使用什么 CI/CD 平台？GitHub Actions、GitLab CI 还是 Jenkins？

**决策**：使用 GitHub Actions
- **原因**：
  - 与 GitHub 集成，无需额外配置
  - 免费额度足够个人项目使用
  - 配置简单，YAML 格式
  - 支持 Docker 和容器注册表

### 2. 工作流设计
**思考**：一个工作流还是多个工作流？

**决策**：前后端独立工作流
- **原因**：
  - 前后端变更独立，不需要互相触发
  - 并行构建，节省时间
  - 路径过滤，只构建变更的部分
  - 便于维护和调试

**结构**：
```
.github/workflows/
├── backend.yml    # 后端 CI/CD
└── frontend.yml   # 前端 CI/CD
```

### 3. 触发条件设计
**思考**：什么时候触发 CI？

**决策**：路径过滤 + 分支限制
- **触发条件**：
  - `backend-fastapi/**` 变更 → 触发后端工作流
  - `frontend-react/**` 变更 → 触发前端工作流
  - 只在 `main`/`master` 分支
  - PR 时也检查（但不推送镜像）

**好处**：
- 只更新文档时不触发构建（节省资源）
- 只更新后端时不构建前端镜像
- PR 时只测试，不推送

### 4. 镜像注册表选择
**思考**：推送到哪里？Docker Hub 还是 GHCR？

**决策**：GitHub Container Registry (GHCR)
- **原因**：
  - 与 GitHub 集成，无需额外账号
  - 使用 `GITHUB_TOKEN` 自动认证
  - 免费，私有仓库也支持
  - 镜像命名规范：`ghcr.io/owner/repo/service:tag`

### 5. 多平台构建
**思考**：是否需要支持多平台（amd64/arm64）？

**决策**：支持多平台构建
- **原因**：
  - Apple Silicon (M1/M2) 使用 arm64
  - 服务器通常是 amd64
  - 一次构建，多平台使用
  - GitHub Actions 支持，无需额外配置

## 🎨 设计要点

### 1. 工作流结构
**后端工作流**：
1. **测试阶段**：安装依赖 → 运行 pytest
2. **构建推送阶段**：构建镜像 → 推送到 GHCR → 清理旧版本

**前端工作流**：
1. **构建测试阶段**：安装依赖 → 构建项目（验证无错误）
2. **构建推送阶段**：构建镜像 → 推送到 GHCR → 清理旧版本

### 2. 路径过滤
**实现**：
```yaml
on:
  push:
    paths:
      - "backend-fastapi/**"
      - ".github/workflows/backend.yml"
    branches: ["main", "master"]
```

**好处**：
- 只在这些路径变更时触发
- 更新文档不触发构建
- 节省 CI 资源

### 3. 多平台构建
**实现**：
```yaml
- name: Build and push
  uses: docker/build-push-action@v6
  with:
    platforms: linux/amd64,linux/arm64
    push: true
    tags: |
      ghcr.io/${{ github.repository }}/backend:latest
      ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
```

**技术细节**：
- 使用 Docker Buildx（多平台构建工具）
- 自动构建两个平台的镜像
- 使用 manifest list（一个标签，多个平台）

### 4. 版本管理
**设计考虑**：如何管理镜像版本？

**实现**：
- `:latest`：最新版本
- `:${{ github.sha }}`：提交 SHA，用于版本追踪
- 自动清理：保留最新 10 个版本

**好处**：
- `latest` 方便使用
- SHA 标签用于回滚
- 自动清理避免存储空间问题

### 5. 测试优先
**设计考虑**：测试失败时不应该构建镜像

**实现**：
```yaml
build-and-push:
  needs: test  # 只有测试通过才执行
```

**好处**：
- 确保代码质量
- 避免推送有问题的镜像
- 节省构建时间

## ⚠️ 遇到的问题

### 问题 1：路径过滤不生效
**现象**：更新文档时，仍然触发构建

**原因**：
- 路径过滤配置错误
- 或者工作流文件本身变更也会触发

**解决方案**：
```yaml
paths:
  - "backend-fastapi/**"
  - ".github/workflows/backend.yml"  # 工作流文件变更也触发
```

**注意**：工作流文件变更应该触发，以便测试工作流本身

### 问题 2：pytest 导入错误
**现象**：CI 中运行 pytest 时报错 `ModuleNotFoundError: No module named 'app'`

**原因**：
- Python 路径未设置
- 工作目录不对

**解决方案**：
```yaml
defaults:
  run:
    working-directory: backend-fastapi

- name: Run tests
  run: |
    export PYTHONPATH="${PYTHONPATH}:${GITHUB_WORKSPACE}/backend-fastapi"
    pytest -v
```

### 问题 3：GHCR 认证失败
**现象**：推送镜像时，认证失败

**原因**：
- 权限配置不正确
- 或者 token 无效

**解决方案**：
```yaml
permissions:
  contents: read
  packages: write
  id-token: write  # OIDC 认证需要

- name: Log in to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

**注意**：`GITHUB_TOKEN` 是自动生成的，无需手动配置

### 问题 4：多平台构建很慢
**现象**：构建多平台镜像耗时很长

**原因**：
- 需要为每个平台构建
- 没有使用缓存

**解决方案**：
```yaml
cache-from: type=gha   # 使用 GitHub Actions 缓存
cache-to: type=gha,mode=max
```

**好处**：
- 缓存 Docker 层，加速构建
- 只构建变更的部分

### 问题 5：PR 时也推送镜像
**现象**：PR 时也推送到 GHCR，产生很多无用镜像

**原因**：
- 没有区分 push 和 pull_request 事件

**解决方案**：
```yaml
push: ${{ github.event_name != 'pull_request' }}
```

**好处**：
- PR 时只构建，不推送
- 节省存储空间

### 问题 6：镜像清理失败
**现象**：清理旧版本时失败，但不影响整体流程

**原因**：
- 权限问题
- 或者 API 限制

**解决方案**：
```yaml
- name: Delete old package versions
  continue-on-error: true  # 失败也不影响整体流程
```

**好处**：
- 清理失败不影响构建
- 可以手动清理

### 问题 7：前端构建参数
**现象**：前端构建时，API 地址不正确

**原因**：
- Vite 环境变量需要在构建时注入
- 构建参数未传递

**解决方案**：
```yaml
build-args: |
  VITE_API_BASE_URL=http://localhost:8000
```

**注意**：浏览器访问，所以用 localhost

## ✅ 解决方案总结

1. **路径过滤**：只构建变更的部分，节省资源
2. **测试优先**：测试通过才构建镜像
3. **多平台构建**：一次构建，多平台使用
4. **版本管理**：latest + SHA 标签，自动清理
5. **权限配置**：正确配置 GHCR 权限
6. **缓存优化**：使用缓存加速构建
7. **PR 处理**：PR 时只测试，不推送

## 📚 学到的经验

1. **CI/CD 自动化很重要**：减少手动操作，提升效率
2. **路径过滤节省资源**：只构建变更的部分
3. **测试优先原则**：确保代码质量
4. **多平台支持**：一次构建，多平台使用
5. **版本管理**：latest + SHA，便于追踪和回滚
6. **缓存优化**：显著提升构建速度
7. **权限配置**：正确配置才能推送镜像

