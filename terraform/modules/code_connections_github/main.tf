resource "aws_codeconnections_connection" "github_connections" {
    name = "github-connection"
    provider_type = "GitHub"
}