# Variables de entrada para el Paso 3 - VPC, ALB y Target Groups
# Este archivo SOLO define las variables
# Los VALORES se asignan en terraform.tfvars

# Variable: Región de AWS
variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "La región debe tener el formato: us-east-1, us-west-2, etc."
  }
}

# Variable: Nombre del proyecto
variable "project_name" {
  description = "Nombre del proyecto (se usa como prefijo en recursos)"
  type        = string
  default     = "python-app"
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "El nombre del proyecto debe tener entre 1 y 20 caracteres."
  }
}

# Variable: Ambiente
variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser: dev, staging o prod."
  }
}

# Variable: CIDR de la VPC
variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un bloque CIDR válido."
  }
}

# Variable: CIDRs de subnets públicas
variable "public_subnet_cidrs" {
  description = "Lista de CIDR blocks para las subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Se requieren al menos 2 subnets públicas para alta disponibilidad del ALB."
  }
}

# Variable: Puerto de la aplicación
variable "app_port" {
  description = "Puerto en el que la aplicación escucha"
  type        = number
  default     = 5000
  
  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "El puerto debe estar entre 1 y 65535."
  }
}

# Variable: Path del health check
variable "health_check_path" {
  description = "Ruta para el health check del ALB"
  type        = string
  default     = "/"
  
  validation {
    condition     = can(regex("^/", var.health_check_path))
    error_message = "El path debe comenzar con /."
  }
}

# Variable: Protección contra eliminación
variable "enable_deletion_protection" {
  description = "Habilitar protección contra eliminación del ALB"
  type        = bool
  default     = false
}
