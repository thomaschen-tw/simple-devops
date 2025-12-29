# 本地变量定义
# 用于统一管理资源命名和常用值

locals {
  # 资源名称前缀
  name_prefix = "${var.project_name}-${var.environment}"

  # 可用区列表（根据 AWS 区域自动获取或使用配置的值）
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names

  # Docker 镜像地址
  backend_image  = "ghcr.io/${var.github_username}/${var.github_repo}/backend:latest"
  frontend_image = "ghcr.io/${var.github_username}/${var.github_repo}/frontend:latest"
}

