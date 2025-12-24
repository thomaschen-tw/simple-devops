"""
API 路由定义
包含搜索和创建文章的接口
"""

from datetime import timezone, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from .models import Article, ArticleCreate, ArticleOut, SessionLocal

# 中国上海时区（UTC+8）
SHANGHAI_TZ = timezone(timedelta(hours=8))

router = APIRouter()


def get_db():
    """
    数据库会话依赖注入函数
    为每个请求提供独立的 SQLAlchemy 会话
    请求结束后自动关闭会话
    
    Yields:
        Session: SQLAlchemy 数据库会话
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/search", response_model=List[ArticleOut])
def search_articles(q: str, db: Session = Depends(get_db)):
    """
    搜索文章接口
    根据关键词在标题和内容中搜索文章（使用 ILIKE 模糊匹配，不区分大小写）
    结果按创建时间降序排序（从新到旧）
    所有时间戳转换为中国上海时区（UTC+8）
    
    Args:
        q: 搜索关键词（必填）
        db: 数据库会话（依赖注入）
    
    Returns:
        List[ArticleOut]: 匹配的文章列表，按创建时间降序排序
    
    Raises:
        HTTPException: 当搜索关键词为空时返回 400 错误
    """
    if q is None or q.strip() == "":
        raise HTTPException(status_code=400, detail="Query parameter 'q' is required")

    keyword = f"%{q.strip()}%"
    results = (
        db.query(Article)
        .filter(or_(Article.title.ilike(keyword), Article.content.ilike(keyword)))
        .order_by(Article.created_at.desc())  # 按创建时间降序排序（从新到旧）
        .all()
    )
    
    # 将 UTC 时间转换为中国上海时区（UTC+8）
    # 创建新的 ArticleOut 对象列表，确保时区转换和排序正确
    converted_results = []
    for article in results:
        dt = article.created_at
        if dt.tzinfo is None:
            # 如果数据库存储的是 naive datetime，假设是 UTC
            dt = dt.replace(tzinfo=timezone.utc)
        # 转换为上海时区
        dt_shanghai = dt.astimezone(SHANGHAI_TZ)
        # 创建 ArticleOut 对象，确保时区信息正确传递
        converted_results.append(ArticleOut(
            id=article.id,
            title=article.title,
            content=article.content,
            created_at=dt_shanghai
        ))
    
    return converted_results


@router.get("/posts/{article_id}", response_model=ArticleOut)
def get_article(article_id: int, db: Session = Depends(get_db)):
    """
    获取单篇文章详情接口
    根据文章 ID 获取文章详情
    返回的时间戳转换为中国上海时区（UTC+8）
    
    Args:
        article_id: 文章 ID
        db: 数据库会话（依赖注入）
    
    Returns:
        ArticleOut: 文章详情对象
    
    Raises:
        HTTPException: 当文章不存在时返回 404 错误
    """
    article = db.query(Article).filter(Article.id == article_id).first()
    if article is None:
        raise HTTPException(status_code=404, detail="Article not found")
    
    # 将 UTC 时间转换为中国上海时区（UTC+8）
    dt = article.created_at
    if dt.tzinfo is None:
        # 如果数据库存储的是 naive datetime，假设是 UTC
        dt = dt.replace(tzinfo=timezone.utc)
    # 转换为上海时区
    dt_shanghai = dt.astimezone(SHANGHAI_TZ)
    
    # 创建 ArticleOut 对象，确保时区信息正确传递
    return ArticleOut(
        id=article.id,
        title=article.title,
        content=article.content,
        created_at=dt_shanghai
    )


@router.post("/posts", response_model=ArticleOut, status_code=201)
def create_post(article: ArticleCreate, db: Session = Depends(get_db)):
    """
    创建文章接口
    创建一篇新文章并返回保存后的实体
    返回的时间戳转换为中国上海时区（UTC+8）
    
    Args:
        article: 文章创建请求体（包含 title 和 content）
        db: 数据库会话（依赖注入）
    
    Returns:
        ArticleOut: 创建的文章实体，包含 id 和 created_at
    """
    new_article = Article(title=article.title, content=article.content)
    db.add(new_article)
    db.commit()
    db.refresh(new_article)
    
    # 将 UTC 时间转换为中国上海时区（UTC+8）
    dt = new_article.created_at
    if dt.tzinfo is None:
        # 如果数据库存储的是 naive datetime，假设是 UTC
        dt = dt.replace(tzinfo=timezone.utc)
    # 转换为上海时区并更新对象属性
    new_article.created_at = dt.astimezone(SHANGHAI_TZ)
    return new_article
