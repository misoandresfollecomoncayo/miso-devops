# ============================================
# Valores específicos - Paso 4 ECS
# ============================================

aws_region   = "us-east-1"
project_name = "python-app"
environment  = "dev"

# Networking (obtenido automáticamente desde p3-alb-target-groups via terraform_remote_state)
# vpc_id, subnet_ids, ecs_tasks_security_group_id se obtienen dinámicamente

# CloudWatch Logs
log_retention_days = 7

# Task Definition - CPU y Memoria
task_cpu    = "256"  # 0.25 vCPU
task_memory = "512"  # 512 MB

# Contenedor
container_name = "python-app"
container_port = 5000

# Imagen Docker desde ECR
ecr_repository_url = "148342400171.dkr.ecr.us-east-1.amazonaws.com/python-app-dev"
image_tag          = "latest"

# Base de datos (db_host se obtiene automáticamente desde p3-rds-postgres via terraform_remote_state)
db_user     = "postgres"
db_password = "postgres123"
db_name     = "miso_devops_blacklists"
db_port     = 5432

# New Relic (configurar con tu license key)
new_relic_license_key = "c5742501abd3df11ae98b4b6ba90ecddFFFFNRAL"
new_relic_app_name = "Python Blacklists App - ECS Fargate"
new_relic_enabled = true

# Servicio ECS
desired_count = 1
