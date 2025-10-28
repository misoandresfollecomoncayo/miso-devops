
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