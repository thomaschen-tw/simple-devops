#!/bin/bash
# 一键部署脚本（已整合到 Makefile，建议使用 make prod-deploy）
# 使用方法: ./deploy.sh [你的GitHub用户名] [你的仓库名]
# 或者: 在 .env 文件中设置 GITHUB_USERNAME 和 GITHUB_REPO，然后运行 make prod-deploy

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 加载 .env 文件（如果存在）
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 检查参数或环境变量
if [ -z "$1" ] || [ -z "$2" ]; then
    if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_REPO" ]; then
        echo -e "${RED}❌ 错误: 请提供 GitHub 用户名和仓库名${NC}"
        echo "使用方法:"
        echo "  1. ./deploy.sh <GitHub用户名> <仓库名>"
        echo "  2. 或在 .env 文件中设置 GITHUB_USERNAME 和 GITHUB_REPO，然后运行: make prod-deploy"
        echo ""
        echo "例如: ./deploy.sh xiaotongchen simple-devops"
        exit 1
    else
        GITHUB_USER=$GITHUB_USERNAME
        REPO_NAME=$GITHUB_REPO
    fi
else
    GITHUB_USER=$1
    REPO_NAME=$2
fi

REGISTRY="ghcr.io"
BACKEND_IMAGE="${REGISTRY}/${GITHUB_USER}/${REPO_NAME}/backend:latest"
FRONTEND_IMAGE="${REGISTRY}/${GITHUB_USER}/${REPO_NAME}/frontend:latest"

echo -e "${GREEN}🚀 开始部署博客应用...${NC}"
echo "GitHub 用户: ${GITHUB_USER}"
echo "仓库名: ${REPO_NAME}"
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
    exit 1
fi

# 检查是否已登录 GHCR（可选，如果镜像是公开的则不需要）
echo -e "${YELLOW}ℹ️  检查镜像访问权限...${NC}"
echo "如果镜像未公开，请先登录 GHCR:"
echo "  echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
echo ""

# 拉取最新镜像
echo -e "${GREEN}📥 拉取最新镜像...${NC}"
docker pull ${BACKEND_IMAGE} || {
    echo -e "${RED}❌ 无法拉取后端镜像: ${BACKEND_IMAGE}${NC}"
    echo "请确保:"
    echo "  1. GitHub Actions 已成功构建镜像"
    echo "  2. 镜像名称正确"
    echo "  3. 已登录 GHCR（如果镜像是私有的）"
    exit 1
}

docker pull ${FRONTEND_IMAGE} || {
    echo -e "${RED}❌ 无法拉取前端镜像: ${FRONTEND_IMAGE}${NC}"
    exit 1
}

echo -e "${GREEN}✅ 镜像拉取完成${NC}"
echo ""

# 停止旧容器（如果存在）
echo -e "${YELLOW}🛑 停止旧容器...${NC}"
BACKEND_IMAGE=${BACKEND_IMAGE} FRONTEND_IMAGE=${FRONTEND_IMAGE} \
    docker compose -f docker-compose.prod.yml down 2>/dev/null || true

# 启动服务
echo -e "${GREEN}🚀 启动服务...${NC}"
BACKEND_IMAGE=${BACKEND_IMAGE} FRONTEND_IMAGE=${FRONTEND_IMAGE} \
    docker compose -f docker-compose.prod.yml up -d

# 等待服务就绪
echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
sleep 5

# 检查服务状态
echo -e "${GREEN}📊 服务状态:${NC}"
docker compose -f docker-compose.prod.yml ps

echo ""
echo -e "${GREEN}✅ 部署完成！${NC}"
echo ""
echo "访问地址:"
echo "  🌐 前端: http://localhost:5173"
echo "  🔧 后端 API: http://localhost:8000"
echo "  📖 API 文档: http://localhost:8000/docs"
echo "  ❤️  健康检查: http://localhost:8000/healthz"
echo ""
echo "管理命令:"
echo "  查看日志: docker compose -f docker-compose.prod.yml logs -f"
echo "  停止服务: docker compose -f docker-compose.prod.yml down"
echo "  重启服务: docker compose -f docker-compose.prod.yml restart"
echo ""
echo -e "${YELLOW}💡 提示: 建议使用 Makefile 管理服务: make prod-up, make prod-down, make logs$(NC)"
echo ""

