/**
 * Terraform 输出
 * 输出部署后的重要信息
 */

output "alb_dns_name" {
  description = "Application Load Balancer DNS 名称"
  value       = aws_lb.main.dns_name
}

output "frontend_url" {
  description = "前端访问地址"
  value       = "http://${aws_lb.main.dns_name}"
}

output "backend_url" {
  description = "后端 API 访问地址"
  value       = "http://${aws_lb.main.dns_name}:8000"
}

output "backend_api_docs" {
  description = "后端 API 文档地址"
  value       = "http://${aws_lb.main.dns_name}:8000/docs"
}

output "rds_endpoint" {
  description = "RDS 数据库端点（仅内部访问）"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS 数据库地址"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS 集群名称"
  value       = aws_ecs_cluster.main.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "cloudwatch_log_groups" {
  description = "CloudWatch 日志组"
  value = {
    backend  = aws_cloudwatch_log_group.backend.name
    frontend = aws_cloudwatch_log_group.frontend.name
  }
}

output "ecr_backend_repository" {
  description = "后端 ECR 仓库 URI"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repository" {
  description = "前端 ECR 仓库 URI"
  value       = aws_ecr_repository.frontend.repository_url
}

