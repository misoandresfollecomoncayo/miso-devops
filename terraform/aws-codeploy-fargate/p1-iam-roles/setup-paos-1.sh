#!/bin/bash

# ============================================
# Script para crear la estructura del PASO 1
# Crea todos los archivos automáticamente
# ============================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "============================================"
echo "  PASO 1: Creación de estructura IAM Roles"
echo "============================================"
echo -e "${NC}"

# Crear directorio
echo -e "${BLUE}→${NC} Creando directorio paso-1-iam-roles..."
mkdir -p paso-1-iam-roles
cd paso-1-iam-roles

# ============================================
# Crear main.tf
# ============================================
echo -e "${BLUE}→${NC} Creando main.tf..."
cat > main.tf << 'EOF'
# ============================================
# PASO 1: IAM Roles para CodeDeploy - ECS
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

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Step        = "1-IAM-Roles"
    }
  }
}

# IAM Role para CodeDeploy - ECS
resource "aws_iam_role" "codedeploy_ecs" {
  name        = "${var.project_name}-${var.environment}-codedeploy-ecs-role"
  description = "Permite a CodeDeploy gestionar despliegues Blue/Green en ECS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-ecs-role"
  }
}

# Política 1: AWSCodeDeployRoleForECS
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_policy" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Política 2: ElasticLoadBalancingFullAccess
resource "aws_iam_role_policy_attachment" "codedeploy_elb" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# Política 3: AmazonECS_FullAccess
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_full" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
EOF

# ============================================
# Crear variables.tf
# ============================================
echo -e "${BLUE}→${NC} Creando variables.tf..."
cat > variables.tf << 'EOF'
# ============================================
# Variables de entrada para el Paso 1
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

variable "project_name" {
  description = "Nombre del proyecto (se usa como prefijo en recursos)"
  type        = string
  default     = "python-app"
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "El nombre del proyecto debe tener entre 1 y 20 caracteres."
  }
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser: dev, staging o prod."
  }
}
EOF

# ============================================
# Crear outputs.tf
# ============================================
echo -e "${BLUE}→${NC} Creando outputs.tf..."
cat > outputs.tf << 'EOF'
# ============================================
# Outputs del Paso 1
# ============================================

output "codedeploy_role_arn" {
  description = "ARN del rol de CodeDeploy (necesario para crear deployment group)"
  value       = aws_iam_role.codedeploy_ecs.arn
}

output "codedeploy_role_name" {
  description = "Nombre del rol de CodeDeploy"
  value       = aws_iam_role.codedeploy_ecs.name
}

output "codedeploy_role_id" {
  description = "ID único del rol"
  value       = aws_iam_role.codedeploy_ecs.id
}

output "console_url" {
  description = "URL directa para ver el rol en AWS Console"
  value       = "https://console.aws.amazon.com/iam/home?region=${data.aws_region.current.name}#/roles/${aws_iam_role.codedeploy_ecs.name}"
}

output "role_summary" {
  description = "Resumen completo del rol creado"
  value = {
    name        = aws_iam_role.codedeploy_ecs.name
    arn         = aws_iam_role.codedeploy_ecs.arn
    region      = data.aws_region.current.name
    account_id  = data.aws_caller_identity.current.account_id
    policies    = [
      "AWSCodeDeployRoleForECS",
      "ElasticLoadBalancingFullAccess",
      "AmazonECS_FullAccess"
    ]
  }
}

output "verify_command" {
  description = "Comando AWS CLI para verificar el rol"
  value       = "aws iam get-role --role-name ${aws_iam_role.codedeploy_ecs.name}"
}
EOF

# ============================================
# Crear terraform.tfvars
# ============================================
echo -e "${BLUE}→${NC} Creando terraform.tfvars..."
cat > terraform.tfvars << 'EOF'
# ============================================
# Valores específicos de TU proyecto
# ============================================

aws_region   = "us-east-1"
project_name = "python-app"
environment  = "dev"
EOF

# ============================================
# Crear .gitignore
# ============================================
echo -e "${BLUE}→${NC} Creando .gitignore..."
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfstate.backup
.terraform/
.terraform.lock.hcl
*.tfplan
tfplan

# Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store

# Temp
*.tmp
*.bak
EOF

# ============================================
# Crear README.md
# ============================================
echo -e "${BLUE}→${NC} Creando README.md..."
cat > README.md << 'EOF'
# PASO 1: Roles IAM para CodeDeploy-ECS

## 🎯 Objetivo

Crear el rol IAM que permitirá a AWS CodeDeploy realizar despliegues Blue/Green en Amazon ECS.

## 📋 ¿Qué se crea?

1. **IAM Role**: `python-app-dev-codedeploy-ecs-role`
2. **3 Políticas adjuntas**:
   - AWSCodeDeployRoleForECS
   - ElasticLoadBalancingFullAccess
   - AmazonECS_FullAccess

## 🚀 Despliegue

```bash
# 1. Configurar variables (editar terraform.tfvars si es necesario)
nano terraform.tfvars

# 2. Inicializar
terraform init

# 3. Ver plan
terraform plan

# 4. Aplicar
terraform apply

# 5. Ver outputs
terraform output
```

## ✅ Verificación

```bash
# Ver el rol
aws iam get-role --role-name python-app-dev-codedeploy-ecs-role

# Ver políticas adjuntas
aws iam list-attached-role-policies --role-name python-app-dev-codedeploy-ecs-role
```

## 💰 Costo

**$0.00** - IAM es gratuito

## 📝 Guardar para después

```bash
# Guardar ARN del rol (lo usaremos en Paso 7)
export CODEDEPLOY_ROLE_ARN=$(terraform output -raw codedeploy_role_arn)
echo $CODEDEPLOY_ROLE_ARN
```
EOF

echo ""
echo -e "${GREEN}✓${NC} Todos los archivos creados exitosamente"
echo ""
echo -e "${YELLOW}Estructura creada:${NC}"
echo "paso-1-iam-roles/"
echo "├── main.tf"
echo "├── variables.tf"
echo "├── outputs.tf"
echo "├── terraform.tfvars"
echo "├── .gitignore"
echo "└── README.md"
echo ""
echo -e "${GREEN}Siguiente paso:${NC}"
echo "1. Edita terraform.tfvars si quieres cambiar valores"
echo "2. Ejecuta: cd paso-1-iam-roles"
echo "3. Ejecuta: terraform init"
echo "4. Ejecuta: terraform plan"
echo "5. Ejecuta: terraform apply"
echo ""