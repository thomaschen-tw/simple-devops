"""
数据库种子数据脚本
生成 100 条测试文章，用于本地开发、docker-compose 或预览环境
"""

from datetime import datetime, timedelta, timezone

from app.models import Article, Base, SessionLocal, engine


def seed():
    """
    填充数据库测试数据
    生成 100 条文章，标题格式：article 1, article 2, ..., article 100
    如果数据库中已有数据，会先清空再重新生成
    """
    # 创建表（如果不存在）
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # 清空现有数据，保持数据一致性
        db.query(Article).delete()
        # 使用 timezone-aware datetime（避免弃用警告）
        now = datetime.now(timezone.utc)
        
        # 生成 100 条文章
        for i in range(100):
            article = Article(
                title=f"article {i + 1}",
                content=(
                    "This is a placeholder article for testing search and post APIs. "
                    f"Entry number {i + 1}."
                ),
                created_at=now - timedelta(minutes=i),
            )
            db.add(article)
        db.commit()
        print("✅ 已生成 100 条测试文章")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
