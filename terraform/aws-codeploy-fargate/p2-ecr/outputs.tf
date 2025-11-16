# ============================================
# Outputs del Paso 2 - ECR
# ============================================
# Estos valores se usan para construir y pushear imágenes

# ============================================
# Output: URL del repositorio
# ============================================
output "repository_url" {
  description = "URL completa del repositorio ECR (para docker push)"
  value       = aws_ecr_repository.app.repository_url
}

# ============================================
# Output: ARN del repositorio
# ============================================
output "repository_arn" {
  description = "ARN del repositorio ECR"
  value       = aws_ecr_repository.app.arn
}

# ============================================
# Output: Nombre del repositorio
# ============================================
output "repository_name" {
  description = "Nombre del repositorio ECR"
  value       = aws_ecr_repository.app.name
}

# ============================================
# Output: Registry ID
# ============================================
output "registry_id" {
  description = "ID del registry (Account ID)"
  value       = aws_ecr_repository.app.registry_id
}

# ============================================
# Output: Comandos Docker
# ============================================
output "docker_commands" {
  description = "Comandos para autenticarse y pushear imagen a ECR"
  value = {
    login = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    build = "docker build -t ${aws_ecr_repository.app.name} ."
    tag   = "docker tag ${aws_ecr_repository.app.name}:latest ${aws_ecr_repository.app.repository_url}:latest"
    push  = "docker push ${aws_ecr_repository.app.repository_url}:latest"
  }
}

# ============================================
# Output: Resumen del repositorio
# ============================================
output "repository_summary" {
  description = "Resumen completo del repositorio ECR"
  value = {
    name                 = aws_ecr_repository.app.name
    url                  = aws_ecr_repository.app.repository_url
    arn                  = aws_ecr_repository.app.arn
    registry_id          = aws_ecr_repository.app.registry_id
    image_tag_mutability = aws_ecr_repository.app.image_tag_mutability
    scan_on_push         = var.scan_on_push
    max_images           = var.max_image_count
    region               = data.aws_region.current.name
    account_id           = data.aws_caller_identity.current.account_id
  }
}

# ============================================
# Output: URL de AWS Console
# ============================================
output "console_url" {
  description = "URL directa para ver el repositorio en AWS Console"
  value       = "https://console.aws.amazon.com/ecr/repositories/private/${data.aws_caller_identity.current.account_id}/${aws_ecr_repository.app.name}?region=${data.aws_region.current.name}"
}
