# Variables para RDS PostgreSQL

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
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Database Configuration

variable "postgres_version" {
  description = "Versión de PostgreSQL"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Tipo de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento en GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "miso_devops_blacklists"
}

variable "db_username" {
  description = "Usuario maestro de la base de datos"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Contraseña del usuario maestro"
  type        = string
  sensitive   = true
  default     = "postgres123"
}

# Network & Security

variable "vpc_id" {
  description = "ID de la VPC donde se creará RDS"
  type        = string
}

variable "ecs_tasks_security_group_id" {
  description = "ID del Security Group de ECS Tasks (para permitir conexiones)"
  type        = string
}

variable "publicly_accessible" {
  description = "Hacer la base de datos accesible públicamente"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Habilitar Multi-AZ para alta disponibilidad"
  type        = bool
  default     = false
}

# Backup & Maintenance

variable "backup_retention_period" {
  description = "Días de retención de backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Omitir snapshot final al eliminar"
  type        = bool
  default     = true
}
