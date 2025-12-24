#!/bin/bash
# 后端启动脚本：自动初始化数据库并启动应用
# 如果数据库为空，会自动运行 seed_db.py 填充测试数据

set -e

echo "🚀 启动 FastAPI 后端服务..."

# 等待数据库就绪（最多等待 30 秒）
echo "⏳ 等待数据库连接..."
for i in {1..30}; do
    if python -c "from app.models import engine; engine.connect()" 2>/dev/null; then
        echo "✅ 数据库连接成功"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ 数据库连接超时"
        exit 1
    fi
    sleep 1
done

# 创建表（如果不存在）
echo "📋 创建数据库表..."
python -c "from app.models import Base, engine; Base.metadata.create_all(bind=engine)"

# 检查数据库是否已有数据
echo "🔍 检查数据库数据..."
ARTICLE_COUNT=$(python -c "
from app.models import Article, SessionLocal
db = SessionLocal()
try:
    count = db.query(Article).count()
    print(count)
except Exception as e:
    print('0')
finally:
    db.close()
" 2>/dev/null || echo "0")

if [ "$ARTICLE_COUNT" -eq "0" ]; then
    echo "📦 数据库为空，开始初始化测试数据..."
    python seed_db.py
    echo "✅ 已初始化 100 条测试文章"
else
    echo "ℹ️  数据库已有 $ARTICLE_COUNT 条文章，跳过初始化"
fi

# 启动应用
echo "🌐 启动 FastAPI 应用..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000

