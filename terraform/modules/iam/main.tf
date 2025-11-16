# ============================================
# PASO 1: IAM Role para CodeDeploy - ECS
# ============================================
# Este rol permite a CodeDeploy gestionar despliegues Blue/Green en ECS

# ============================================
# main.tf
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
}

# ============================================
# 1. Rol IAM para CodeDeploy
# ============================================
# Este rol permite que el servicio CodeDeploy asuma permisos
resource "aws_iam_role" "codedeploy_ecs" {
  name        = "${var.project_name}-codedeploy-ecs-role"
  description = "Rol para CodeDeploy en despliegues Blue/Green de ECS"

  # Trust policy: Define quién puede asumir este rol
  # En este caso, solo el servicio codedeploy.amazonaws.com
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-codedeploy-ecs-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "CodeDeploy ECS Blue/Green Deployments"
  }
}

# ============================================
# 2. Política AWS Gestionada: AWSCodeDeployRoleForECS
# ============================================
# Esta política AWS pre-configurada da los permisos básicos para CodeDeploy con ECS
# Incluye permisos para:
# - Leer información de ECS (clusters, services, task definitions)
# - Actualizar servicios ECS
# - Registrar/deregistrar targets en ELB
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_policy" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# ============================================
# 3. Política AWS Gestionada: ElasticLoadBalancingFullAccess
# ============================================
# Permite a CodeDeploy gestionar completamente el Load Balancer
# Necesario para:
# - Modificar target groups durante Blue/Green
# - Actualizar reglas de listeners
# - Gestionar health checks
resource "aws_iam_role_policy_attachment" "codedeploy_elb" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# ============================================
# 4. Política AWS Gestionada: AmazonECS_FullAccess
# ============================================
# Da acceso completo a ECS para:
# - Crear y actualizar task definitions
# - Modificar servicios
# - Gestionar tasks en ejecución
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_full" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# ============================================
# variables.tf
# ============================================
variable "aws_region" {
  description = "Región de AWS donde desplegar"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto (se usará como prefijo)"
  type        = string
  default     = "python-app"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ============================================
# outputs.tf
# ============================================
output "codedeploy_role_arn" {
  description = "ARN del rol de CodeDeploy (necesario para crear el deployment group)"
  value       = aws_iam_role.codedeploy_ecs.arn
}

output "codedeploy_role_name" {
  description = "Nombre del rol de CodeDeploy"
  value       = aws_iam_role.codedeploy_ecs.name
}

output "codedeploy_role_id" {
  description = "ID del rol de CodeDeploy"
  value       = aws_iam_role.codedeploy_ecs.id
}

# Información adicional útil
output "role_info" {
  description = "Información completa del rol creado"
  value = {
    name        = aws_iam_role.codedeploy_ecs.name
    arn         = aws_iam_role.codedeploy_ecs.arn
    policies    = [
      "AWSCodeDeployRoleForECS",
      "ElasticLoadBalancingFullAccess", 
      "AmazonECS_FullAccess"
    ]
  }
}

# ============================================
# terraform.tfvars
# ============================================
# Crea este archivo con tus valores específicos

aws_region   = "us-east-1"
project_name = "python-app"
environment  = "dev"