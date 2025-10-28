output "secret_manager_value" {
    value = aws_codebuild_source_credential.github.arn
    sensitive = true
}