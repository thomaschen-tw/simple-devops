# Day 8 工作总结：CI 测试集成与 K8s 部署配置

## 📋 工作内容
- 在 `backend.yml` 中添加 pytest 测试步骤（使用 PYTHONPATH 配置）
- 创建 `k8s/` 目录下的部署配置：
  - `namespace.yaml`（创建 blog 命名空间）
  - `postgres.yaml`（PostgreSQL StatefulSet + Service）
  - `backend.yaml`（后端 Deployment + Service）
  - `frontend.yaml`（前端 Deployment + Service + NodePort）
  - `kind-config.yaml`（Kind 集群配置，端口映射）
- 编写 `deploy.sh` 一键部署脚本
- 验证代码变更触发 CI 并自动部署到 GHCR

## 💭 思考过程

### 1. 测试集成策略
**思考**：如何在 CI 中运行测试？需要真实的数据库吗？

**决策**：使用假数据库地址，只测试接口逻辑
- **原因**：
  - CI 环境可能没有数据库
  - 健康检查接口不需要数据库
  - 快速执行，不依赖外部服务
  - 后续可以添加集成测试（需要数据库）

**实现**：
```yaml
- name: Run tests
  env:
    DATABASE_URL: "postgresql+psycopg://test:test@localhost:5432/test"
  run: |
    export PYTHONPATH="${PYTHONPATH}:${GITHUB_WORKSPACE}/backend-fastapi"
    pytest -v
```

### 2. Kubernetes 部署策略
**思考**：使用什么 K8s 发行版？Minikube、kind 还是云服务？

**决策**：使用 kind（Kubernetes in Docker）
- **原因**：
  - 本地开发友好，无需虚拟机
  - 轻量级，启动快
  - 适合学习和测试
  - 免费，无需云账号

### 3. K8s 资源组织
**思考**：如何组织 K8s 配置文件？

**决策**：按资源类型分离
- **结构**：
  - `namespace.yaml`：命名空间
  - `postgres.yaml`：数据库
  - `backend.yaml`：后端服务
  - `frontend.yaml`：前端服务
  - `kind-config.yaml`：集群配置

**好处**：
- 清晰明了，易于维护
- 可以单独应用某个资源
- 符合 K8s 最佳实践

### 4. 服务暴露方式
**思考**：如何暴露服务？NodePort、LoadBalancer 还是 Ingress？

**决策**：
- **前端**：NodePort（30080），方便本地访问
- **后端**：ClusterIP，通过 port-forward 访问
- **原因**：
  - 本地开发，NodePort 足够
  - 生产环境可以升级到 Ingress

### 5. 部署脚本设计
**思考**：如何简化部署流程？

**决策**：创建 `deploy.sh` 一键部署脚本
- **功能**：
  - 替换镜像占位符
  - 应用 K8s 配置
  - 等待服务就绪
  - 显示访问地址

**好处**：
- 自动化部署，减少手动操作
- 统一流程，避免错误
- 新成员友好

## 🎨 设计要点

### 1. 命名空间隔离
**设计考虑**：使用独立的命名空间，避免冲突

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: blog
```

**好处**：
- 资源隔离
- 便于管理
- 可以设置资源限制

### 2. 数据库部署
**设计考虑**：使用 StatefulSet 而非 Deployment

**原因**：
- StatefulSet 保证 Pod 有序启动
- 适合有状态服务（数据库）
- 支持持久化存储

**配置**：
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          value: postgres
        - name: POSTGRES_DB
          value: blog
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

### 3. 后端部署
**设计考虑**：使用 Deployment，支持滚动更新

**配置**：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: backend
        image: ghcr.io/OWNER/REPO/backend:latest
        env:
        - name: DATABASE_URL
          value: postgresql+psycopg://postgres:postgres@postgres:5432/blog
        ports:
        - containerPort: 8000
```

### 4. 前端部署
**设计考虑**：使用 NodePort 暴露服务

**配置**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

### 5. Kind 集群配置
**设计考虑**：映射 NodePort 到宿主机

**配置**：
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
```

## ⚠️ 遇到的问题

### 问题 1：pytest 找不到模块
**现象**：CI 中运行 pytest 时报错 `ModuleNotFoundError`

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

### 问题 2：测试需要数据库
**现象**：某些测试需要真实的数据库连接

**原因**：
- 健康检查测试不需要数据库（已解决）
- 但搜索接口测试需要数据库

**解决方案**：
- 当前：只测试健康检查接口（不需要数据库）
- 后续：可以添加测试数据库，或使用 mock

### 问题 3：镜像占位符替换
**现象**：K8s 配置中使用 `ghcr.io/OWNER/REPO`，需要手动替换

**原因**：
- 不同用户/仓库需要不同配置
- 手动替换容易出错

**解决方案**：
- 创建 `deploy.sh` 脚本，自动替换
- 或者使用环境变量（Kustomize）

```bash
sed -i "s|ghcr.io/OWNER/REPO|ghcr.io/$GITHUB_USERNAME/$REPO_NAME|g" k8s/*.yaml
```

### 问题 4：服务启动顺序
**现象**：后端启动时，数据库还未就绪

**原因**：
- K8s 不保证启动顺序
- 需要等待数据库就绪

**解决方案**：
1. 使用 `initContainers` 等待数据库
2. 或者后端启动脚本已有重试逻辑（start.sh）

```yaml
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nc -z postgres 5432; do sleep 1; done']
```

### 问题 5：持久化存储
**现象**：数据库数据在 Pod 重启后丢失

**原因**：
- 没有配置持久化存储

**解决方案**：
```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 1Gi
```

### 问题 6：NodePort 端口冲突
**现象**：30080 端口已被占用

**原因**：
- 其他服务使用了相同端口

**解决方案**：
- 修改 `kind-config.yaml` 中的端口映射
- 或者修改 `frontend.yaml` 中的 nodePort

### 问题 7：镜像拉取失败
**现象**：K8s 无法拉取 GHCR 镜像

**原因**：
- 镜像未公开，需要认证
- 或者镜像名称不正确

**解决方案**：
1. 创建 Secret 存储认证信息
2. 在 Deployment 中引用 Secret

```yaml
imagePullSecrets:
- name: ghcr-secret
```

## ✅ 解决方案总结

1. **测试集成**：使用假数据库地址，只测试接口逻辑
2. **K8s 配置**：按资源类型分离，清晰明了
3. **服务暴露**：前端 NodePort，后端 ClusterIP + port-forward
4. **部署脚本**：自动化部署，减少手动操作
5. **启动顺序**：使用 initContainers 或启动脚本重试
6. **持久化存储**：数据库使用 PVC，数据不丢失
7. **镜像认证**：私有镜像需要配置 Secret

## 📚 学到的经验

1. **测试策略**：单元测试不需要真实数据库，集成测试需要
2. **K8s 资源组织**：按类型分离，易于维护
3. **服务暴露**：本地开发 NodePort 足够，生产环境用 Ingress
4. **自动化部署**：脚本自动化，减少错误
5. **启动顺序**：使用 initContainers 或重试逻辑
6. **持久化存储**：有状态服务必须配置 PVC
7. **镜像管理**：私有镜像需要认证，公开镜像不需要

