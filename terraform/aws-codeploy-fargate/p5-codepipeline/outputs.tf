output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.app.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.app.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.app.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.app.arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.arn
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline IAM role"
  value       = aws_iam_role.codepipeline.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild.arn
}

output "console_url" {
  description = "AWS Console URL for the pipeline"
  value       = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.app.name}/view?region=${local.region}"
}

output "pipeline_summary" {
  description = "Summary of the pipeline configuration"
  value = {
    pipeline_name     = aws_codepipeline.app.name
    codebuild_project = aws_codebuild_project.app.name
    artifacts_bucket  = aws_s3_bucket.codepipeline_artifacts.bucket
    github_repo       = var.github_repo
    github_branch     = var.github_branch
    stages = {
      source = "GitHub"
      build  = "CodeBuild"
      deploy = "CodeDeploy (Blue/Green)"
    }
    codedeploy = {
      application      = var.codedeploy_app_name
      deployment_group = var.codedeploy_deployment_group
    }
    ecs = {
      cluster = var.ecs_cluster_name
      service = var.ecs_service_name
    }
    region     = local.region
    account_id = local.account_id
  }
}
