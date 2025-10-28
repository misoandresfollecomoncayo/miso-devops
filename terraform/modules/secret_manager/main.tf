resource "aws_secretsmanager_secret" "github-pat" {
    name = "Token-Github"
}

resource "aws_secretsmanager_secret_version" "github-pat-value" {
    secret_id = aws_secretsmanager_secret.github-pat.id
    secret_string = var.personal-access-token-github
}