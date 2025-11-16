# ============================================
# Outputs del Paso 1
# ============================================
# Estos valores se pueden usar en pasos posteriores
# o simplemente para verificar qué se creó

# ============================================
# Output: ARN del rol (lo más importante)
# ============================================
output "codedeploy_role_arn" {
  description = "ARN del rol de CodeDeploy (necesario para crear deployment group)"
  value       = aws_iam_role.codedeploy_ecs.arn
}

# ============================================
# Output: Nombre del rol
# ============================================
output "codedeploy_role_name" {
  description = "Nombre del rol de CodeDeploy"
  value       = aws_iam_role.codedeploy_ecs.name
}

# ============================================
# Output: ID del rol
# ============================================
output "codedeploy_role_id" {
  description = "ID único del rol"
  value       = aws_iam_role.codedeploy_ecs.id
}

# ============================================
# Output: URL de AWS Console para ver el rol
# ============================================
output "console_url" {
  description = "URL directa para ver el rol en AWS Console"
  value       = "https://console.aws.amazon.com/iam/home?region=${data.aws_region.current.name}#/roles/${aws_iam_role.codedeploy_ecs.name}"
}

# ============================================
# Output: Información resumida
# ============================================
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

# ============================================
# Output: Comando para verificar en AWS CLI
# ============================================
output "verify_command" {
  description = "Comando AWS CLI para verificar el rol"
  value       = "aws iam get-role --role-name ${aws_iam_role.codedeploy_ecs.name}"
}