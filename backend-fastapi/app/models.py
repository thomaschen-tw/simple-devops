"""
数据库模型和 Pydantic 模式定义
所有 SQLAlchemy 配置集中在此，保持路由文件简洁
"""

import os
from datetime import datetime

from pydantic import BaseModel
from sqlalchemy import Column, DateTime, Integer, String, Text, Enum as SQLEnum, create_engine
import enum
from sqlalchemy.orm import declarative_base, sessionmaker

# 数据库连接字符串；可通过环境变量 DATABASE_URL 覆盖（用于 Docker/K8s）
# 使用 psycopg3 驱动（连接字符串格式：postgresql+psycopg://）
# 本地开发默认端口：5434（映射到容器内部 5432）
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5434/blog"
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


class UrgencyLevel(str, enum.Enum):
    """工单紧急程度枚举"""
    CRITICAL = "critical"
    HIGH = "high"
    NORMAL = "normal"
    LOW = "low"


class Ticket(Base):
    """
    工单/反馈 SQLAlchemy 模型
    对应数据库中的 tickets 表
    """

    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    issue_title = Column(String(200), nullable=False, index=True)
    issue_description = Column(Text, nullable=False)
    customer_name = Column(String(100), nullable=False)
    customer_email = Column(String(255), nullable=False, index=True)
    urgency = Column(String(20), nullable=False, index=True)  # critical, high, normal, low
    n8n_sent = Column(String(10), default="pending")  # pending, success, failed
    created_at = Column(DateTime, default=datetime.utcnow)
