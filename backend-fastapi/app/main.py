"""
FastAPI 应用入口文件
配置 CORS、注册路由、提供健康检查接口
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from . import models
from .routes import router

# 注意：表创建已延迟，避免导入时连接数据库
# 表将在 start.sh 脚本中创建，或在首次请求时创建
# 生产环境建议使用数据库迁移工具（如 Alembic）

app = FastAPI(title="Blog API", version="0.1.0")

# 配置 CORS：允许前端从浏览器访问后端 API
# 在 Docker 环境中，前端通过 http://localhost:8000 访问后端
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",      # Vite 开发服务器
        "http://127.0.0.1:5173",      # Vite 开发服务器（备用）
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz")
def health_check():
    """
    健康检查接口
    用于容器健康检查和 CI/CD 测试
    不需要数据库连接
    
    Returns:
        dict: {"status": "ok"}
    """
    return {"status": "ok"}


# 注册所有 API 路由（定义在 app/routes.py 中）
app.include_router(router)
