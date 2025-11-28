# Amazon RDS PostgreSQL
# Base de datos relacional con configuración de alta disponibilidad y monitoreo

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
      Step        = "3-RDS-PostgreSQL"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data Source - Leer outputs del módulo de networking
data "terraform_remote_state" "networking" {
  backend = "local"
  
  config = {
    path = "../p3-alb-target-groups/terraform.tfstate"
  }
}

# Variables locales derivadas de remote state
locals {
  vpc_id                      = data.terraform_remote_state.networking.outputs.vpc_id
  ecs_tasks_security_group_id = data.terraform_remote_state.networking.outputs.ecs_tasks_security_group_id
  public_subnet_ids           = data.terraform_remote_state.networking.outputs.public_subnet_ids
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group para RDS PostgreSQL"
  vpc_id      = local.vpc_id

  ingress {
    description     = "PostgreSQL from ECS Tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [local.ecs_tasks_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = data.aws_subnets.public.ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# IAM Role para Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine         = "postgres"
  engine_version = var.postgres_version

  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  multi_az = var.multi_az

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}
