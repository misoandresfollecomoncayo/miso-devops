# ============================================
# Valores específicos - Paso 4 ECS
# ============================================

aws_region   = "us-east-1"
project_name = "python-app"
environment  = "dev"

# Networking (valores del paso 3)
vpc_id = "vpc-03c5511735044c4ba"
subnet_ids = ["subnet-0b8b956318668c8ee", "subnet-05fdc8410fdc2d81e"]
ecs_tasks_security_group_id = "sg-07de55655900433ee"

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

# Base de datos (será actualizado por deploy-all.sh)
db_host     = "python-app-dev-db.cw54gouccfhu.us-east-1.rds.amazonaws.com"
db_user     = "postgres"
db_password = "postgres123"
db_name     = "miso_devops_blacklists"
db_port     = 5432

# Servicio ECS
desired_count = 1
