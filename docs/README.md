# 📚 项目文档索引

本目录包含项目的详细文档和工作日志。

## 📖 主要文档

### 部署和运维
- [部署指南](./DEPLOYMENT.md) - 本地开发和生产环境完整部署说明
- [Makefile 使用指南](./MAKEFILE_GUIDE.md) - Makefile 命令详解和使用说明
- [Makefile 学习指南](./MAKEFILE_LEARNING_GUIDE.md) - Makefile 设计和使用教程（从基础到高级）

### 项目说明
- [项目指南](./PROJECT_GUIDE.md) - 项目架构、设计思路和核心文件详解
- [文件整理分析](./FILE_ORGANIZATION.md) - 文件整理和优化建议

### 功能说明
- [N8N 反馈功能](./N8N_FEEDBACK_FEATURE.md) - N8N 自动化反馈处理功能说明
- [多平台构建](./MULTI_PLATFORM_BUILD.md) - Docker 多平台构建说明
- [搜索排序说明](./SEARCH_SORT_EXPLANATION.md) - 搜索和排序功能说明

### 技术文档
- [Python 版本说明](./PYTHON_VERSION_CLARIFICATION.md) - Python 3.13 和 uv 使用说明
- [Docker Compose 对比](./DOCKER_COMPOSE_COMPARISON.md) - docker-compose.yml 和 docker-compose.prod.yml 对比
- [Git 上传指南](./GIT_UPLOAD_GUIDE.md) - Git 使用和上传说明
- [文档结构说明](./DOCUMENTATION_STRUCTURE.md) - 文档组织结构说明

### 项目历史
- [清理总结](./CLEANUP_SUMMARY.md) - k8s 和 terraform 清理工作总结

## 📝 工作日志

### 周总结
- [第1周总结](./week1.md) - Day 1-5 基础骨架与搜索功能
- [第2周总结](./week2.md) - Day 6-10 本地 K8s 与 CI/CD 初版

### 每日工作总结

#### 第1周
- [Day 1](./day1.md) - 仓库初始化与项目骨架搭建
- [Day 2](./day2.md) - 数据库 Schema 设计与种子数据
- [Day 3](./day3.md) - FastAPI 搜索接口实现与本地联调
- [Day 4](./day4.md) - React 前端搜索页面实现
- [Day 5](./day5.md) - 创建文章接口与前端页面完善

#### 第2周
- [Day 6](./day6.md) - Dockerfile 编写与多环境配置
- [Day 7](./day7.md) - GitHub Actions CI/CD 配置
- [Day 8](./day8.md) - CI 测试集成与 K8s 部署配置

## 🔍 快速查找

### 按主题查找

**部署相关**
- 快速部署: [部署指南](./DEPLOYMENT.md)
- Makefile: [Makefile 使用指南](./MAKEFILE_GUIDE.md)
- Docker: [Docker Compose 对比](./DOCKER_COMPOSE_COMPARISON.md)

**开发相关**
- 项目架构: [项目指南](./PROJECT_GUIDE.md)
- Python 环境: [Python 版本说明](./PYTHON_VERSION_CLARIFICATION.md)
- 功能说明: [N8N 反馈功能](./N8N_FEEDBACK_FEATURE.md)

**历史记录**
- 开发过程: [工作日志](./week1.md), [week2.md](./week2.md)
- 清理工作: [清理总结](./CLEANUP_SUMMARY.md)

## 💡 使用建议

1. **新成员入门**: 先阅读 [部署指南](./DEPLOYMENT.md) 和 [项目指南](./PROJECT_GUIDE.md)
2. **部署问题**: 查看 [部署指南](./DEPLOYMENT.md) 的故障排查部分
3. **了解历史**: 阅读工作日志了解项目演进过程
4. **学习参考**: 参考设计思路和最佳实践

## 📝 文档说明

这些文档记录了项目的：
- 技术选型的思考过程
- 设计决策的原因
- 遇到的问题和解决方案
- 学到的经验和最佳实践

希望这些文档能帮助团队成员更好地理解项目，也希望能为其他开发者提供参考。
