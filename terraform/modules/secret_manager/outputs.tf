output "secret_manager_value" {
    value = aws_secretsmanager_secret_version.github-pat-value.secret_string
    sensitive = true
}