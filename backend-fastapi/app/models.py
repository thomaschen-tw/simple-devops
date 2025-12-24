"""
Database models and Pydantic schemas for the blog API.
All SQLAlchemy configuration lives here to keep routes thin.
"""

import os
from datetime import datetime

from pydantic import BaseModel
from sqlalchemy import Column, DateTime, Integer, String, Text, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Database connection string; override via DATABASE_URL in docker/k8s.
# Using psycopg3 driver (`postgresql+psycopg://`).
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/blog"
)

# Engine and session factory; future=True opts in to SQLAlchemy 2.0 style.
engine = create_engine(DATABASE_URL, echo=False, future=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

# Base class for declarative models.
Base = declarative_base()


class Article(Base):
    """SQLAlchemy model representing a blog article."""

    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class ArticleCreate(BaseModel):
    """Request payload schema for creating an article."""

    title: str
    content: str


class ArticleOut(ArticleCreate):
    """Response schema for returning an article."""

    id: int
    created_at: datetime

    class Config:
        # Allow Pydantic to read from ORM objects.
        from_attributes = True

