###########################################################
# IAMRole Configuration
###########################################################

module "iam_ec2_role" {
    source = "../../modules/iam_ec2_role"
    rolename_ec2 = var.rolename_ec2
}

module "iam_service_role" {
    source = "../../modules/iam_service_role"
    rolename_service = var.rolename_service
}

###########################################################
# S3 para versiones
###########################################################

module "s3_bucket_for_versions" {
    source = "../../modules/s3"
    environment = var.environment
    bucket_name = var.s3_bucket_for_versions
}

###########################################################
# RDS para aplicación.  
###########################################################

module "rds" {
    source = "../../modules/rds"
    identifier = var.identifier
    username = var.username
    password = var.password
    db_name = var.db_name
}

###########################################################
# Beanstalk Configuration
###########################################################

module "beanstalk" {
    source = "../../modules/beanstalk"
    solution_stack_name = var.solution_stack_name
    application_name = var.application_name
    instance_type = var.instance_type
    environment_name = var.environment_name
    instance_role = module.iam_ec2_role.role_name
    service_role = module.iam_service_role.role_arn
    ecr_image_uri = var.ecr_image_uri
    bucket_id = module.s3_bucket_for_versions.bucket_id
    db_name = var.db_name
    username = var.username
    password = var.password
    db_host = module.rds.db_host
    DeploymentPolicy = var.DeploymentPolicy
}