# Multi-stage build: install deps then run app (Python 3.13)
FROM python:3.13-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/venv/bin:$PATH"

WORKDIR /app

# Install build essentials and libpq-dev (for psycopg3 binary compatibility)
# Note: psycopg[binary] usually doesn't need compilation, but keeping libpq-dev for compatibility
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

RUN python -m venv /venv
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app ./app
COPY seed_db.py .
COPY start.sh .

# 添加执行权限
RUN chmod +x start.sh

EXPOSE 8000

ENV DATABASE_URL="postgresql+psycopg://demo:demo@postgres:5432/demo"

# 使用启动脚本，自动初始化数据库
CMD ["./start.sh"]

