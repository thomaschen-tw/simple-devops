把你原始的 **单阶段 Dockerfile** 和我建议的 **多阶段优化版 Dockerfile** 放在一起，并指出修改点。这样你能一眼看到哪些地方被调整了。

---

## 📊 单阶段 vs 多阶段 Dockerfile 对比

| 部分 | 单阶段版本 | 多阶段优化版 | 修改点说明 |
|------|------------|--------------|------------|
| **基础镜像** | `FROM python:3.13-slim AS base` | `FROM python:3.13-slim AS builder` <br> `FROM python:3.13-slim AS runtime` | 拆分为两个阶段：构建阶段和运行阶段 |
| **安装依赖** | 在同一个阶段安装 `build-essential libpq-dev` | 只在 **builder** 阶段安装编译工具，runtime 阶段不安装 | 构建工具只存在于 builder，避免污染最终镜像 |
| **虚拟环境** | 在 base 阶段创建 `/venv` | 在 builder 阶段创建 `/venv`，然后复制到 runtime | 虚拟环境只复制结果，不带构建工具 |
| **requirements 安装** | 在 base 阶段 `pip install -r requirements.txt` | 在 builder 阶段安装依赖，runtime 阶段直接用复制过来的 venv | 运行镜像不需要 pip 或编译工具 |
| **COPY 应用代码** | 直接在 base 阶段复制 `app/ seed_db.py start.sh` | 在 runtime 阶段复制应用代码和脚本 | 保持运行阶段干净，只包含代码和依赖 |
| **清理 apt 缓存** | `rm -rf /var/lib/apt/lists/*` | 同样在 builder 阶段清理 | 保证 builder 阶段更轻量 |
| **最终镜像大小** | 包含 Python + 构建工具 + venv + app | 只包含 Python + venv + app | 多阶段减少 100–200MB 左右 |

---

## 📝 修改后的关键代码片段

### 单阶段（原始）
```dockerfile
FROM python:3.13-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*
RUN python -m venv /venv
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app ./app
COPY seed_db.py .
COPY start.sh .
```

### 多阶段（优化版）
```dockerfile
# 构建阶段
FROM python:3.13-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 运行阶段
FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"
COPY app ./app
COPY seed_db.py .
COPY start.sh .
RUN chmod +x start.sh
```

---

✅ 总结：主要修改点就是 **拆分阶段**、**构建工具只留在 builder**、**运行阶段只复制 venv 和代码**。这样最终镜像更小、更安全、更快。  

要不要我帮你估算一下这两种方式在 **镜像大小上的差异**（比如 MB 数量级对比）？