# Day 2 工作总结：数据库 Schema 设计与种子数据

## 📋 工作内容
- 在 `app/models.py` 中定义 Article 模型（id, title, content, created_at）
- 实现 `seed_db.py` 脚本，自动生成 100 条测试数据
- 配置 SQLAlchemy 和 Pydantic 模型（ArticleCreate, ArticleOut）

## 💭 思考过程

### 1. 数据库选择
**思考**：选择什么数据库？SQLite、PostgreSQL 还是 MySQL？

**决策**：选择 PostgreSQL
- **原因**：
  - 生产环境常用，功能强大
  - 支持全文搜索（后续可扩展）
  - Docker 部署方便
  - 与 FastAPI + SQLAlchemy 集成良好

### 2. Schema 设计
**思考**：文章表需要哪些字段？如何平衡简单性和扩展性？

**设计决策**：
```python
class Article(Base):
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
```

**设计考虑**：
- `id`：主键，自动递增，添加索引提升查询性能
- `title`：限制 200 字符，添加索引（搜索常用）
- `content`：使用 Text 类型，不限制长度
- `created_at`：自动记录创建时间，使用 UTC 时间

**为什么不用更多字段？**
- 初期保持简单，只实现核心功能
- 后续可以轻松添加：author、tags、updated_at 等

### 3. ORM vs 原生 SQL
**思考**：使用 SQLAlchemy ORM 还是直接写 SQL？

**决策**：使用 SQLAlchemy ORM
- **优势**：
  - 代码更 Pythonic，易于维护
  - 自动处理 SQL 注入问题
  - 支持数据库迁移（后续可用 Alembic）
  - 类型安全，IDE 支持好

### 4. Pydantic 模型设计
**思考**：如何区分请求和响应模型？

**设计决策**：
- `ArticleCreate`：创建请求模型（只有 title 和 content）
- `ArticleOut`：响应模型（包含 id 和 created_at）
- 继承关系：`ArticleOut(ArticleCreate)`，避免重复定义

**好处**：
- 类型安全：FastAPI 自动验证请求数据
- 自动文档生成：Swagger UI 自动显示模型
- 数据转换：自动将 SQLAlchemy 模型转为 Pydantic 模型

## 🎨 设计要点

### 1. 数据库连接配置
```python
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql+psycopg://postgres:postgres@localhost:5432/blog"
)
```

**设计考虑**：
- 使用环境变量，支持不同环境（开发/生产）
- 默认值方便本地开发
- 使用 `psycopg3` 驱动（纯二进制，无需编译）

### 2. 种子数据脚本
**设计思路**：
- 生成 100 条测试数据，方便测试搜索功能
- 使用 UTC 时间，时间间隔递减（模拟不同创建时间）
- 清空现有数据后重新填充（保持数据一致性）

## ⚠️ 遇到的问题

### 问题 1：psycopg2 vs psycopg3
**现象**：Python 3.13 上安装 psycopg2 需要编译，需要安装 PostgreSQL 开发库

**原因**：
- psycopg2 需要编译 C 扩展
- Python 3.13 是较新版本，psycopg2 可能不完全支持

**解决方案**：
- 使用 `psycopg[binary]`（psycopg3 的二进制包）
- 连接字符串格式：`postgresql+psycopg://`（不是 `postgresql://`）
- 无需编译，直接安装即可

### 问题 2：时区处理
**现象**：数据库存储 UTC 时间，但前端显示需要本地时间

**原因**：
- 数据库默认使用 UTC 时间（最佳实践）
- 前端需要转换为用户时区

**解决方案**：
- 数据库存储 UTC 时间（`datetime.utcnow()`）
- 后端返回时转换为上海时区（UTC+8）
- 前端直接显示，无需转换

### 问题 3：表创建时机
**现象**：何时创建数据库表？导入时还是启动时？

**原因**：
- 如果在 `main.py` 导入时创建表，测试环境可能没有数据库
- 如果手动创建，每次部署都需要手动操作

**解决方案**：
- 不在 `main.py` 导入时创建表（避免测试时连接数据库）
- 在启动脚本 `start.sh` 中创建表（生产环境）
- 测试环境可以手动创建或使用内存数据库

### 问题 4：批量插入性能
**现象**：100 条数据逐条插入很慢

**解决方案**：
```python
# 批量添加，最后一次性提交
for i in range(100):
    article = Article(...)
    db.add(article)
db.commit()  # 只提交一次，而不是 100 次
```

## ✅ 解决方案总结

1. **数据库驱动**：使用 `psycopg[binary]`，避免编译问题
2. **时区处理**：数据库存 UTC，后端返回时转换
3. **表创建**：延迟到启动脚本，避免测试时连接数据库
4. **批量操作**：使用批量添加 + 单次提交，提升性能

## 📚 学到的经验

1. **驱动选择很重要**：psycopg3 比 psycopg2 更适合现代 Python
2. **时区统一管理**：数据库存 UTC，应用层转换时区
3. **测试友好设计**：避免在导入时执行数据库操作
4. **性能优化**：批量操作时减少提交次数

