resource "aws_db_instance" "postgres" {
    identifier = "db-postgres-devops"

    engine         = "postgres"
    engine_version = "17.4"
    instance_class = "db.t3.micro"

    allocated_storage = 20
    storage_type      = "gp3"

    db_name  = "dbdevops"
    username = "postgres"
    password = "postgres"

    publicly_accessible = true //Acceso público
    vpc_security_group_ids = [aws_security_group.postgres.id]
    skip_final_snapshot = true

    tags = {
        Name = "PostgreSQL Dev"
    }
}

# Security Group en VPC por defecto
resource "aws_security_group" "postgres" {
    name        = "postgres-public-access"
    description = "Permite acceso a PostgreSQL desde mi IP"

    ingress {
        description = "PostgreSQL desde mi IP"
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "db_endpoint" {
    value = aws_db_instance.postgres.endpoint
}

output "db_host" {
    value = aws_db_instance.postgres.address
}