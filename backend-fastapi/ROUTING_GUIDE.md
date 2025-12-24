# FastAPI 路由定义指南

## 两种路由定义方式

### 方式一：直接在 `main.py` 中定义（不推荐用于大型项目）

```python
# main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/api/search")
def search_articles():
    return {"message": "search"}

@app.post("/api/posts")
def create_post():
    return {"message": "create"}
```

**特点：**
- ✅ 简单直接，适合小型项目
- ❌ 所有路由都在一个文件中，难以维护
- ❌ 代码组织不够清晰

### 方式二：使用 `APIRouter` + `include_router`（推荐，当前项目使用的方式）

```python
# routes.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/search")  # 注意：这里没有 /api 前缀
def search_articles():
    return {"message": "search"}

# main.py
from fastapi import FastAPI
from .routes import router

app = FastAPI()
app.include_router(router, prefix="/api")  # 在这里添加前缀
```

**特点：**
- ✅ 代码模块化，易于维护
- ✅ 可以在挂载时统一添加前缀
- ✅ 支持多个 router，每个可以有不同的前缀
- ✅ 推荐用于中大型项目

## 当前项目的路由结构

### 当前实现（无前缀）

```python
# routes.py
router = APIRouter()

@router.get("/search")  # 实际路径: /search
def search_articles():
    ...

# main.py
app.include_router(router)  # 没有 prefix，所以路径就是 /search
```

**访问路径：**
- `GET /search`
- `POST /posts`

### 如果添加 `/api` 前缀

```python
# routes.py（不需要修改）
router = APIRouter()

@router.get("/search")  # 相对路径
def search_articles():
    ...

# main.py（只需要修改这里）
app.include_router(router, prefix="/api")  # 添加前缀
```

**访问路径：**
- `GET /api/search`
- `POST /api/posts`

## 路径前缀的几种方式

### 1. 在 `include_router` 时添加前缀（推荐）

```python
# main.py
app.include_router(router, prefix="/api")
```

**优点：**
- 集中管理前缀
- 修改方便
- 可以为不同的 router 设置不同的前缀

### 2. 在 `APIRouter` 创建时添加前缀

```python
# routes.py
router = APIRouter(prefix="/api")

@router.get("/search")  # 实际路径: /api/search
def search_articles():
    ...
```

**优点：**
- 前缀定义在 router 内部
- 适合该 router 的所有路由都需要相同前缀的情况

### 3. 在路由装饰器中直接写完整路径

```python
# routes.py
router = APIRouter()

@router.get("/api/search")  # 完整路径
def search_articles():
    ...
```

**不推荐：**
- 如果以后要改前缀，需要修改每个路由
- 不够灵活

## 多个 Router 的示例

```python
# routes.py
router = APIRouter()

@router.get("/search")
def search_articles():
    ...

# admin_routes.py
admin_router = APIRouter()

@admin_router.get("/users")
def list_users():
    ...

# main.py
from .routes import router
from .admin_routes import admin_router

app = FastAPI()

# 普通 API 使用 /api 前缀
app.include_router(router, prefix="/api")

# 管理 API 使用 /admin 前缀
app.include_router(admin_router, prefix="/admin")
```

**访问路径：**
- `GET /api/search`
- `GET /admin/users`

## 最佳实践建议

### 1. 使用 Router 模块化（当前项目已采用）

```python
# ✅ 推荐：使用 APIRouter
router = APIRouter()
@router.get("/search")
def search_articles():
    ...

app.include_router(router, prefix="/api")
```

### 2. 统一添加前缀

```python
# ✅ 推荐：在 include_router 时统一添加
app.include_router(router, prefix="/api", tags=["articles"])
```

### 3. 使用 tags 组织 API 文档

```python
# routes.py
router = APIRouter(tags=["文章管理"])

@router.get("/search", summary="搜索文章")
def search_articles():
    ...

# main.py
app.include_router(router, prefix="/api")
```

## 当前项目如何添加 `/api` 前缀

如果你想为当前项目添加 `/api` 前缀，只需要修改 `main.py`：

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from . import models
from .routes import router

models.Base.metadata.create_all(bind=models.engine)

app = FastAPI(title="Blog API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/healthz")
def health_check():
    return {"status": "ok"}

# 添加 prefix="/api" 即可
app.include_router(router, prefix="/api")
```

然后前端也需要更新 API 地址：
```javascript
// frontend-react/src/api.js
const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";

export async function searchArticles(query) {
  const url = new URL("/api/search", API_BASE);  // 添加 /api 前缀
  // ...
}
```

## 总结

| 方式 | 定义位置 | 前缀位置 | 适用场景 |
|------|---------|---------|---------|
| 直接在 main.py | `main.py` | 路由装饰器中 | 小型项目，路由少 |
| APIRouter + include_router | `routes.py` | `include_router` 的 prefix 参数 | **推荐**，中大型项目 |
| APIRouter 自带 prefix | `routes.py` | `APIRouter(prefix=...)` | 单个 router 需要独立前缀 |

**当前项目使用的是方式二（APIRouter + include_router），这是最佳实践！**

