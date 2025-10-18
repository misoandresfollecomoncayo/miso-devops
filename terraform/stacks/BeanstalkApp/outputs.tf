output "application_name" {
    value = module.beanstalk.application_name
}

output "endpoint_url" {
    value = module.beanstalk.endpoint_url
}

output "dbs_url" {
    value = module.beanstalk.dns_url
}