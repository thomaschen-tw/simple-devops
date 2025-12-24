"""
健康检查测试
这些测试不需要数据库连接，可以在 CI 环境中运行
"""
import os
import sys

# 在导入 app 模块之前设置假的 DATABASE_URL
# 这样可以防止导入时尝试连接数据库
# 健康检查接口不需要数据库，所以这是安全的
os.environ["DATABASE_URL"] = "postgresql+psycopg://test:test@localhost:5432/test"

from fastapi.testclient import TestClient

# 在设置环境变量后导入
from app.main import app

# 使用 FastAPI 的 TestClient 进行简单的集成测试
client = TestClient(app)


def test_healthz():
    """
    测试健康检查接口
    健康检查接口应该返回 200 状态码和 {"status": "ok"}
    此接口不需要数据库连接
    """
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
