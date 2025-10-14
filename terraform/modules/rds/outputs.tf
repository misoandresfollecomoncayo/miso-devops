output "db_endpoint" {
    value = aws_db_instance.postgres.endpoint
}

output "db_host" {
    value = aws_db_instance.postgres.address
}