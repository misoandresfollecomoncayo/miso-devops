# Outputs del Paso 4 - ECS Cluster y Task

# Outputs: ECS Cluster
output "cluster_id" {
  description = "ID del ECS Cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN del ECS Cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Nombre del ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

# Outputs: Task Definition
output "task_definition_arn" {
  description = "ARN de la Task Definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Familia de la Task Definition"
  value       = aws_ecs_task_definition.app.family
}

output "task_definition_revision" {
  description = "Revisión de la Task Definition"
  value       = aws_ecs_task_definition.app.revision
}

# Outputs: IAM Roles
output "task_execution_role_arn" {
  description = "ARN del rol de ejecución de la task"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN del rol de la task (runtime)"
  value       = aws_iam_role.ecs_task.arn
}

# Output: CloudWatch Log Group
output "log_group_name" {
  description = "Nombre del Log Group en CloudWatch"
  value       = aws_cloudwatch_log_group.app.name
}

output "log_group_arn" {
  description = "ARN del Log Group"
  value       = aws_cloudwatch_log_group.app.arn
}

# Outputs: Servicio ECS
output "service_id" {
  description = "ID del servicio ECS"
  value       = aws_ecs_service.app.id
}

output "service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}

# Output: Resumen
output "ecs_summary" {
  description = "Resumen completo del ECS Cluster y Task Definition"
  value = {
    cluster = {
      name = aws_ecs_cluster.main.name
      arn  = aws_ecs_cluster.main.arn
      id   = aws_ecs_cluster.main.id
    }
    task_definition = {
      family   = aws_ecs_task_definition.app.family
      arn      = aws_ecs_task_definition.app.arn
      revision = aws_ecs_task_definition.app.revision
      cpu      = var.task_cpu
      memory   = var.task_memory
    }
    container = {
      name  = var.container_name
      port  = var.container_port
      image = "${var.ecr_repository_url}:${var.image_tag}"
    }
    iam_roles = {
      execution_role = aws_iam_role.ecs_task_execution.arn
      task_role      = aws_iam_role.ecs_task.arn
    }
    logs = {
      group_name = aws_cloudwatch_log_group.app.name
      retention  = var.log_retention_days
    }
    service = {
      name          = aws_ecs_service.app.name
      desired_count = var.desired_count
      launch_type   = "FARGATE"
    }
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
  }
}

# Output: URL de AWS Console
output "console_url" {
  description = "URL para ver el cluster en AWS Console"
  value       = "https://console.aws.amazon.com/ecs/home?region=${data.aws_region.current.name}#/clusters/${aws_ecs_cluster.main.name}"
}
