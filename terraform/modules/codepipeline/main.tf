resource "aws_codepipeline" "docker_build_pipe" {
    name = var.pipeline_name
    role_arn = var.role_arn

    artifact_store {
        location = var.bucket_versiones
        type = "S3"
    }

    pipeline_type = "V2"
    execution_mode = "QUEUED"

    stage {
        name = "Source"

        action {
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeStarSourceConnection"
            version = "1"
            output_artifacts = ["source_output"]

            configuration = {
                FullRepositoryId = var.source_location
                BranchName = var.source_version
                ConnectionArn = var.codeconnections_arn
            }
        }
    }

    stage {
        name = "Build"

        action {
            name = "Build"
            category = "Build"
            owner = "AWS"
            provider = "CodeBuild"
            input_artifacts = ["source_output"]
            output_artifacts = ["build_output"]
            version = "1"

            configuration = {
                ProjectName = var.codebuild_name
            }
        }
    }
}