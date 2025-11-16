# AWS CodeDeploy con ECS Fargate - Blue/Green Deployment

Infraestructura como código para implementar despliegues Blue/Green automatizados de aplicaciones Python en AWS ECS Fargate utilizando CodeDeploy y CodePipeline.

## Descripción General

Este proyecto configura una infraestructura completa de CI/CD en AWS que incluye:

- Repositorio de imágenes Docker (ECR)
- Red virtual privada (VPC) con subnets públicas
- Application Load Balancer con Target Groups para Blue/Green
- Base de datos RDS PostgreSQL
- Cluster ECS Fargate para contenedores
- Pipeline de CI/CD automatizado con CodePipeline
- Despliegues Blue/Green controlados con CodeDeploy

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
└────────────────────────┬────────────────────────────────────────┘
                         │ (Push/Commit)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        CodePipeline                              │
│  ┌──────────┐    ┌────────────┐    ┌─────────────────┐        │
│  │  Source  │───▶│   Build    │───▶│     Deploy      │        │
│  │ (GitHub) │    │ (CodeBuild)│    │  (CodeDeploy)   │        │
│  └──────────┘    └────────────┘    └─────────────────┘        │
└────────────────────────────────────────────────────────────────┘
                                               │
                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Blue/Green Deployment                         │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │  Blue (Active)  │              │ Green (Standby) │          │
│  │  ECS Service    │◀────────────▶│  ECS Service    │          │
│  └─────────────────┘              └─────────────────┘          │
│          │                                  │                   │
│          ▼                                  ▼                   │
│  ┌─────────────────────────────────────────────────┐           │
│  │        Application Load Balancer (ALB)          │           │
│  │   Production (80)  │  Test (8080)               │           │
│  └─────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │   RDS PostgreSQL │
              └──────────────────┘
```

## Estructura del Proyecto

```
terraform/aws-codeploy-fargate/
├── README.md                      # Este archivo
├── deploy-all.sh                  # Script de despliegue automatizado
├── destroy-all.sh                 # Script de destrucción completa
│
├── p1-iam-roles/                  # Roles IAM para CodeDeploy
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── p2-ecr/                        # Repositorio de contenedores
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── rebuild-and-push.sh
│   └── README.md
│
├── p3-alb-target-groups/          # VPC, ALB y Target Groups
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── p3-rds-postgres/               # Base de datos PostgreSQL
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── p4-ecs-cluster-task/           # ECS Cluster y Service
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
└── p5-codepipeline/               # Pipeline CI/CD
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── setup-codestar-connection.sh
    └── README.md
```

## Requisitos Previos

- AWS CLI configurado con credenciales válidas
- Terraform >= 1.0
- Docker instalado
- Cuenta de GitHub con repositorio configurado
- Permisos IAM suficientes en AWS

## Despliegue Rápido

### Opción 1: Despliegue Automatizado (Recomendado)

```bash
cd terraform/aws-codeploy-fargate
./deploy-all.sh
```

Este script desplegará automáticamente toda la infraestructura en el orden correcto.

### Opción 2: Despliegue Manual por Pasos

Consulta el README de cada módulo para despliegue individual:

1. [IAM Roles](./p1-iam-roles/README.md) - Roles y permisos
2. [ECR Repository](./p2-ecr/README.md) - Repositorio de imágenes
3. [VPC y ALB](./p3-alb-target-groups/README.md) - Red y balanceador
4. [RDS PostgreSQL](./p3-rds-postgres/README.md) - Base de datos
5. [ECS Cluster](./p4-ecs-cluster-task/README.md) - Contenedores
6. [CodePipeline](./p5-codepipeline/README.md) - CI/CD automatizado

## Configuración

### Variables Principales

Cada módulo tiene su archivo `terraform.tfvars` con variables configurables:

```hcl
project_name = "python-app"
environment  = "dev"
aws_region   = "us-east-1"
```

### Estrategias de Despliegue

El proyecto soporta múltiples estrategias de despliegue Blue/Green:

- **ECSAllAtOnce**: Cambio instantáneo (30 segundos)
- **ECSCanary10Percent5Minutes**: 10% → espera 5min → 90% (recomendado)
- **ECSCanary10Percent15Minutes**: 10% → espera 15min → 90%
- **ECSLinear10PercentEvery1Minutes**: Incrementos de 10% cada minuto
- **ECSLinear10PercentEvery3Minutes**: Incrementos de 10% cada 3 minutos

Para cambiar la estrategia:

```bash
./update-deployment-strategy.sh
```

Consulta [ESTRATEGIAS-DEPLOYMENT.md](./ESTRATEGIAS-DEPLOYMENT.md) para más detalles.

## Pipeline CI/CD

El pipeline se activa automáticamente en cada push a la rama `main`:

1. **Source**: Descarga código desde GitHub (CodeStar Connection)
2. **Build**: Construye imagen Docker y la sube a ECR
3. **Deploy**: Despliega con CodeDeploy usando Blue/Green

### Configuración del Pipeline

Antes del primer despliegue del pipeline, configura la conexión a GitHub:

```bash
cd p5-codepipeline
./setup-codestar-connection.sh
```

Consulta [p5-codepipeline/README.md](./p5-codepipeline/README.md) para más detalles.

## Monitoreo y Logs

### CloudWatch Logs

```bash
# Ver logs de la aplicación
aws logs tail /ecs/python-app-dev --follow

