# 1. Crear IAM Role para Elastic Beanstalk
resource "aws_iam_role" "elasticbeanstalk_role" {
    name = var.rolename

assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    {
        Effect = "Allow"
        Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }
    ]
})
}

# 2. Adjuntar políticas administradas de AWS
resource "aws_iam_role_policy_attachment" "eb_web_tier" {
    role       = aws_iam_role.elasticbeanstalk_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_worker_tier" {
    role       = aws_iam_role.elasticbeanstalk_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "eb_docker_tier" {
    role       = aws_iam_role.elasticbeanstalk_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}
