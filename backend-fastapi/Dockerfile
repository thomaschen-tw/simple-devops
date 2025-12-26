# 构建阶段：使用 uv 安装依赖
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder
WORKDIR /app

# 复制依赖文件
COPY pyproject.toml uv.lock ./

# 安装依赖（使用 --frozen 确保使用 lock 文件，--no-dev 不安装开发依赖）
RUN uv sync --frozen --no-dev

# 运行阶段：使用 Python 官方镜像
FROM python:3.13-slim AS runtime
WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder /app/.venv /app/.venv

# 设置环境变量，使用虚拟环境中的 Python
ENV PATH="/app/.venv/bin:$PATH"

# 复制应用代码和脚本
COPY app ./app
COPY seed_db.py .
COPY start.sh .
RUN chmod +x start.sh

EXPOSE 8000

# Docker 环境中的数据库连接（容器内部通信，使用服务名 postgres）
# 本地开发时，数据库端口映射为 5433->5432，连接字符串在 models.py 中配置
ENV DATABASE_URL="postgresql+psycopg://demo:demo@postgres:5432/demo"

CMD ["./start.sh"]
