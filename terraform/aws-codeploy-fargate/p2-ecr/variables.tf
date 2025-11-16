# Variables de entrada para el Paso 2 - ECR
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

# Variable: Mutabilidad de tags
variable "image_tag_mutability" {
  description = "Mutabilidad de los tags de imagen (MUTABLE o IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Debe ser MUTABLE o IMMUTABLE."
  }
}

# Variable: Escaneo automático
variable "scan_on_push" {
  description = "Habilitar escaneo de vulnerabilidades al hacer push de imagen"
  type        = bool
  default     = true
}

# Variable: Cantidad máxima de imágenes
variable "max_image_count" {
  description = "Número máximo de imágenes a mantener en el repositorio"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_image_count > 0 && var.max_image_count <= 100
    error_message = "El número debe estar entre 1 y 100."
  }
}

# Variable: Acceso entre cuentas
variable "allow_cross_account_access" {
  description = "Permitir acceso desde otras cuentas AWS"
  type        = bool
  default     = false
}

# Variable: IDs de cuentas permitidas
variable "allowed_account_ids" {
  description = "Lista de IDs de cuentas AWS con acceso al repositorio"
  type        = list(string)
  default     = []
}
