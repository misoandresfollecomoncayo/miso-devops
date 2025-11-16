# ============================================
# Outputs para RDS PostgreSQL
# ============================================

output "db_instance_id" {
  description = "ID de la instancia RDS"
  value       = aws_db_instance.postgres.id
}

output "db_endpoint" {
  description = "Endpoint completo de conexión (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "db_host" {
  description = "Host de la base de datos (sin puerto)"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "Puerto de la base de datos"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.postgres.db_name
}

output "db_username" {
  description = "Usuario de la base de datos"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "db_arn" {
  description = "ARN de la instancia RDS"
  value       = aws_db_instance.postgres.arn
}

output "db_security_group_id" {
  description = "ID del Security Group de RDS"
  value       = aws_security_group.rds.id
}

# ============================================
# Connection Info para ECS
# ============================================

output "connection_info" {
  description = "Información de conexión para usar en ECS Task Definition"
  value = {
    DB_HOST     = aws_db_instance.postgres.address
    DB_PORT     = tostring(aws_db_instance.postgres.port)
    DB_NAME     = aws_db_instance.postgres.db_name
    DB_USER     = aws_db_instance.postgres.username
    DB_PASSWORD = var.db_password
  }
  sensitive = true
}

# ============================================
# Console URL
# ============================================

output "console_url" {
  description = "URL para ver RDS en AWS Console"
  value       = "https://console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${aws_db_instance.postgres.identifier}"
}

# ============================================
# Resumen
# ============================================

output "rds_summary" {
  description = "Resumen completo de RDS PostgreSQL"
  value = {
    instance_id       = aws_db_instance.postgres.id
    endpoint         = aws_db_instance.postgres.endpoint
    host             = aws_db_instance.postgres.address
    port             = aws_db_instance.postgres.port
    database_name    = aws_db_instance.postgres.db_name
    engine           = "${aws_db_instance.postgres.engine} ${aws_db_instance.postgres.engine_version}"
    instance_class   = aws_db_instance.postgres.instance_class
    storage          = "${aws_db_instance.postgres.allocated_storage} GB"
    multi_az         = aws_db_instance.postgres.multi_az
    publicly_accessible = aws_db_instance.postgres.publicly_accessible
    region           = data.aws_region.current.name
    account_id       = data.aws_caller_identity.current.account_id
  }
}
