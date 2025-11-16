# ============================================
# PASO 2: Amazon ECR (Elastic Container Registry)
# ============================================
# Este archivo contiene:
# 1. Configuración de Terraform y Provider AWS
# 2. Repositorio ECR para almacenar imágenes Docker
# 3. Política del ciclo de vida para gestión de imágenes

# ============================================
# 1. Configuración de Terraform
# ============================================
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# 2. Configuración del Provider AWS
# ============================================
provider "aws" {
  region = var.aws_region
  
  # Tags por defecto para TODOS los recursos
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Step        = "2-ECR"
    }
  }
}

# ============================================
# 3. Data Sources
# ============================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================
# 4. Repositorio ECR
# ============================================
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = var.image_tag_mutability

  # Habilitar escaneo de vulnerabilidades en push
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Cifrado de imágenes
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecr"
  }
}

# ============================================
# 5. Política de ciclo de vida para ECR
# ============================================
# Mantiene solo las últimas N imágenes y elimina las antiguas
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener solo las últimas ${var.max_image_count} imágenes"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================
# 6. Política de permisos del repositorio (Opcional)
# ============================================
# Permite que otras cuentas AWS accedan al repositorio si es necesario
resource "aws_ecr_repository_policy" "app" {
  count      = var.allow_cross_account_access ? 1 : 0
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_account_ids
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
