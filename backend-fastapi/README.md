# Backend FastAPI 项目

## 🐍 Python 版本

**本项目使用 Python 3.13**

- ✅ 配置要求：`requires-python = ">=3.13"`（见 `pyproject.toml`）
- ✅ Docker 镜像：`python:3.13-slim`
- ✅ CI/CD：`uv python install 3.13`

**注意**：
- ⚠️ 某些 IDE 或工具可能推荐 Python 3.12.9（这是工具的默认推荐）
- ✅ 但本项目**明确要求 Python 3.13**
- ✅ 请使用 `uv python install 3.13` 安装正确的版本

## 📦 包管理器

**本项目使用 uv 包管理器**

- ✅ 配置文件：`pyproject.toml` + `uv.lock`
- ✅ 虚拟环境：`.venv/`（由 uv 自动管理）
- ⚠️ `requirements.txt` 已弃用（保留仅作参考）

## 🚀 快速开始

### 1. 安装 uv 和 Python 3.13

```bash
# 安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 添加到 PATH（永久）
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 验证 uv 安装
which uv
uv --version

# 安装 Python 3.13
uv python install 3.13
```

**⚠️ 如果遇到 `command not found: uv`**：
- 查看 [故障排查指南](TROUBLESHOOTING.md)

### 2. 安装依赖

```bash
cd backend-fastapi
uv sync
```

### 3. 运行项目

```bash
# 设置数据库连接
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"

# 运行应用
uv run uvicorn app.main:app --reload
```

### 4. 运行测试

```bash
uv run pytest -v
```

## 📚 文档

- [快速开始指南](QUICKSTART.md) - 详细的使用说明
- [uv 迁移指南](UV_MIGRATION_GUIDE.md) - 从 pip 迁移到 uv
- [为什么使用虚拟环境](WHY_VIRTUAL_ENV.md) - 虚拟环境的重要性
- [代码审核报告](CODE_REVIEW.md) - 代码质量审核

## 🏗️ 项目结构

```
backend-fastapi/
├── app/                    # 应用代码
│   ├── __init__.py
│   ├── main.py            # FastAPI 应用入口
│   ├── models.py          # 数据库模型
│   └── routes.py          # API 路由
├── tests/                 # 测试代码
│   ├── test_health.py     # 健康检查测试
│   └── n8n_test.py        # N8N 测试脚本
├── pyproject.toml         # 项目配置（uv）
├── uv.lock                # 依赖锁定文件
├── requirements.txt       # ⚠️ 已弃用（保留参考）
├── Dockerfile             # Docker 构建文件
├── start.sh               # 启动脚本
└── seed_db.py             # 数据库种子数据
```

## 🔧 环境变量

- `DATABASE_URL` - 数据库连接字符串
  - 默认：`postgresql+psycopg://postgres:postgres@localhost:5434/blog`
  - Docker：`postgresql+psycopg://demo:demo@postgres:5432/demo`
- `N8N_WEBHOOK_URL` - N8N Webhook URL（可选）

## 📖 更多信息

查看项目根目录的 [README.md](../README.md) 和 [PROJECT_GUIDE.md](../PROJECT_GUIDE.md)

