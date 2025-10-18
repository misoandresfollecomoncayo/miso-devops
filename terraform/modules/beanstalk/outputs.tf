output "application_name" {
    value = aws_elastic_beanstalk_application.app.name
}

output "endpoint_url" {
    value = aws_elastic_beanstalk_environment.env.endpoint_url
}

output "dns_url" {
    value = aws_elastic_beanstalk_environment.env.cname
}