# Ver logs de CodeBuild
aws logs tail /aws/codebuild/python-app-dev-build --follow
```

### Estado del Servicio ECS

```bash
aws ecs describe-services \
  --cluster python-app-dev-cluster \
  --services python-app-dev-service \
  --region us-east-1
```

### Historial de Despliegues

```bash
aws deploy list-deployments \
  --application-name python-app-dev-app \
  --region us-east-1
```

## Acceso a la Aplicación

Después del despliegue, obtén la URL del balanceador:

```bash
cd p3-alb-target-groups
terraform output alb_dns_name
```

- **Producción (Blue)**: http://ALB_DNS_NAME
- **Test (Green)**: http://ALB_DNS_NAME:8080

## Costos Estimados

Costos mensuales aproximados (región us-east-1):

| Recurso | Costo Mensual |
|---------|---------------|
| ECS Fargate (2 tasks) | ~$30 |
| RDS db.t3.micro | ~$15 |
| Application Load Balancer | ~$20 |
| NAT Gateway | $0 (no usado) |
| ECR Storage (1 GB) | ~$0.10 |
| CodeBuild (100 builds) | ~$1 |
| **Total Estimado** | **~$66/mes** |

Nota: Los costos pueden variar según uso y región.

## Destrucción de Recursos

Para eliminar toda la infraestructura:

```bash
./destroy-all.sh
```

Advertencia: Esta operación es irreversible y eliminará todos los recursos creados.

## Solución de Problemas

### Error: GitHub OAuth deprecated

**Problema**: El pipeline falla en la etapa Source con error de autenticación.

**Solución**: Migrar a CodeStar Connection. Ver [p5-codepipeline/SOLUCION-GITHUB-OAUTH.md](./p5-codepipeline/SOLUCION-GITHUB-OAUTH.md)

### Error: Deployment group not found

**Problema**: CodeDeploy no encuentra el deployment group.

**Solución**: Verificar que el ECS service use deployment controller CODE_DEPLOY. Ver [CONFIGURACION-MANUAL-CODEDEPLOY.md](./CONFIGURACION-MANUAL-CODEDEPLOY.md)

### Tests fallan en CodeBuild

**Problema**: Tests de base de datos fallan durante el build.

**Solución**: Los tests están deshabilitados en `buildspec.yml` ya que CodeBuild no tiene acceso a RDS. Los tests se ejecutan en el entorno ECS.

## Documentación Adicional

- [Estrategias de Deployment](./ESTRATEGIAS-DEPLOYMENT.md)
- [Ciclo Destroy-Deploy](./CICLO-DESTROY-DEPLOY.md)
- [Configuración Manual de CodeDeploy](./CONFIGURACION-MANUAL-CODEDEPLOY.md)
- [Scripts de Automatización](./README-SCRIPTS.md)

## Seguridad

### Buenas Prácticas Implementadas

- Cifrado de imágenes en ECR (AES256)
- Escaneo automático de vulnerabilidades en ECR
- RDS con storage encryption habilitado
- Security Groups con reglas restrictivas
- Secrets almacenados en variables de entorno (no en código)
- IAM roles con permisos mínimos necesarios

### Credenciales de Base de Datos

Por defecto, se usan credenciales de desarrollo. Para producción:

```hcl
# p3-rds-postgres/terraform.tfvars
db_username = "postgres"
db_password = "USE_SECRETS_MANAGER_IN_PRODUCTION"
```

Recomendación: Usar AWS Secrets Manager para producción.

## Contribución

1. Crear feature branch desde `main`
2. Realizar cambios
3. Probar localmente con `terraform plan`
4. Commit y push
5. El pipeline se ejecutará automáticamente

## Licencia

Este proyecto es parte del curso MISO DevOps - Universidad de los Andes.

## Soporte

Para problemas o preguntas:
- Revisar documentación en cada módulo (README.md)
- Consultar archivos de troubleshooting (*.md)
- Verificar logs en CloudWatch

---

**Última actualización**: Noviembre 2025
**Versión de Terraform**: >= 1.0
**Provider AWS**: ~> 5.0
