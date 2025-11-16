# Paso 3: VPC, ALB y Target Groups

Infraestructura de red completa con VPC, subnets públicas, Application Load Balancer y Target Groups para despliegues Blue/Green.

## Recursos Creados

### Red
- **VPC**: 10.0.0.0/16 con DNS habilitado
- **Subnets públicas**: 2 subnets en diferentes AZs (10.0.1.0/24, 10.0.2.0/24)
- **Internet Gateway**: Para acceso público
- **Route Tables**: Tablas de ruteo con rutas a IGW

### Seguridad
- **ALB Security Group**: Permite tráfico HTTP (80, 8080) desde internet
- **ECS Tasks Security Group**: Permite tráfico desde ALB

### Load Balancing
- **Application Load Balancer**: Balanceador público
- **Target Group Blue**: Puerto 80 (producción)
- **Target Group Green**: Puerto 8080 (test/staging)
- **Listeners HTTP**: Puertos 80 y 8080

## Uso

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

- `vpc_id` - ID de la VPC creada
- `public_subnet_ids` - IDs de subnets públicas
- `alb_dns_name` - DNS del balanceador (URL de acceso)
- `alb_arn` - ARN del ALB
- `target_group_blue_arn` - ARN del TG Blue (producción)
- `target_group_green_arn` - ARN del TG Green (test)
- `ecs_tasks_security_group_id` - SG para ECS tasks

## Variables

```hcl
project_name          = "python-app"
environment           = "dev"
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
```

## Acceso

Después del despliegue:

- **Producción (Blue)**: http://ALB_DNS_NAME
- **Test (Green)**: http://ALB_DNS_NAME:8080

## Costos

- ALB: ~$20/mes
- VPC/Subnets: Gratis
- Internet Gateway: Gratis

## Limpieza

```bash
terraform destroy
```
