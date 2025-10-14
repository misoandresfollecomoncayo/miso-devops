###########################################################
# Beanstalk Application Configuration
###########################################################

resource "aws_elastic_beanstalk_application" "app" {
    name        = var.application_name
    description = "Elastic Beanstalk application for ${var.application_name}"
}

resource "aws_elastic_beanstalk_configuration_template" "template" {
    name                = "${var.application_name}-template"
    application         = aws_elastic_beanstalk_application.app.name
    solution_stack_name = var.solution_stack_name

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = var.instance_role
    }

    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "ServiceRole"
        value     = var.service_role
    }

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "InstanceType"
        value     = var.instance_type
    }

}

###########################################################
# Beanstalk Environment Configuration
###########################################################

#Generar Dockerrun.aws.json localmente
resource "local_file" "dockerrun" {
    filename = "${path.module}/build/Dockerrun.aws.json"
    content  = jsonencode({
    AWSEBDockerrunVersion = "1"
    Image = {
        Name   = "${var.ecr_image_uri}:latest"
        Update = "true"
    }
    Ports = [
        { ContainerPort = "8000" }
    ]
    Environment = [
        { 
            Name =  "DB_USER"
            Value = "${var.username}"
        },
        { 
            Name =  "DB_PASSWORD"
            Value = "${var.password}"
        },
        { 
            Name =  "DB_NAME"
            Value = "${var.db_name}"
        },
        { 
            Name =  "DB_HOST"
            Value = "${var.db_host}"
        }      
    ]
})
}

#Crear zip desde el dockerrun
data "archive_file" "app_version_zip" {
    type        = "zip"
    output_path = "${path.module}/build/${var.application_name}-version.zip"

    source {
        content  = local_file.dockerrun.content
        filename = "Dockerrun.aws.json"
    }
}

#Subir ZIP al bucket
resource "aws_s3_object" "app_version_object" {
    bucket = var.bucket_id
    key    = "${var.application_name}/${basename(data.archive_file.app_version_zip.output_path)}"
    source = data.archive_file.app_version_zip.output_path
    etag   = data.archive_file.app_version_zip.output_md5

    depends_on = [ data.archive_file.app_version_zip ]
}

#Crear aplicación version en beanstalk
resource "aws_elastic_beanstalk_application_version" "app_version" {
    application = aws_elastic_beanstalk_application.app.name
    name        = "${var.application_name}-v-${timestamp()}"
    bucket      = var.bucket_id
    key         = aws_s3_object.app_version_object.key

    # opcional: manejar el lifecycle
    lifecycle {
        create_before_destroy = true
    }
}

#Crear environment y desplegar la versión creda
resource "aws_elastic_beanstalk_environment" "env" {
    name                = var.environment_name
    application         = aws_elastic_beanstalk_application.app.name
    solution_stack_name = var.solution_stack_name
    version_label       = aws_elastic_beanstalk_application_version.app_version.name

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = var.instance_role
    }

    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "ServiceRole"
        value     = var.service_role
    }

    # healthcheck y puerto (dependiendo de tu app)
    setting {
        namespace = "aws:elasticbeanstalk:application"
        name      = "Application Healthcheck URL"
        value     = "/ping"
    }
}