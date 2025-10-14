# 1. Crear IAM Role para instancias de ec2
resource "aws_iam_role" "elasticbeanstalk_role" {
    name = var.rolename_ec2

assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    {
        Effect = "Allow"
        Principal = {
        Service = "ec2.amazonaws.com"
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

resource "aws_iam_role_policy_attachment" "eb_ecr_readonly" {
    role       = aws_iam_role.elasticbeanstalk_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# Instance Profile

# Crear Instance Profile para vincular el Role a EC2 (OBLIGATORIO)
resource "aws_iam_instance_profile" "elasticbeanstalk_instance_profile" {
    name = var.rolename_ec2
    role = aws_iam_role.elasticbeanstalk_role.name
}