output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "rds_endpoint" {
  description = "RDS endpoint (without port)"
  value       = module.rds.endpoint
  sensitive   = true
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.dns_name
}

output "frontend_url" {
  description = "Frontend URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${module.alb.dns_name}"
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}/api" : "http://${module.alb.dns_name}/api"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = module.ecs_backend.service_name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = module.ecs_frontend.service_name
}

