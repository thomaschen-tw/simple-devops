# Day 3 工作总结：FastAPI 搜索接口实现与本地联调

## 📋 工作内容
- 在 `app/routes.py` 中实现 GET /search 接口（支持标题和内容模糊搜索）
- 配置 CORS 中间件，允许前端跨域访问
- 实现依赖注入 get_db() 管理数据库会话
- 本地测试搜索功能

## 💭 思考过程

### 1. 路由组织方式
**思考**：路由定义在哪里？直接在 `main.py` 还是单独文件？

**决策**：使用 `APIRouter` 模块化路由
- **原因**：
  - 代码模块化，易于维护
  - 可以在 `include_router` 时统一添加前缀（如 `/api`）
  - 支持多个 router，每个可以有不同的标签
  - 符合 FastAPI 最佳实践

**实现**：
```python
# routes.py
router = APIRouter()

@router.get("/search")
def search_articles(...):
    ...

# main.py
from .routes import router
app.include_router(router)
```

### 2. 搜索实现方式
**思考**：如何实现搜索？全文搜索还是 LIKE 查询？

**决策**：使用 SQLAlchemy 的 `ILIKE`（不区分大小写的 LIKE）
- **原因**：
  - 简单快速，无需额外配置（如 Elasticsearch）
  - 满足初期需求（标题和内容搜索）
  - 后续可以升级到 PostgreSQL 全文搜索
  - 性能对中小型应用足够

**实现**：
```python
keyword = f"%{q.strip()}%"
results = (
    db.query(Article)
    .filter(or_(Article.title.ilike(keyword), Article.content.ilike(keyword)))
    .order_by(Article.created_at.desc())
    .all()
)
```

### 3. 依赖注入设计
**思考**：如何管理数据库会话？全局变量还是依赖注入？

**决策**：使用 FastAPI 的依赖注入系统
- **原因**：
  - 每个请求独立的数据库会话
  - 自动管理会话生命周期（请求结束后自动关闭）
  - 易于测试（可以 mock 数据库会话）
  - 符合 FastAPI 最佳实践

**实现**：
```python
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/search")
def search_articles(q: str, db: Session = Depends(get_db)):
    ...
```

### 4. CORS 配置
**思考**：前端运行在 `localhost:5173`，后端在 `localhost:8000`，如何解决跨域？

**决策**：配置 CORS 中间件
- **原因**：
  - 开发环境前后端分离，必须处理跨域
  - 生产环境可能也需要（如果前后端不同域名）
  - FastAPI 的 CORS 中间件简单易用

**实现**：
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🎨 设计要点

### 1. 错误处理
**设计考虑**：
- 搜索关键词为空时返回 400 错误
- 使用 HTTPException 提供清晰的错误信息

```python
if q is None or q.strip() == "":
    raise HTTPException(status_code=400, detail="Query parameter 'q' is required")
```

### 2. 时区转换
**设计考虑**：
- 数据库存储 UTC 时间
- 返回时转换为上海时区（UTC+8）
- 处理 naive datetime（假设是 UTC）

```python
SHANGHAI_TZ = timezone(timedelta(hours=8))
dt_shanghai = dt.astimezone(SHANGHAI_TZ)
```

### 3. 响应模型
**设计考虑**：
- 使用 Pydantic 模型自动验证和序列化
- 自动生成 API 文档

```python
@router.get("/search", response_model=List[ArticleOut])
def search_articles(...):
    ...
```

## ⚠️ 遇到的问题

### 问题 1：CORS 错误
**现象**：前端调用后端 API 时，浏览器报错 `CORS policy blocked`

**原因**：
- 浏览器安全策略：不同端口视为不同源
- 后端未配置 CORS 中间件

**解决方案**：
1. 添加 CORS 中间件到 `main.py`
2. 配置允许的源（开发环境：`localhost:5173`）
3. 允许所有方法和头部（开发环境，生产环境应限制）

**调试技巧**：
- 查看浏览器控制台的错误信息
- 检查 Network 标签页的请求头（`Origin` 和 `Access-Control-Allow-Origin`）

### 问题 2：数据库会话未关闭
**现象**：长时间运行后，数据库连接数耗尽

**原因**：
- 忘记关闭数据库会话
- 异常时未正确清理资源

**解决方案**：
- 使用 `try...finally` 确保会话关闭
- 使用依赖注入的 `yield` 模式，自动管理生命周期

```python
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()  # 无论是否异常，都会执行
```

### 问题 3：搜索性能问题
**现象**：搜索大量数据时响应慢

**原因**：
- `ILIKE` 查询无法使用索引（通配符开头）
- 没有限制返回数量

**解决方案**：
1. 在 `title` 字段添加索引（虽然 `ILIKE '%keyword%'` 无法使用）
2. 后续可以添加分页（`limit` 和 `offset`）
3. 考虑使用 PostgreSQL 全文搜索（`tsvector`）

### 问题 4：时区转换错误
**现象**：返回的时间显示不正确

**原因**：
- 数据库存储的是 naive datetime（无时区信息）
- 直接转换会出错

**解决方案**：
```python
dt = article.created_at
if dt.tzinfo is None:
    dt = dt.replace(tzinfo=timezone.utc)  # 假设是 UTC
dt_shanghai = dt.astimezone(SHANGHAI_TZ)
```

### 问题 5：模块导入错误
**现象**：运行 uvicorn 时报错 `ModuleNotFoundError: No module named 'app'`

**原因**：
- 工作目录不对
- Python 路径未设置

**解决方案**：
- 必须在 `backend-fastapi` 目录下运行：`cd backend-fastapi && uvicorn app.main:app`
- 或者设置 PYTHONPATH：`export PYTHONPATH=/path/to/backend-fastapi`

## ✅ 解决方案总结

1. **CORS 配置**：开发环境允许所有源，生产环境应限制
2. **资源管理**：使用依赖注入 + try/finally 确保资源释放
3. **性能优化**：添加索引，后续考虑全文搜索和分页
4. **时区处理**：统一假设 UTC，然后转换为目标时区
5. **运行环境**：确保工作目录和 Python 路径正确

## 📚 学到的经验

1. **依赖注入是利器**：自动管理资源生命周期，代码更清晰
2. **CORS 是前后端分离的必修课**：开发环境必须配置
3. **错误处理要全面**：考虑边界情况和异常情况
4. **时区处理要统一**：数据库存 UTC，应用层转换
5. **性能要考虑**：初期可以简单实现，但要预留优化空间

