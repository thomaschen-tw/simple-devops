# GitHub Actions CI/CD 工作流说明

## 工作流概览

项目包含三个独立的 GitHub Actions 工作流：

### 1. `backend.yml` - 后端 CI/CD

**触发条件：**
- `backend-fastapi/**` 目录下的文件变更
- `.github/workflows/backend.yml` 变更

**执行步骤：**
1. ✅ 运行测试（pytest）
2. ✅ 构建 Docker 镜像
3. ✅ 推送到 GHCR（`ghcr.io/OWNER/REPO/backend:latest` 和 `:SHA`）
4. ✅ **自动删除旧版本**（保留最新 10 个版本）

**修复的问题：**
- ✅ 修复了测试导入错误（设置 PYTHONPATH）
- ✅ 添加了自动清理旧镜像功能

### 2. `frontend.yml` - 前端 CI/CD

**触发条件：**
- `frontend-react/**` 目录下的文件变更
- `.github/workflows/frontend.yml` 变更

**执行步骤：**
1. ✅ 安装依赖并构建（npm run build）
2. ✅ 构建 Docker 镜像
3. ✅ 推送到 GHCR（`ghcr.io/OWNER/REPO/frontend:latest` 和 `:SHA`）
4. ✅ **自动删除旧版本**（保留最新 10 个版本）

### 3. `docs.yml` - 文档更新（新增）

**触发条件：**
- `*.md` 文件变更
- `**/*.md` 文件变更
- `docs/**` 目录变更
- `.github/workflows/docs.yml` 变更

**执行步骤：**
- ✅ 检查文档文件
- ✅ 显示更新的文档列表
- ⚠️ **不会触发前后端构建**（节省 CI 资源）

## 路径过滤说明

### 后端工作流
```yaml
paths:
  - "backend-fastapi/**"
  - ".github/workflows/backend.yml"
```
**只在这些路径变更时触发**

### 前端工作流
```yaml
paths:
  - "frontend-react/**"
  - ".github/workflows/frontend.yml"
```
**只在这些路径变更时触发**

### 文档工作流
```yaml
paths:
  - "*.md"
  - "**/*.md"
  - "docs/**"
  - ".github/workflows/docs.yml"
```
**只在这些路径变更时触发，不会触发前后端构建**

## 自动清理旧镜像版本

### 功能说明
- 每次推送新镜像后，自动删除超过 10 个的旧版本
- 保留最新的 10 个版本（包括 `latest` 标签）
- 只在 push 事件时执行（PR 时不执行）

### 配置位置
- `backend.yml`: 删除 `backend` 包的旧版本
- `frontend.yml`: 删除 `frontend` 包的旧版本

### 工作原理
```yaml
- name: Delete old package versions
  if: github.event_name != 'pull_request'
  uses: actions/delete-package-versions@v5
  with:
    package-name: backend  # 或 frontend
    package-type: 'container'
    min-versions-to-keep: 10
    delete-only-untagged-versions: false
```

## 测试修复

### 问题
之前测试失败：`ModuleNotFoundError: No module named 'app'`

### 解决方案
在运行 pytest 前设置 PYTHONPATH：
```yaml
- name: Run tests
  run: |
    export PYTHONPATH="${PYTHONPATH}:${GITHUB_WORKSPACE}/backend-fastapi"
    pytest
```

## 使用场景示例

### 场景 1: 更新后端代码
```bash
# 修改 backend-fastapi/app/routes.py
git add backend-fastapi/app/routes.py
git commit -m "Update routes"
git push
```
**结果：** 只触发 `backend.yml`，构建后端镜像

### 场景 2: 更新前端代码
```bash
# 修改 frontend-react/src/App.jsx
git add frontend-react/src/App.jsx
git commit -m "Update frontend"
git push
```
**结果：** 只触发 `frontend.yml`，构建前端镜像

### 场景 3: 只更新文档
```bash
# 修改 README.md
git add README.md
git commit -m "Update README"
git push
```
**结果：** 只触发 `docs.yml`，**不会构建镜像**，节省 CI 资源

### 场景 4: 同时更新前后端
```bash
# 同时修改前后端代码
git add backend-fastapi/ frontend-react/
git commit -m "Update both"
git push
```
**结果：** 同时触发 `backend.yml` 和 `frontend.yml`，并行构建

## 权限说明

所有工作流都需要以下权限：
- `contents: read` - 读取代码
- `packages: write` - 推送和删除镜像
- `id-token: write` - OIDC 认证（用于 GHCR）

这些权限在 GitHub Actions 中自动配置，无需手动设置。

## 查看工作流状态

1. 访问 GitHub 仓库
2. 点击 "Actions" 标签
3. 查看各个工作流的运行状态
4. 点击具体运行查看详细日志

## 故障排查

### 问题 1: 测试失败
- 检查 PYTHONPATH 是否正确设置
- 确认所有依赖都已安装

### 问题 2: 镜像推送失败
- 检查 GitHub Token 权限
- 确认仓库是公开的或已配置访问权限

### 问题 3: 旧版本未删除
- 确认 `min-versions-to-keep` 设置正确
- 检查是否有足够的权限删除包版本

