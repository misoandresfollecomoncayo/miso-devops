# ============================================
# Variables de entrada para el Paso 1
# ============================================
# Este archivo SOLO define las variables
# Los VALORES se asignan en terraform.tfvars

# ============================================
# Variable: Región de AWS
# ============================================
variable "aws_region" {
    description = "Región de AWS donde se desplegarán los recursos"
    type        = string
    default     = "us-east-1"

    validation {
        condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
        error_message = "La región debe tener el formato: us-east-1, us-west-2, etc."
    }
}

# ============================================
# Variable: Nombre del proyecto
# ============================================
variable "project_name" {
  description = "Nombre del proyecto (se usa como prefijo en recursos)"
  type        = string
  default     = "python-app"
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "El nombre del proyecto debe tener entre 1 y 20 caracteres."
  }
}

# ============================================
# Variable: Ambiente
# ============================================
variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser: dev, staging o prod."
  }
}