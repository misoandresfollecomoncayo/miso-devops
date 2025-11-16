# ============================================
# Valores específicos de TU proyecto - Paso 2 ECR
# ============================================
# ⚠️ IMPORTANTE: NO subas este archivo a git si contiene datos sensibles

# Región de AWS donde desplegarás
aws_region = "us-east-1"

# Nombre de tu proyecto (sin espacios, solo guiones)
project_name = "python-app"

# Ambiente (dev para desarrollo, prod para producción)
environment = "dev"

# Configuración del repositorio ECR
image_tag_mutability = "MUTABLE"
scan_on_push         = true
max_image_count      = 10

# Acceso entre cuentas (dejar false si no es necesario)
allow_cross_account_access = false
allowed_account_ids        = []
