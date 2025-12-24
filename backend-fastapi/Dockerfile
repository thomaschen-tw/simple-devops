# 多阶段构建：安装依赖后运行应用（Python 3.13）
FROM python:3.13-slim AS base

# 设置 Python 环境变量
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/venv/bin:$PATH"

WORKDIR /app

# 安装构建工具和 libpq-dev（用于 psycopg3 二进制兼容性）
# 注意：psycopg[binary] 通常不需要编译，但保留 libpq-dev 以确保兼容性
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

# 创建虚拟环境并安装依赖
RUN python -m venv /venv
COPY requirements.txt .
RUN pip install -r requirements.txt

# 复制应用代码和脚本
COPY app ./app
COPY seed_db.py .
COPY start.sh .

# 添加启动脚本执行权限
RUN chmod +x start.sh

EXPOSE 8000

# 设置数据库连接字符串（可在 docker-compose 中覆盖）
ENV DATABASE_URL="postgresql+psycopg://demo:demo@postgres:5432/demo"

# 使用启动脚本，自动初始化数据库
CMD ["./start.sh"]
