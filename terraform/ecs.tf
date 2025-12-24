/**
 * ECS 配置
 * 创建 ECS Cluster、Task Definitions 和 Services
 */

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

# CloudWatch Log Group for Backend
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}/backend"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-backend-logs"
  }
}

# CloudWatch Log Group for Frontend
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name_prefix}/frontend"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-frontend-logs"
  }
}

# IAM Role for ECS Task Execution（拉取镜像、写入日志）
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task（应用运行时权限）
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 注意：如果使用 GHCR 私有镜像，需要配置认证
# 但 ECS 原生不支持 GHCR 认证，推荐使用 ECR（见 ecr-sync.tf）
# 如果使用 ECR，以下代码可以删除

# Secrets Manager Secret for GitHub Token（仅在使用 GHCR 私有镜像时需要）
# resource "aws_secretsmanager_secret" "github_token" {
#   name        = "${local.name_prefix}/github-token"
#   description = "GitHub Personal Access Token for pulling GHCR images"
#
#   tags = {
#     Name = "${local.name_prefix}-github-token"
#   }
# }
#
# resource "aws_secretsmanager_secret_version" "github_token" {
#   secret_id     = aws_secretsmanager_secret.github_token.id
#   secret_string = var.github_token
# }
#
# resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
#   name = "${local.name_prefix}-ecs-task-execution-secrets"
#   role = aws_iam_role.ecs_task_execution.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = [
#           aws_secretsmanager_secret.github_token.arn
#         ]
#       }
#     ]
#   })
# }

# Backend Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = local.backend_image

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}:5432/${var.db_name}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import http.client; conn = http.client.HTTPConnection('localhost', 8000); conn.request('GET', '/healthz'); r = conn.getresponse(); exit(0 if r.status == 200 else 1)\""]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 40
      }

      # 如果使用 ECR，ECS 会自动使用任务执行角色的权限拉取镜像
      # 如果使用 GHCR 公开镜像，无需额外配置
    }
  ])

  tags = {
    Name = "${local.name_prefix}-backend-task"
  }
}

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name_prefix}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "frontend"
      image = local.frontend_image

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      # 前端使用相对路径访问后端 API（通过 ALB 路径路由）
      # 无需设置 VITE_API_BASE_URL，前端代码会使用相对路径

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-frontend-task"
  }
}

# Backend ECS Service
resource "aws_ecs_service" "backend" {
  name            = "${local.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.backend,
    aws_db_instance.main
  ]

  tags = {
    Name = "${local.name_prefix}-backend-service"
  }
}

# Frontend ECS Service
resource "aws_ecs_service" "frontend" {
  name            = "${local.name_prefix}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.frontend
  ]

  tags = {
    Name = "${local.name_prefix}-frontend-service"
  }
}

