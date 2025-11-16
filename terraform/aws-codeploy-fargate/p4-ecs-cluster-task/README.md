# Paso 4: ECS Cluster y Task Definition

Este paso crea el Cluster ECS y la Task Definition necesaria para ejecutar la aplicación en Fargate.

##  Recursos que se crean

### ECS Cluster
- **Cluster ECS**: Cluster con Container Insights habilitado

### Task Definition
- **Task Definition**: Definición de la tarea con configuración Fargate
  - CPU: 256 (0.25 vCPU)
  - Memoria: 512 MB
  - Network Mode: awsvpc
  - Imagen: Desde ECR

### IAM Roles
- **Task Execution Role**: Para descargar imágenes y escribir logs
- **Task Role**: Para acceso en runtime (aplicación)

### CloudWatch
- **Log Group**: Para los logs de la aplicación

##  Prerequisitos

Debes tener:
1. Repositorio ECR creado (Paso 2)
2. Imagen Docker subida a ECR
3. Base de datos RDS disponible (actualizar en terraform.tfvars)

##  Instrucciones de uso

### 1. Configurar variables

Edita `terraform.tfvars` y actualiza:
- `ecr_repository_url`: URL de tu repositorio ECR
- `db_host`: Endpoint de tu base de datos RDS
- `db_password`: Contraseña de la base de datos

### 2. Inicializar Terraform

```bash
cd terraform/aws-codeploy-fargate/p4-ecs-cluster-task
terraform init
```

### 3. Revisar el plan

```bash
terraform plan
```

### 4. Aplicar cambios

```bash
terraform apply
```

##  Configuración de Task Definition

La Task Definition incluye:

- **Recursos**: 256 CPU / 512 MB Memory
- **Puerto**: 5000 (aplicación Flask)
- **Health Check**: Curl al endpoint raíz
- **Variables de entorno**: DB_USER, DB_PASSWORD, DB_NAME, DB_HOST, DB_PORT
- **Logs**: CloudWatch con retención de 7 días

## 🔍 Verificación

Después de aplicar:

1. Ve a AWS Console → ECS → Clusters
2. Verifica que exista el cluster `python-app-dev-cluster`
3. Ve a Task Definitions
4. Busca `python-app-dev` y revisa la configuración

### Ver logs (después de desplegar el servicio)

```bash
aws logs tail /ecs/python-app-dev --follow
```

## 📝 Notas importantes

- La Task Definition está lista pero NO desplegada aún
- El servicio ECS se creará en el siguiente paso
- Los logs se guardan en CloudWatch con retención de 7 días
- La imagen debe existir en ECR antes de crear el servicio

##  Seguridad

****IMPORTANTE**: 
- La contraseña de la base de datos está en texto plano en `terraform.tfvars`
- Para producción, usa AWS Secrets Manager o Parameter Store
- No subas `terraform.tfvars` al control de versiones

##  Destruir recursos

```bash
terraform destroy
```

**Nota**: Debes destruir primero el servicio ECS (paso 5) antes de destruir el cluster.
