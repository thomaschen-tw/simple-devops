# ============================================================================
# 输出定义
# ============================================================================

# VPC 输出
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# ALB 输出
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

# RDS 输出
output "rds_endpoint" {
  description = "RDS endpoint (hostname only)"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

# ECS 输出
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}

# 应用访问地址
output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "http://${aws_lb.main.dns_name}/api"
}

output "backend_health_check_url" {
  description = "Backend health check URL"
  value       = "http://${aws_lb.main.dns_name}/healthz"
}
