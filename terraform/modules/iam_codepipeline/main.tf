resource "aws_iam_role" "codepipeline_role" {
    name               = "codepipeline-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
    name = "codepipeline-policy"
    role = aws_iam_role.codepipeline_role.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect = "Allow",
            Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ],
            Resource = "*"
        },
        {
            Effect = "Allow",
            Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
            ],
            Resource = "*"
        },
        {
            Effect = "Allow",
            Action = [
                "codeconnections:*",
                "codestar-connections:*"
            ],
            Resource = var.codeconnections_arn
        },
        {
            Effect = "Allow",
            Action = [
                "codebuild:StartBuild",
                "codebuild:BatchGetBuilds"
            ],
            Resource = "*"
        }
        ]
    })
}