resource "aws_codebuild_source_credential" "github" {
    auth_type   = "PERSONAL_ACCESS_TOKEN"
    server_type = "GITHUB"
    token       = var.personal-access-token-github
}