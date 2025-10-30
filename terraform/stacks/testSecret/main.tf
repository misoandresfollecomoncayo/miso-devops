###########################################################
# S3 para versiones
###########################################################

module "s3_bucket_for_versions" {
    source = "../../modules/s3"
    environment = var.environment
    bucket_name = var.s3_bucket_for_versions
}

###########################################################
# IAM CodeBuild
###########################################################

module "iam_codebuild" {
    source = "../../modules/iam_codebuild"
}

###########################################################
# CodeConnections for github
###########################################################

module "connection_github" {
    source = "../../modules/code_connections_github"
}

###########################################################
# Codebuild project configuration
###########################################################

module "codebuild_aws" {
    source = "../../modules/codebuild"
    build_name = var.build_name
    iam_codebuild_arn = module.iam_codebuild.codebuild_role_arn
    ecr_repo_uri = var.ecr_image_uri
    source_location = var.source_location
    source_type = var.source_type
    source_version = var.source_version
    codeconnections_arn = module.connection_github.codeconnettions_arn
    compute_type = var.compute_type
    aws_region = var.aws_region
    bucket_versiones = module.s3_bucket_for_versions.bucket_name
    db_name = var.db_name
    db_host = var.db_host #Este es la salida de un modulo
    username = var.username
    password = var.password
}

###########################################################
# IAM CodePipeline
###########################################################

module "iam_codepipeline" {
    source = "../../modules/iam_codepipeline"
}


###########################################################
# CodePipeline project configuration
###########################################################

module "codepipeline_aws" {
    source = "../../modules/codepipeline"
    pipeline_name = var.pipeline_name
    bucket_versiones = module.s3_bucket_for_versions.bucket_name
    source_location = var.source_location
    codebuild_name = module.codebuild_aws.project_name
    codeconnections_arn = module.connection_github.codeconnettions_arn
    source_version = var.source_version
    role_arn = module.iam_codepipeline.codepipeline_role_arn
}