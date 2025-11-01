resource "aws_iam_role" "codebuild_role" {
    name               = "codebuid-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
    name = "codebuild-policy"
    role = aws_iam_role.codebuild_role.id

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
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:DescribeRepositories",
            "ecr:DescribeImages"
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
                "codeconnections:GetConnectionToken",
                "codeconnections:GetConnection"
            ],
            Resource = "*"
        }
        ]
    })
}