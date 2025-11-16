aws_region   = "us-east-1"
project_name = "python-app"
environment  = "dev"

# Network (valores del paso 3)
vpc_id = "vpc-00b4c218a107af0ff"
ecs_tasks_security_group_id = "sg-06d1bf2977cb264b3"

# Database
postgres_version    = "15.15"
db_instance_class   = "db.t3.micro"
allocated_storage   = 20
db_name            = "miso_devops_blacklists"
db_username        = "postgres"
db_password        = "postgres123"

# Network
publicly_accessible = false
multi_az           = false

# Backup
backup_retention_period = 7
skip_final_snapshot    = true
