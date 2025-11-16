# Paso 3.5: Amazon RDS PostgreSQL

Este paso crea una base de datos PostgreSQL en Amazon RDS para la aplicación.

##  Recursos que se crean

- **RDS PostgreSQL Instance** (db.t3.micro)
  - Engine: PostgreSQL 15.4
  - Storage: 20 GB gp3 cifrado
  - Enhanced Monitoring: Habilitado
  - Performance Insights: Habilitado
  - CloudWatch Logs: Habilitado

- **Security Group** (permite tráfico desde ECS Tasks)
- **DB Subnet Group** (usa las subnets públicas)
- **IAM Role** (para Enhanced Monitoring)

##  Prerequisitos

Debes tener completado:
1. Paso 2: VPC y Networking
2. Paso 3: ALB y Target Groups

##  Despliegue

### 1. Inicializar Terraform

```bash
cd terraform/aws-codeploy-fargate/p3-rds-postgres
terraform init
```

### 2. Revisar el plan

```bash
terraform plan
```

### 3. Aplicar cambios

```bash
terraform apply
```

****Tiempo estimado**: 5-10 minutos

### 4. Obtener información de conexión

```bash
# Obtener el host de RDS
terraform output db_host

# Ver toda la información de conexión
terraform output connection_info

# Ver resumen completo
terraform output rds_summary
```

##  Credenciales por defecto

****Cambiar en producción:**
- **Usuario**: `postgres`
- **Contraseña**: `postgres123`
- **Base de datos**: `miso_devops_blacklists`
- **Puerto**: `5432`

## 📝 Siguiente paso: Actualizar Task Definition

Después de crear RDS, necesitas actualizar la Task Definition (Paso 4) con el nuevo endpoint:

```bash
# Obtener el DB_HOST
cd terraform/aws-codeploy-fargate/p3-rds-postgres
DB_HOST=$(terraform output -raw db_host)
echo "DB_HOST: $DB_HOST"

# Actualizar terraform.tfvars en p4-ecs-cluster-task
cd ../p4-ecs-cluster-task
# Editar terraform.tfvars y cambiar db_host
```

O usar el script de actualización automática:

```bash
./update-db-config.sh
```

## 💰 Costos Estimados

- **db.t3.micro**: ~$15-20/mes (Free Tier: 750 horas/mes por 12 meses)
- **Storage (20 GB)**: ~$2.30/mes
- **Backups**: Incluidos

**Total**: ~$17-22/mes (o **GRATIS** en Free Tier)

## 🔍 Verificación

1. Ve a AWS Console → RDS
2. Busca la instancia `python-app-dev-db`
3. Verifica que el estado sea `Available`
4. Revisa los logs en CloudWatch

### Probar conexión (desde un contenedor o EC2 en la misma VPC)

```bash
psql -h <db_host> -U postgres -d miso_devops_blacklists
```

## 🧹 Destruir recursos

```bash
terraform destroy
```

****Nota**: Por defecto se omite el snapshot final (`skip_final_snapshot = true`). Cambiar a `false` en producción para conservar backups.

##  Monitoreo

La instancia incluye:
- **Enhanced Monitoring** (60 segundos)
- **Performance Insights** (7 días de retención)
- **CloudWatch Logs** (postgresql, upgrade)
- **Automated Backups** (7 días de retención)

## 🔗 Conexión desde ECS

Las variables de entorno en la Task Definition serán:

```terraform
environment = [
  { name = "DB_USER", value = "postgres" },
  { name = "DB_PASSWORD", value = "postgres123" },
  { name = "DB_HOST", value = "<rds-endpoint>.rds.amazonaws.com" },
  { name = "DB_PORT", value = "5432" },
  { name = "DB_NAME", value = "miso_devops_blacklists" }
]
```

## Seguridad

- Storage cifrado (encryption-at-rest)
- No públicamente accesible
- Security Group restrictivo (solo desde ECS)
- Backups automáticos habilitados
- Credenciales en texto plano (usar Secrets Manager en producción)

## 📝 Mejoras para Producción

1. **Multi-AZ**: Cambiar `multi_az = true` para alta disponibilidad
2. **Secrets Manager**: Usar AWS Secrets Manager para credenciales
3. **Instance Class**: Escalar a `db.t3.small` o superior
4. **Final Snapshot**: Cambiar `skip_final_snapshot = false`
5. **Backup Window**: Ajustar según tu zona horaria
6. **Monitoring**: Habilitar alarmas en CloudWatch
