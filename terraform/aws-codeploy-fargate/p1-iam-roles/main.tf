# ============================================
# PASO 1: IAM Roles para CodeDeploy - ECS
# ============================================
# Este archivo contiene:
# 1. Configuración de Terraform y Provider AWS
# 2. Rol IAM para CodeDeploy
# 3. Políticas adjuntas al rol

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
      Step        = "1-IAM-Roles"
    }
  }
}

# ============================================
# 3. IAM Role para CodeDeploy - ECS
# ============================================
resource "aws_iam_role" "codedeploy_ecs" {
  name        = "${var.project_name}-${var.environment}-codedeploy-ecs-role"
  description = "Permite a CodeDeploy gestionar despliegues Blue/Green en ECS"

  # Trust Policy: Define QUIÉN puede asumir este rol
  # Solo el servicio codedeploy.amazonaws.com puede usarlo
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

# ============================================
# 4. Política 1: AWSCodeDeployRoleForECS
# ============================================
# Política gestionada por AWS con permisos básicos de CodeDeploy para ECS
# Incluye: ecs:DescribeServices, ecs:CreateTaskSet, etc.
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_policy" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# ============================================
# 5. Política 2: ElasticLoadBalancingFullAccess
# ============================================
# Permite modificar el Load Balancer durante despliegues Blue/Green
# Incluye: modificar target groups, listeners, etc.
resource "aws_iam_role_policy_attachment" "codedeploy_elb" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# ============================================
# 6. Política 3: AmazonECS_FullAccess
# ============================================
# Acceso completo a ECS para gestionar servicios y tasks
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_full" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# ============================================
# 7. Data Sources (información de AWS)
# ============================================
# Obtiene información de tu cuenta AWS
data "aws_caller_identity" "current" {}

# Obtiene información de la región actual
data "aws_region" "current" {}