variable "rolename_ec2" {
    description = "IAMRole Name"
    type        = string
    nullable    = false
}

variable "rolename_service" {
    description = "IAMRole Beanstalk Service"
    type = string
    nullable = false
}

variable "ecr_image_uri" {
    description = "URI docker image of the app"
}

variable "aws_region" {
    description = "La región de AWS donde se desplegarán los recursos."
    type        = string
}

variable "owner" {
    description = "Propietario de los recursos, generalmente el nombre del usuario o equipo."
    type        = string
}

variable "application_name" {
    description = "Nombre de la aplicación."
    type = string
}

variable "environment_name" {
    description = "Nombre del ambiente de la aplicación."
    type = string
}

variable "solution_stack_name" {
    description = "Nombre del stack de la aplicación."
    type = string
}

variable "instance_type" {
    description = "Tipo de instancia"
    type = string
}

variable "s3_bucket_for_versions" {
    description = "Nombre del bucket S3"
    type    = string
    default = "beanstalk-versions-static"
}

variable "environment" {
    description = "Ambiente del s3"
    type = string
}

variable "identifier" {
    type = string
}

variable "db_name" {
    type = string
}

variable "username" {
    type = string
}

variable "password" {
    type = string
}

variable "DeploymentPolicy" {
    type = string
}