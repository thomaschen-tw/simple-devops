# 第2周 Day 6–10 本地 K8s 与 CI/CD 初版

**Day 6** 编写 Dockerfile（frontend/backend/postgres），支持多环境配置。
- 编写 `backend-fastapi/Dockerfile`（多阶段构建，Python 3.13 + psycopg3）
- 编写 `frontend-react/Dockerfile`（多阶段构建：Node 构建 + Nginx 运行）
- 创建 `docker-compose.yml`（本地开发环境，自动构建镜像）
- 创建 `docker-compose.prod.yml`（生产环境，使用 GHCR 镜像）
- 编写 `backend-fastapi/start.sh` 启动脚本（自动初始化数据库）
- 配置环境变量支持（DATABASE_URL, VITE_API_BASE_URL）

**Day 7** 编写 GitHub Actions CI/CD：前后端独立工作流，构建并推送镜像到 GHCR。
- 创建 `.github/workflows/backend.yml`（测试 + 构建 + 推送后端镜像）
- 创建 `.github/workflows/frontend.yml`（构建测试 + 构建推送前端镜像）
- 配置路径过滤（只在前端/后端代码变更时触发对应工作流）
- 实现多平台构建（linux/amd64, linux/arm64）
- 配置自动清理旧镜像版本（保留最新 10 个）

**Day 8** 在 CI 中加入后端测试步骤，编写 K8s 部署配置，验证自动部署流程。
- 在 `backend.yml` 中添加 pytest 测试步骤（使用 PYTHONPATH 配置）
- 创建 `k8s/` 目录下的部署配置：
  - `namespace.yaml`（创建 blog 命名空间）
  - `postgres.yaml`（PostgreSQL StatefulSet + Service）
  - `backend.yaml`（后端 Deployment + Service）
  - `frontend.yaml`（前端 Deployment + Service + NodePort）
  - `kind-config.yaml`（Kind 集群配置，端口映射）
- 编写 `deploy.sh` 一键部署脚本
- 验证代码变更触发 CI 并自动部署到 GHCR

