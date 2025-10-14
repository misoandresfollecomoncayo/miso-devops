output "role_name" {
    value = aws_iam_role.beanstalk_service_assume.name
}

output "role_arn" {
    value = aws_iam_role.beanstalk_service_assume.arn
}