
###########################################################
# IAM CodeBuild
###########################################################

module "iam_codebuild" {
    source = "../../modules/iam_codebuild"
}

###########################################################
# Personal Token Github
###########################################################

module "secret_manager" {
    source = "../../modules/secret_manager"
    personal-access-token-github = var.personal-access-token-github
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
    auth_github_token = module.secret_manager.secret_manager_value
    compute_type = var.compute_type
    aws_region = var.aws_region
}