# Backend FastAPI 文档索引

## 📚 文档导航

### 🚀 快速开始
- [README.md](README.md) - 项目概览和快速开始
- [QUICKSTART.md](QUICKSTART.md) - 详细的快速开始指南（uv + Python 3.13）

### 📖 迁移和配置
- [UV_MIGRATION_GUIDE.md](UV_MIGRATION_GUIDE.md) - 从 pip 迁移到 uv 的完整指南
- [WHY_VIRTUAL_ENV.md](WHY_VIRTUAL_ENV.md) - 为什么使用虚拟环境（重要！）

### 🔍 代码质量
- [CODE_REVIEW.md](CODE_REVIEW.md) - 代码审核报告（Python 3.13 + uv）

### 📝 技术文档
- [ROUTING_GUIDE.md](ROUTING_GUIDE.md) - FastAPI 路由设计指南

## 🎯 按主题查找

### 新手入门
1. 阅读 [README.md](README.md) 了解项目
2. 按照 [QUICKSTART.md](QUICKSTART.md) 开始开发

### 迁移到 uv
1. 阅读 [UV_MIGRATION_GUIDE.md](UV_MIGRATION_GUIDE.md)
2. 按照步骤执行迁移
3. 查看 [CODE_REVIEW.md](CODE_REVIEW.md) 了解审核结果

### 理解架构
1. 查看项目根目录的 [PROJECT_GUIDE.md](../PROJECT_GUIDE.md)
2. 阅读 [ROUTING_GUIDE.md](ROUTING_GUIDE.md) 了解路由设计

## ⚠️ 重要说明

### Python 版本
- **项目要求**：Python 3.13
- **配置位置**：`pyproject.toml` → `requires-python = ">=3.13"`
- **注意**：某些工具可能推荐 3.12.9，但本项目使用 3.13

### 包管理器
- **当前使用**：uv（`pyproject.toml` + `uv.lock`）
- **已弃用**：pip + `requirements.txt`（保留仅作参考）

### 虚拟环境
- **位置**：`.venv/`（项目根目录）
- **管理**：uv 自动管理，无需手动创建
- **使用**：`uv run <command>` 自动使用虚拟环境

## 📊 文档更新日期

- 2025-12-26：迁移到 uv，统一 Python 3.13

