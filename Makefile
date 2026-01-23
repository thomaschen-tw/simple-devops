# ============================================
# Makefile for Simple DevOps Project
# ============================================
# 统一管理项目开发、部署、测试等常用命令
# 使用方法: make <target>
# 查看所有命令: make help
# ============================================

.PHONY: help install dev build up down restart logs clean test deploy prod-deploy

# 默认目标
.DEFAULT_GOAL := help

# 颜色定义
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# 检查 .env 文件是否存在
ENV_FILE := .env
ifeq ($(wildcard $(ENV_FILE)),)
    $(warning $(YELLOW)⚠️  .env 文件不存在，请先运行: cp .env.example .env$(NC))
endif

# 加载环境变量（如果 .env 文件存在）
ifneq ($(wildcard $(ENV_FILE)),)
    include $(ENV_FILE)
    export
endif

# ============================================
# 帮助信息
# ============================================
help: ## 显示此帮助信息
	@echo "$(GREEN)Simple DevOps Project - Makefile 命令列表$(NC)"
	@echo ""
	@echo "$(YELLOW)环境配置:$(NC)"
	@echo "  make install        - 初始化项目（复制 .env.example 为 .env）"
	@echo "  make check-env      - 检查环境变量配置"
	@echo ""
	@echo "$(YELLOW)开发环境:$(NC)"
	@echo "  make dev            - 启动开发环境（docker-compose up）"
	@echo "  make dev-backend    - 仅启动后端服务（开发模式）"
	@echo "  make dev-frontend   - 仅启动前端服务（开发模式）"
	@echo ""
	@echo "$(YELLOW)Docker 管理:$(NC)"
	@echo "  make build          - 构建 Docker 镜像"
	@echo "  make up             - 启动所有服务（后台运行）"
	@echo "  make down           - 停止所有服务"
	@echo "  make restart        - 重启所有服务"
	@echo "  make logs           - 查看所有服务日志"
	@echo "  make logs-backend   - 查看后端日志"
	@echo "  make logs-frontend  - 查看前端日志"
	@echo "  make logs-db        - 查看数据库日志"
	@echo "  make ps             - 查看服务状态"
	@echo ""
	@echo "$(YELLOW)数据库管理:$(NC)"
	@echo "  make db-shell       - 进入 PostgreSQL 命令行"
	@echo "  make db-reset       - 重置数据库（删除并重新创建）"
	@echo "  make db-seed        - 填充测试数据"
	@echo ""
	@echo "$(YELLOW)测试:$(NC)"
	@echo "  make test           - 运行所有测试"
	@echo "  make test-backend   - 运行后端测试"
	@echo ""
	@echo "$(YELLOW)生产部署:$(NC)"
	@echo "  make prod-deploy    - 生产环境部署（使用 GHCR 镜像）"
	@echo "  make prod-pull      - 拉取最新生产镜像"
	@echo "  make prod-up        - 启动生产环境服务"
	@echo "  make prod-down      - 停止生产环境服务"
	@echo ""
	@echo "$(YELLOW)清理:$(NC)"
	@echo "  make clean          - 清理 Docker 资源（容器、镜像、卷）"
	@echo "  make clean-all      - 清理所有资源（包括数据卷）"
	@echo ""

# ============================================
# 环境配置
# ============================================
install: ## 初始化项目环境
	@if [ ! -f .env ]; then \
		echo "$(GREEN)📋 创建 .env 文件...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)✅ .env 文件已创建，请编辑 .env 文件配置环境变量$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  .env 文件已存在，跳过创建$(NC)"; \
	fi

