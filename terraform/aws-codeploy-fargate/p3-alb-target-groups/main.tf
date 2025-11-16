# ============================================
# PASO 3: VPC, Networking, ALB y Target Groups
# ============================================
# Este archivo contiene:
# 1. Configuración de Terraform y Provider AWS
# 2. VPC y Subnets
# 3. Internet Gateway y Route Tables
# 4. Security Groups (ALB y ECS Tasks)
# 5. Application Load Balancer (ALB)
# 6. Dos Target Groups (Blue y Green para despliegue Blue/Green)
# 7. Listeners HTTP

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
      Step        = "3-ALB-TargetGroups"
    }
  }
}

# ============================================
# 3. Data Sources
# ============================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# 4. VPC
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ============================================
# 5. Internet Gateway
# ============================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ============================================
# 6. Subnets Públicas (2 AZs para alta disponibilidad)
# ============================================
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# ============================================
# 7. Route Table para Subnets Públicas
# ============================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================
# 8. Security Group para ALB
# ============================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group para Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico HTTP en puerto 80 (Blue)
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir tráfico HTTP en puerto 8080 (Green - Test)
  ingress {
    description = "HTTP Test from Internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir todo el tráfico saliente
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ============================================
# 9. Security Group para ECS Tasks
# ============================================
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group para ECS Tasks"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico desde el ALB en el puerto de la aplicación
  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Permitir todo el tráfico saliente
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  }
}

# ============================================
# 10. Application Load Balancer
# ============================================
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  idle_timeout              = 60

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ============================================
# 11. Target Group Blue (Producción)
# ============================================
resource "aws_lb_target_group" "blue" {
  name        = "${var.project_name}-${var.environment}-blue-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-blue-tg"
    Type = "Blue"
  }
}

# ============================================
# 12. Target Group Green (Staging para Blue/Green)
# ============================================
resource "aws_lb_target_group" "green" {
  name        = "${var.project_name}-${var.environment}-green-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-green-tg"
    Type = "Green"
  }
}

# ============================================
# 13. Listener HTTP en puerto 80 (Producción - Blue)
# ============================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

# ============================================
# 14. Listener de Test en puerto 8080 (para validar Green)
# ============================================
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-test-listener"
  }
}
