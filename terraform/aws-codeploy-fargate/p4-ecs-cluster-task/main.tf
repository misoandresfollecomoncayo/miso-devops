# ECS Cluster, Task Definition y Service
# Configuración de contenedores y servicios para despliegue en Fargate

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Step        = "4-ECS-Cluster-Task"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data Sources - Leer outputs de otros módulos Terraform
data "terraform_remote_state" "networking" {
  backend = "local"
  
  config = {
    path = "../p3-alb-target-groups/terraform.tfstate"
  }
}

data "terraform_remote_state" "rds" {
  backend = "local"
  
  config = {
    path = "../p3-rds-postgres/terraform.tfstate"
  }
}

# Variables locales derivadas de remote state
locals {
  # Networking desde p3-alb-target-groups
  vpc_id                       = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids                   = data.terraform_remote_state.networking.outputs.public_subnet_ids
  ecs_tasks_security_group_id  = data.terraform_remote_state.networking.outputs.ecs_tasks_security_group_id
  
  # Database desde p3-rds-postgres
  db_host = data.terraform_remote_state.rds.outputs.db_host
  
  # Target Groups desde p3-alb-target-groups
  blue_target_group_name  = data.terraform_remote_state.networking.outputs.blue_target_group_name
  green_target_group_name = data.terraform_remote_state.networking.outputs.green_target_group_name
  alb_name                = data.terraform_remote_state.networking.outputs.alb_summary.alb.name
}

# 4. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# 5. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-logs"
  }
}

# 6. IAM Role para ECS Task Execution
# Este rol permite a ECS descargar imágenes de ECR y escribir logs
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  }
}

# Política gestionada para ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 7. IAM Role para ECS Task (Runtime)
# Este rol es el que usa la aplicación en runtime
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# Política personalizada para acceso a recursos AWS (si es necesario)
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project_name}-${var.environment}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.app.arn}:*"
      }
    ]
  })
}

# 8. Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_USER"
          value = var.db_user
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_HOST"
          value = local.db_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "NEW_RELIC_LICENSE_KEY"
          value = var.new_relic_license_key
        },
        {
          name  = "NEW_RELIC_APP_NAME"
          value = var.new_relic_app_name
        },
        {
          name  = "NEW_RELIC_MONITOR_MODE"
          value = tostring(var.new_relic_enabled)
        },
        {
          name  = "NEW_RELIC_DISTRIBUTED_TRACING_ENABLED"
          value = "true"
        },
        {
          name  = "NEW_RELIC_LOG"
          value = "stdout"
        },
        {
          name  = "NEW_RELIC_LOG_LEVEL"
          value = "info"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ping || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-task"
  }
}

# 9. Data Sources - Target Groups
# Data sources para Target Groups usando remote state
data "aws_lb_target_group" "blue" {
  name = local.blue_target_group_name
}

data "aws_lb_target_group" "green" {
  name = local.green_target_group_name
}

data "aws_lb" "main" {
  name = local.alb_name
}

# 10. Servicio ECS
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [local.ecs_tasks_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = data.aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # Ignorar cambios en task_definition y desired_count
  # porque CodeDeploy los manejará
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer
    ]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-service"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy
  ]
}

# 11. CodeDeploy Application
resource "aws_codedeploy_app" "app" {
  name             = "${var.project_name}-${var.environment}-app"
  compute_platform = "ECS"

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-app"
  }
}

# Data sources para CodeDeploy
data "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-${var.environment}-codedeploy-role"
}

data "aws_lb_listener" "production" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 80
}

data "aws_lb_listener" "test" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 8080
}

# 12. CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.project_name}-${var.environment}-dg"
  service_role_arn       = data.aws_iam_role.codedeploy.arn
  deployment_config_name = var.deployment_config_name

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.app.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [data.aws_lb_listener.production.arn]
      }

      test_traffic_route {
        listener_arns = [data.aws_lb_listener.test.arn]
      }

      target_group {
        name = data.aws_lb_target_group.blue.name
      }

      target_group {
        name = data.aws_lb_target_group.green.name
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-deployment-group"
  }

  depends_on = [
    aws_ecs_service.app
  ]
}
