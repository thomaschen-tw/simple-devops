"""
Route definitions for the blog API.
Contains search and create endpoints.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from .models import Article, ArticleCreate, ArticleOut, SessionLocal

router = APIRouter()


def get_db():
    """Provide a SQLAlchemy session per request (FastAPI dependency)."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/search", response_model=List[ArticleOut])
def search_articles(q: str, db: Session = Depends(get_db)):
    """
    Search articles by keyword across title and content using ILIKE.
    Returns results sorted by title in ascending order (A-Z).
    """
    if q is None:
        raise HTTPException(status_code=400, detail="Query parameter 'q' is required")

    keyword = f"%{q}%"
    results = (
        db.query(Article)
        .filter(or_(Article.title.ilike(keyword), Article.content.ilike(keyword)))
        .order_by(Article.title.asc())  # 按标题升序排序（A-Z）
        .all()
    )
    return results


@router.post("/posts", response_model=ArticleOut, status_code=201)
def create_post(article: ArticleCreate, db: Session = Depends(get_db)):
    """
    Create a new article and return the persisted entity.
    """
    new_article = Article(title=article.title, content=article.content)
    db.add(new_article)
    db.commit()
    db.refresh(new_article)
    return new_article

