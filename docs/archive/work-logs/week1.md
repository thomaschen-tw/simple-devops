# 第1周 Day 1–5 基础骨架与搜索功能

**Day 1** 仓库初始化，创建前后端项目骨架，编写 README 和项目文档。
- 创建 `backend-fastapi` 目录结构（app/main.py, app/models.py, app/routes.py）
- 创建 `frontend-react` 目录结构（React + Vite 项目）
- 编写项目 README.md 和 PROJECT_GUIDE.md

**Day 2** 设计 PostgreSQL 数据库 schema，编写 seed_db.py 生成 100 条测试文章。
- 在 `app/models.py` 中定义 Article 模型（id, title, content, created_at）
- 实现 `seed_db.py` 脚本，自动生成 100 条测试数据
- 配置 SQLAlchemy 和 Pydantic 模型（ArticleCreate, ArticleOut）

**Day 3** 实现 FastAPI /search 接口（使用 ILIKE 全文搜索），本地联调前后端。
- 在 `app/routes.py` 中实现 GET /search 接口（支持标题和内容模糊搜索）
- 配置 CORS 中间件，允许前端跨域访问
- 实现依赖注入 get_db() 管理数据库会话
- 本地测试搜索功能

**Day 4** 在 React 前端添加搜索页面并调用 /search 接口。
- 创建 `frontend-react/src/pages/SearchPage.jsx` 搜索页面组件
- 实现 `frontend-react/src/api.js` API 调用封装
- 添加搜索表单、加载状态和错误处理
- 实现搜索结果展示和日期格式化

**Day 5** 实现 POST /posts 创建文章接口，完善前端创建页面并联调。
- 在 `app/routes.py` 中实现 POST /posts 接口
- 创建 `frontend-react/src/pages/CreatePage.jsx` 创建页面组件
- 实现表单验证、提交处理和成功提示
- 完善前端路由和页面导航（HomePage, SearchPage, CreatePage）