check-env: ## 检查环境变量配置
	@echo "$(GREEN)🔍 检查环境变量配置...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)❌ .env 文件不存在，请运行: make install$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ .env 文件存在$(NC)"
	@echo ""
	@echo "$(YELLOW)关键环境变量:$(NC)"
	@echo "  DATABASE_URL: $${DATABASE_URL:-未设置}"
	@echo "  POSTGRES_USER: $${POSTGRES_USER:-未设置}"
	@echo "  POSTGRES_PASSWORD: $${POSTGRES_PASSWORD:-未设置}"
	@echo "  N8N_WEBHOOK_URL: $${N8N_WEBHOOK_URL:-未设置}"
	@echo "  VITE_API_BASE_URL: $${VITE_API_BASE_URL:-未设置}"
	@echo "  GITHUB_USERNAME: $${GITHUB_USERNAME:-未设置}"
	@echo "  GITHUB_REPO: $${GITHUB_REPO:-未设置}"

# ============================================
# 开发环境
# ============================================
dev: ## 启动开发环境
	@echo "$(GREEN)🚀 启动开发环境...$(NC)"
	docker-compose up

dev-backend: ## 仅启动后端服务（开发模式）
	@echo "$(GREEN)🚀 启动后端服务...$(NC)"
	cd backend-fastapi && python3 -m uvicorn app.main:app --reload --port 8000

dev-frontend: ## 仅启动前端服务（开发模式）
	@echo "$(GREEN)🚀 启动前端服务...$(NC)"
	cd frontend-react && npm run dev

# ============================================
# Docker 管理
# ============================================
build: ## 构建 Docker 镜像
	@echo "$(GREEN)🔨 构建 Docker 镜像...$(NC)"
	docker-compose build

up: ## 启动所有服务（后台运行）
	@echo "$(GREEN)🚀 启动所有服务...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ 服务已启动$(NC)"
	@echo ""
	@echo "$(YELLOW)访问地址:$(NC)"
	@echo "  🌐 前端: http://localhost:5173"
	@echo "  🔧 后端 API: http://localhost:8000"
	@echo "  📖 API 文档: http://localhost:8000/docs"
	@echo "  ❤️  健康检查: http://localhost:8000/healthz"

down: ## 停止所有服务
	@echo "$(YELLOW)🛑 停止所有服务...$(NC)"
	docker-compose down

restart: ## 重启所有服务
	@echo "$(YELLOW)🔄 重启所有服务...$(NC)"
	docker-compose restart

logs: ## 查看所有服务日志
	docker-compose logs -f

logs-backend: ## 查看后端日志
	docker-compose logs -f backend

logs-frontend: ## 查看前端日志
	docker-compose logs -f frontend

logs-db: ## 查看数据库日志
	docker-compose logs -f postgres

ps: ## 查看服务状态
	docker-compose ps

# ============================================
# 数据库管理
# ============================================
db-shell: ## 进入 PostgreSQL 命令行
	@echo "$(GREEN)📊 连接到 PostgreSQL...$(NC)"
	docker-compose exec postgres psql -U $${POSTGRES_USER:-demo} -d $${POSTGRES_DB:-demo}

db-reset: ## 重置数据库（删除并重新创建）
	@echo "$(RED)⚠️  警告: 这将删除所有数据库数据！$(NC)"
	@read -p "确认继续? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)🗑️  删除数据库卷...$(NC)"; \
		docker-compose down -v; \
		echo "$(GREEN)✅ 数据库已重置$(NC)"; \
	fi

db-seed: ## 填充测试数据
	@echo "$(GREEN)📦 填充测试数据...$(NC)"
	docker-compose exec backend python seed_db.py

# ============================================
# 测试
# ============================================
test: test-backend ## 运行所有测试

test-backend: ## 运行后端测试
	@echo "$(GREEN)🧪 运行后端测试...$(NC)"
	cd backend-fastapi && python -m pytest tests/ -v

