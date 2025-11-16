# ============================================
# Valores específicos de TU proyecto - Paso 3 VPC, ALB y Target Groups
# ============================================

# Región de AWS donde desplegarás
aws_region = "us-east-1"

# Nombre de tu proyecto
project_name = "python-app"

# Ambiente
environment = "dev"

# VPC y Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]

# Puerto donde tu aplicación escucha
app_port = 5000

# Path para el health check
health_check_path = "/ping"

# Protección contra eliminación (false para desarrollo)
enable_deletion_protection = false
