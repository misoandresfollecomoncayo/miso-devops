# ============================================
# Valores específicos - Paso 5 CodePipeline
# ============================================

aws_region   = "us-east-1"
project_name = "python-app"
environment  = "dev"

# GitHub Repository
github_repo   = "ecruzs-uniandes/miso-devops"
github_branch = "main"

# GitHub Token (almacenado en AWS Secrets Manager)
github_token_secret_name = "github-token"

# ECR Repository
ecr_repository_url = "148342400171.dkr.ecr.us-east-1.amazonaws.com/python-app-dev"

# CodeDeploy
codedeploy_app_name         = "python-app-dev-app"
codedeploy_deployment_group = "python-app-dev-dg"

# ECS
ecs_cluster_name = "python-app-dev-cluster"
ecs_service_name = "python-app-dev-service"