# ============================================
# 生产部署
# ============================================
prod-deploy: ## 生产环境部署（使用 GHCR 镜像）
	@if [ -z "$$GITHUB_USERNAME" ] || [ -z "$$GITHUB_REPO" ]; then \
		echo "$(RED)❌ 错误: 请先设置 GITHUB_USERNAME 和 GITHUB_REPO 环境变量$(NC)"; \
		echo "  编辑 .env 文件或运行: export GITHUB_USERNAME=your_username GITHUB_REPO=your_repo"; \
		exit 1; \
	fi
	@echo "$(GREEN)🚀 开始生产环境部署...$(NC)"
	@echo "GitHub 用户: $$GITHUB_USERNAME"
	@echo "仓库名: $$GITHUB_REPO"
	@echo ""
	@if [ ! -z "$$GITHUB_TOKEN" ]; then \
		echo "$(YELLOW)🔐 登录 GHCR...$(NC)"; \
		echo $$GITHUB_TOKEN | docker login ghcr.io -u $$GITHUB_USERNAME --password-stdin; \
	fi
	@echo "$(GREEN)📥 拉取最新镜像...$(NC)"
	@docker pull ghcr.io/$$GITHUB_USERNAME/$$GITHUB_REPO/backend:latest || \
		(echo "$(RED)❌ 无法拉取后端镜像$(NC)" && exit 1)
	@docker pull ghcr.io/$$GITHUB_USERNAME/$$GITHUB_REPO/frontend:latest || \
		(echo "$(RED)❌ 无法拉取前端镜像$(NC)" && exit 1)
	@echo "$(GREEN)✅ 镜像拉取完成$(NC)"
	@echo ""
	@echo "$(YELLOW)🛑 停止旧容器...$(NC)"
	@docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
	@echo "$(GREEN)🚀 启动服务...$(NC)"
	@BACKEND_IMAGE=ghcr.io/$$GITHUB_USERNAME/$$GITHUB_REPO/backend:latest \
	 FRONTEND_IMAGE=ghcr.io/$$GITHUB_USERNAME/$$GITHUB_REPO/frontend:latest \
	 docker-compose -f docker-compose.prod.yml up -d
	@echo "$(YELLOW)⏳ 等待服务启动...$(NC)"
	@sleep 5
	@echo "$(GREEN)📊 服务状态:$(NC)"
	@docker-compose -f docker-compose.prod.yml ps
	@echo ""
	@echo "$(GREEN)✅ 部署完成！$(NC)"
	@echo ""
	@echo "$(YELLOW)访问地址:$(NC)"
	@echo "  🌐 前端: http://localhost:5173"
	@echo "  🔧 后端 API: http://localhost:8000"
	@echo "  📖 API 文档: http://localhost:8000/docs"

prod-pull: ## 拉取最新生产镜像
	@if [ -z "$$GITHUB_USERNAME" ] || [ -z "$$GITHUB_REPO" ]; then \
		echo "$(RED)❌ 错误: 请先设置 GITHUB_USERNAME 和 GITHUB_REPO$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)📥 拉取最新生产镜像...$(NC)"
	@docker pull ghcr.io/$$GITHUB_USERNAME/$$GITHUB_REPO/backend:latest
	@docker pull ghcr.io/$$GITHUB_USERNAME/$$GITHUB_REPO/frontend:latest
	@echo "$(GREEN)✅ 镜像拉取完成$(NC)"

prod-up: ## 启动生产环境服务
	@echo "$(GREEN)🚀 启动生产环境服务...$(NC)"
	@docker-compose -f docker-compose.prod.yml up -d

prod-down: ## 停止生产环境服务
	@echo "$(YELLOW)🛑 停止生产环境服务...$(NC)"
	@docker-compose -f docker-compose.prod.yml down

# ============================================
# 清理
# ============================================
clean: ## 清理 Docker 资源（容器、镜像、卷）
	@echo "$(YELLOW)🧹 清理 Docker 资源...$(NC)"
	@docker-compose down
	@docker system prune -f
	@echo "$(GREEN)✅ 清理完成$(NC)"

clean-all: ## 清理所有资源（包括数据卷）
	@echo "$(RED)⚠️  警告: 这将删除所有数据卷（包括数据库数据）！$(NC)"
	@read -p "确认继续? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)🧹 清理所有资源...$(NC)"; \
		docker-compose down -v; \
		docker system prune -af --volumes; \
		echo "$(GREEN)✅ 清理完成$(NC)"; \
	fi
