# IAM Roles para CodeDeploy con ECS
# Configuración de roles y políticas necesarias para despliegues Blue/Green

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

# IAM Role para CodeDeploy ECS
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

# Política AWS gestionada para CodeDeploy con ECS
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_policy" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Permisos para gestionar Load Balancer durante despliegues
resource "aws_iam_role_policy_attachment" "codedeploy_elb" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# Acceso completo a ECS para gestionar servicios y tasks
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_full" {
  role       = aws_iam_role.codedeploy_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}