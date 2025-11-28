# Variables de entrada para el Paso 4 - ECS

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "python-app"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

# Variables de ECS Cluster
variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 7
}

# Variables de Task Definition
variable "task_cpu" {
  description = "CPU para la task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memoria para la task en MB"
  type        = string
  default     = "512"
}

variable "container_name" {
  description = "Nombre del contenedor"
  type        = string
  default     = "python-app"
}

variable "container_port" {
  description = "Puerto del contenedor"
  type        = number
  default     = 5000
}

variable "ecr_repository_url" {
  description = "URL del repositorio ECR"
  type        = string
}

variable "image_tag" {
  description = "Tag de la imagen Docker"
  type        = string
  default     = "latest"
}

# Variables de Base de Datos
variable "db_user" {
  description = "Usuario de la base de datos"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "dbdevops"
}

# Nota: db_host se obtiene dinámicamente desde p3-rds-postgres via terraform_remote_state

variable "db_port" {
  description = "Puerto de la base de datos"
  type        = number
  default     = 5432
}

# Nota: vpc_id, subnet_ids, ecs_tasks_security_group_id se obtienen dinámicamente
# desde p3-alb-target-groups via terraform_remote_state

# Variables de ECS Service
variable "desired_count" {
  description = "Número de tareas deseadas en el servicio"
  type        = number
  default     = 1
}

# Variables de CodeDeploy
variable "deployment_config_name" {
  description = "Configuración de despliegue de CodeDeploy"
  type        = string
  default     = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
  # Opciones disponibles:
  # - CodeDeployDefault.ECSAllAtOnce (0 -> 100% inmediato)
  # - CodeDeployDefault.ECSLinear10PercentEvery1Minutes (10% cada minuto)
  # - CodeDeployDefault.ECSLinear10PercentEvery3Minutes (10% cada 3 minutos)
  # - CodeDeployDefault.ECSCanary10Percent5Minutes (10%, espera 5 min, luego 90%)
  # - CodeDeployDefault.ECSCanary10Percent15Minutes (10%, espera 15 min, luego 90%)
}
