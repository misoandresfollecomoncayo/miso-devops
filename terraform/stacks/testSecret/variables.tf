variable "aws_region" {
    description = "La región de AWS donde se desplegarán los recursos."
    type        = string
}

variable "owner" {
    description = "Propietario de los recursos, generalmente el nombre del usuario o equipo."
    type        = string
}

variable "personal-access-token-github" {
    type = string
    sensitive = true
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

variable "bucket_versiones" {
    type = string
    default = "nose"
}