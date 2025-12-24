"""
数据库模型和 Pydantic 模式定义
所有 SQLAlchemy 配置集中在此，保持路由文件简洁
"""

import os
from datetime import datetime

from pydantic import BaseModel
from sqlalchemy import Column, DateTime, Integer, String, Text, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# 数据库连接字符串；可通过环境变量 DATABASE_URL 覆盖（用于 Docker/K8s）
# 使用 psycopg3 驱动（连接字符串格式：postgresql+psycopg://）
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/blog"
)

# 数据库引擎和会话工厂
# future=True 启用 SQLAlchemy 2.0 风格
engine = create_engine(DATABASE_URL, echo=False, future=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

# 声明式模型基类
Base = declarative_base()


class Article(Base):
    """
    博客文章 SQLAlchemy 模型
    对应数据库中的 articles 表
    """

    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class ArticleCreate(BaseModel):
    """
    创建文章的请求体模式
    用于 POST /posts 接口
    """

    title: str
    content: str


class ArticleOut(ArticleCreate):
    """
    返回文章的响应模式
    继承 ArticleCreate，并添加 id 和 created_at 字段
    """

    id: int
    created_at: datetime

    # 使用 model_config 而不是 class Config（Pydantic V2 风格）
    model_config = {"from_attributes": True}
