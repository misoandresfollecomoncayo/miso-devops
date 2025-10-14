# 1. Crear IAM Role para beanstalk
resource "aws_iam_role" "beanstalk_service_assume" {
    name = var.rolename_service

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
resource "aws_iam_role_policy_attachment" "service_role_managed_updates" {
    role = aws_iam_role.beanstalk_service_assume.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

resource "aws_iam_role_policy_attachment" "service_role_enhanced_health" {
    role = aws_iam_role.beanstalk_service_assume.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "service_role_beanstalk_service" {
    role = aws_iam_role.beanstalk_service_assume.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}