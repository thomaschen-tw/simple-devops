"""
API 路由定义
包含搜索和创建文章的接口
"""

import logging
import os
from datetime import timezone, timedelta
from typing import List

import requests
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy import or_
from sqlalchemy.orm import Session

from .models import Article, ArticleCreate, ArticleOut, SessionLocal, Ticket

# 配置日志
logger = logging.getLogger(__name__)

# 中国上海时区（UTC+8）
SHANGHAI_TZ = timezone(timedelta(hours=8))

# N8N Webhook URL，可通过环境变量覆盖
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL", "http://localhost:5678/webhook-test/new-ticket")

router = APIRouter()


class FeedbackCreate(BaseModel):
    """反馈提交请求体模式"""
    issue_title: str
    issue_description: str
    customer_name: str
    customer_email: EmailStr
    urgency: str  # critical, high, normal, low


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


@router.post("/feedback", status_code=201)
def submit_feedback(feedback: FeedbackCreate, db: Session = Depends(get_db)):
    """
    提交反馈接口
    接收用户反馈，先保存到数据库，然后转发到 n8n webhook 进行自动化处理
    
    数据格式与 n8n.json 工作流完全匹配：
    - issue_title: 问题标题
    - issue_description: 问题描述
    - customer_name: 客户姓名
    - customer_email: 客户邮箱
    - urgency: 紧急程度 (critical, high, normal, low)
    
    n8n 工作流会根据 urgency 进行分支处理：
    - critical: 发送紧急邮件和 Slack 通知
    - high: 发送 Slack 通知
    - normal: 延迟处理
    - low: 自动回复客户邮件
    
    Args:
        feedback: 反馈提交请求体（包含 issue_title, issue_description, customer_name, customer_email, urgency）
        db: 数据库会话（依赖注入）
    
    Returns:
        dict: 提交结果，包含状态和消息
    
    Raises:
        HTTPException: 当数据验证失败时返回错误
    """
    # 验证紧急程度（必须与 n8n.json 中的值完全匹配）
    valid_urgency = ["critical", "high", "normal", "low"]
    if feedback.urgency not in valid_urgency:
        logger.warning(f"Invalid urgency value: {feedback.urgency}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid urgency. Must be one of: {', '.join(valid_urgency)}"
        )
    
    # 准备数据
    ticket_data = {
        "issue_title": feedback.issue_title.strip(),
        "issue_description": feedback.issue_description.strip(),
        "customer_name": feedback.customer_name.strip(),
        "customer_email": feedback.customer_email.strip().lower(),
        "urgency": feedback.urgency.lower()
    }
    
    # 先保存到数据库（确保数据不丢失）
    try:
        new_ticket = Ticket(
            issue_title=ticket_data["issue_title"],
            issue_description=ticket_data["issue_description"],
            customer_name=ticket_data["customer_name"],
            customer_email=ticket_data["customer_email"],
            urgency=ticket_data["urgency"],
            n8n_sent="pending"
        )
        db.add(new_ticket)
        db.commit()
        db.refresh(new_ticket)
        
        logger.info(
            f"工单已保存到数据库: ID={new_ticket.id}, 标题={ticket_data['issue_title']}, "
            f"客户={ticket_data['customer_name']}, 紧急程度={ticket_data['urgency']}"
        )
    except Exception as e:
        db.rollback()
        logger.error(f"保存工单到数据库失败: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="保存工单失败，请稍后重试"
        )
    
    # 然后尝试发送到 n8n webhook（即使失败也不影响返回成功，因为数据已保存）
    n8n_success = False
    try:
        logger.debug(f"发送工单到 n8n webhook: {N8N_WEBHOOK_URL}")
        resp = requests.post(N8N_WEBHOOK_URL, json=ticket_data, timeout=10)
        resp.raise_for_status()
        
        n8n_success = True
        new_ticket.n8n_sent = "success"
        db.commit()
        
        logger.info(f"工单成功提交到 n8n，响应状态: {resp.status_code}")
    except requests.exceptions.RequestException as e:
        # n8n 连接失败，记录但继续（数据已保存）
        logger.warning(f"发送工单到 n8n 失败: {str(e)}")
        new_ticket.n8n_sent = "failed"
        db.commit()
    
    # 根据紧急程度返回不同的提示信息
    urgency_messages = {
        "critical": "紧急工单已提交，我们会立即处理并通知相关人员",
        "high": "高优先级工单已提交，我们会优先处理",
        "normal": "工单已提交，我们会在工作时间内尽快处理",
        "low": "工单已提交，系统已自动发送确认邮件"
    }
    
    # 即使 n8n 失败，也返回成功（因为数据已保存到数据库）
    message = urgency_messages.get(ticket_data["urgency"], "反馈已成功提交，我们会尽快处理")
    if not n8n_success:
        message += "（注意：自动化处理系统暂时不可用，但您的工单已保存）"
    
    return {
        "status": "success",
        "message": message,
        "ticket_id": new_ticket.id,
        "ticket": ticket_data,
        "n8n_sent": n8n_success
    }
