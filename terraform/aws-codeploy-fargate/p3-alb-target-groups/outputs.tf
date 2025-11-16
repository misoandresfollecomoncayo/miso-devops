# ============================================
# Outputs del Paso 3 - VPC, ALB y Target Groups
# ============================================
# Estos valores se usan en RDS, ECS y CodeDeploy

# ============================================
# Outputs: VPC
# ============================================
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

# ============================================
# Outputs: Subnets
# ============================================
output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks de las subnets públicas"
  value       = aws_subnet.public[*].cidr_block
}

# ============================================
# Outputs: Security Groups
# ============================================
output "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "ID del Security Group de ECS Tasks"
  value       = aws_security_group.ecs_tasks.id
}

# ============================================
# Outputs: Application Load Balancer
# ============================================
output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name del ALB (usar para acceder a la aplicación)"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del ALB (para Route53)"
  value       = aws_lb.main.zone_id
}

# ============================================
# Outputs: Target Groups
# ============================================
output "blue_target_group_arn" {
  description = "ARN del Target Group Blue (producción)"
  value       = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  description = "Nombre del Target Group Blue"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_arn" {
  description = "ARN del Target Group Green (staging)"
  value       = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  description = "Nombre del Target Group Green"
  value       = aws_lb_target_group.green.name
}

# ============================================
# Outputs: Listeners
# ============================================
output "http_listener_arn" {
  description = "ARN del listener HTTP (puerto 80 - producción)"
  value       = aws_lb_listener.http.arn
}

output "test_listener_arn" {
  description = "ARN del listener de test (puerto 8080 - staging)"
  value       = aws_lb_listener.test.arn
}

# ============================================
# Output: URLs de acceso
# ============================================
output "application_url" {
  description = "URL para acceder a la aplicación en producción"
  value       = "http://${aws_lb.main.dns_name}"
}

output "test_url" {
  description = "URL para acceder a la aplicación en staging (puerto 8080)"
  value       = "http://${aws_lb.main.dns_name}:8080"
}

# ============================================
# Output: Resumen completo
# ============================================
output "alb_summary" {
  description = "Resumen completo del ALB y Target Groups"
  value = {
    alb = {
      name     = aws_lb.main.name
      arn      = aws_lb.main.arn
      dns_name = aws_lb.main.dns_name
      zone_id  = aws_lb.main.zone_id
    }
    target_groups = {
      blue = {
        name = aws_lb_target_group.blue.name
        arn  = aws_lb_target_group.blue.arn
        port = aws_lb_target_group.blue.port
      }
      green = {
        name = aws_lb_target_group.green.name
        arn  = aws_lb_target_group.green.arn
        port = aws_lb_target_group.green.port
      }
    }
    listeners = {
      production = {
        arn  = aws_lb_listener.http.arn
        port = 80
      }
      test = {
        arn  = aws_lb_listener.test.arn
        port = 8080
      }
    }
    urls = {
      production = "http://${aws_lb.main.dns_name}"
      test       = "http://${aws_lb.main.dns_name}:8080"
    }
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
  }
}

# ============================================
# Output: URL de AWS Console
# ============================================
output "console_url" {
  description = "URL directa para ver el ALB en AWS Console"
  value       = "https://console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancers:search=${aws_lb.main.name}"
}
