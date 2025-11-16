# Paso 1: Roles IAM para CodeDeploy

Configuración de roles y políticas IAM necesarios para que AWS CodeDeploy pueda gestionar despliegues Blue/Green en Amazon ECS.

## Recursos Creados

- **IAM Role**: `python-app-dev-codedeploy-ecs-role`
- **Políticas adjuntas**:
  - `AWSCodeDeployRoleForECS` - Permisos básicos de CodeDeploy para ECS
  - `ElasticLoadBalancingFullAccess` - Gestión de Load Balancers durante despliegues
  - `AmazonECS_FullAccess` - Acceso completo a ECS para gestionar servicios y tasks

## Uso

### Despliegue

```bash
terraform init
terraform plan
terraform apply
```

### Verificación

```bash
# Ver outputs
terraform output

# Verificar rol en AWS
aws iam get-role --role-name python-app-dev-codedeploy-ecs-role
```

## Outputs

- `codedeploy_role_arn` - ARN del rol (necesario para configurar CodeDeploy)
- `codedeploy_role_name` - Nombre del rol

## Variables

Configura en `terraform.tfvars`:

```hcl
project_name = "python-app"  # Nombre del proyecto
environment  = "dev"         # Entorno (dev, staging, prod)
aws_region   = "us-east-1"   # Región de AWS
```

## Costos

IAM Roles y Policies no tienen costo.

## Limpieza

```bash
terraform destroy
```