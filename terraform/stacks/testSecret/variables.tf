variable "aws_region" {
    description = "La región de AWS donde se desplegarán los recursos."
    type        = string
}

variable "owner" {
    description = "Propietario de los recursos, generalmente el nombre del usuario o equipo."
    type        = string
}

variable "build_name" {
    type = string
}

variable "compute_type" {
    type = string
}

variable "ecr_image_uri" {
    type = string
}

variable "source_type" {
    type = string
}

variable "source_location" {
    type = string
}

variable "source_version" {
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

#No incluir

variable "username" {
    type = string
}

variable "password" {
    type = string
}

variable "db_name" {
    type = string
}

variable "db_host" {
    type = string
    default = "test"
} 

variable "pipeline_name" {
    type = string
}