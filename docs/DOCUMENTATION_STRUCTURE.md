# 项目文档结构说明

> **📝 最后更新**: 2026-01-30

## 📁 文档组织原则

1. **根目录**: 项目主 README
2. **docs/**: 所有详细技术文档和指南
3. **docs/archive/**: 历史工作日志和项目演进记录
4. **backend-fastapi/**: 后端代码和相关技术文档

## 📚 当前文档结构

### 根目录
- **README.md** - 项目主文档，快速开始指南

### docs/ 目录（活跃文档）

#### 部署和运维
- **DEPLOYMENT.md** - 完整部署指南（本地开发 + 生产环境）
- **MAKEFILE_GUIDE.md** - Makefile 命令快速参考
- **MAKEFILE_LEARNING_GUIDE.md** - Makefile 设计和学习教程

#### 项目说明
- **PROJECT_GUIDE.md** - 项目架构和设计指南
- **FILE_ORGANIZATION.md** - 文件整理分析报告
- **DOCUMENTATION_STRUCTURE.md** - 本文档

#### 功能说明
- **N8N_FEEDBACK_FEATURE.md** - N8N 自动化反馈功能
- **MULTI_PLATFORM_BUILD.md** - Docker 多平台构建
- **SEARCH_SORT_EXPLANATION.md** - 搜索排序功能

#### 技术文档
- **PYTHON_VERSION_CLARIFICATION.md** - Python 3.13 使用说明
- **DOCKER_COMPOSE_COMPARISON.md** - docker-compose 文件对比
- **GIT_UPLOAD_GUIDE.md** - Git 使用指南

#### 配置文件
- **n8n-workflow.json** - N8N 工作流配置

### docs/archive/ 目录（历史文档）

- **README.md** - 归档文档说明
- **CLEANUP_SUMMARY.md** - k8s/terraform 清理总结
- **REORGANIZATION_SUMMARY.md** - 项目整理总结
- **work-logs/** - 每日工作日志（day1-8, week1-2）

### backend-fastapi/ 目录

#### 入口文档
- **README.md** - 后端项目概览
- **DOCS_INDEX.md** - 后端文档索引

#### 快速开始
- **QUICKSTART.md** - 快速开始指南（uv + Python 3.13）

#### 技术指南
- **UV_MIGRATION_GUIDE.md** - uv 迁移指南
- **ROUTING_GUIDE.md** - FastAPI 路由设计
- **CODE_REVIEW.md** - 代码审核报告
- **TROUBLESHOOTING.md** - 故障排查指南

## 🎯 按需求查找文档

| 需求 | 推荐文档 |
|------|---------|
| **快速部署项目** | [DEPLOYMENT.md](./DEPLOYMENT.md) |
| **了解 Makefile** | [MAKEFILE_GUIDE.md](./MAKEFILE_GUIDE.md) |
| **学习 Makefile 设计** | [MAKEFILE_LEARNING_GUIDE.md](./MAKEFILE_LEARNING_GUIDE.md) |
| **理解项目架构** | [PROJECT_GUIDE.md](./PROJECT_GUIDE.md) |
| **Python 3.13 说明** | [PYTHON_VERSION_CLARIFICATION.md](./PYTHON_VERSION_CLARIFICATION.md) |
| **后端快速开始** | [../backend-fastapi/QUICKSTART.md](../backend-fastapi/QUICKSTART.md) |
| **uv 迁移指南** | [../backend-fastapi/UV_MIGRATION_GUIDE.md](../backend-fastapi/UV_MIGRATION_GUIDE.md) |
| **查看开发历史** | [archive/work-logs/](./archive/work-logs/) |

## 📊 文档维护

### 文档组织优势
- ✅ **简洁的根目录**: 只保留主 README
- ✅ **集中的文档管理**: 所有文档在 docs/ 目录
- ✅ **清晰的归档**: 历史文档独立存放
- ✅ **完善的索引**: README 提供快速导航

### 文档维护原则
1. **保持更新**: 新功能添加时同步更新文档
2. **归档历史**: 过时文档移至 archive/
3. **交叉引用**: 文档间提供清晰的链接
4. **统一格式**: 遵循一致的 Markdown 格式

## 📝 更新记录

- **2026-01-30**: 优化文档结构，归档历史日志，添加快速导航
- **2025-12-26**: 统一 Python 版本说明（3.13），整理文档结构

