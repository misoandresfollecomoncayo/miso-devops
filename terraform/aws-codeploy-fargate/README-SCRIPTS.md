# 🚀 Scripts de Automatización - Tutorial 5

Scripts centralizados para desplegar y destruir toda la infraestructura del Tutorial 5.

## 📦 Scripts Disponibles

### 1. `deploy-all.sh` - Despliegue Completo

Despliega todos los recursos en el orden correcto:

```bash
./deploy-all.sh
```

**Pasos que ejecuta:**

1. ✅ **Verificación de prerequisitos**
   - Terraform instalado
   - AWS CLI configurado
   - Docker funcionando
   - Credenciales AWS válidas

2. 🔐 **IAM Roles** (p1-iam-roles)
   - Roles para CodeDeploy

3. 📦 **ECR Repository** (p2-ecr)
   - Repositorio de imágenes
   - Build y push de imagen Docker

4. 🌐 **VPC y Networking** (p2-vpc-network)
   - VPC con 2 subnets públicas
   - Internet Gateway
   - Security Groups

5. ⚖️ **Application Load Balancer** (p3-alb-target-groups)
   - ALB con listeners Blue/Green
   - Target Groups

6. 🗄️ **RDS PostgreSQL** (p3-rds-postgres)
   - Base de datos PostgreSQL 15.4
   - Actualización automática de DB_HOST en Task Definition

7. 🐳 **ECS Cluster y Service** (p4-ecs-cluster-task)
   - Cluster ECS
   - Task Definition
   - Service con CODE_DEPLOY controller

**Tiempo estimado:** 15-20 minutos

**Output:**
- Resumen completo de recursos creados
- URLs de acceso a la aplicación
- Próximos pasos recomendados
- Log detallado en `deployment.log`

---

### 2. `destroy-all.sh` - Destrucción Completa

Elimina todos los recursos en orden inverso:

```bash
./destroy-all.sh
```

**⚠️ Confirmación requerida:**
- Solicita confirmación explícita (escribir 'yes')
- Muestra lista de recursos a eliminar
- Última oportunidad para cancelar

**Pasos que ejecuta:**

1. 🐳 **ECS Service y Cluster**
   - Forzar desired count a 0
   - Eliminar service
   - Destruir cluster

2. 🗄️ **RDS PostgreSQL**
   - Eliminar base de datos

3. ⚖️ **Load Balancer y Target Groups**
   - Eliminar ALB y listeners

4. 🌐 **VPC y Networking**
   - Eliminar VPC y subnets

5. 📦 **ECR Repository**
   - Eliminar imágenes
   - Eliminar repositorio

6. 🔐 **IAM Roles**
   - Eliminar roles y políticas

7. 🧹 **Limpieza**
   - Archivos .tfstate
   - Directorios .terraform
   - Archivos temporales

**Tiempo estimado:** 10-15 minutos

**Output:**
- Confirmación de recursos eliminados
- Recomendaciones de verificación
- Log detallado en `destruction.log`

---

## 🎯 Uso Recomendado

### Despliegue Inicial

```bash
cd terraform/aws-codeploy-fargate
./deploy-all.sh
```

### Verificar Estado

```bash
# Ver logs del despliegue
cat deployment.log

# Ver recursos en AWS
aws ecs list-clusters
aws rds describe-db-instances
aws elbv2 describe-load-balancers
```

### Destrucción Completa

```bash
cd terraform/aws-codeploy-fargate
./destroy-all.sh
```

---

## 📋 Logs

Ambos scripts generan logs detallados:

- **deployment.log**: Log completo del despliegue
- **destruction.log**: Log completo de la destrucción

Los logs incluyen:
- Timestamps de cada operación
- Outputs de Terraform
- Errores y warnings
- Duración total del proceso

---

## 🛠️ Características

### `deploy-all.sh`

✅ **Verificación de prerequisitos**
- Valida herramientas instaladas
- Verifica credenciales AWS
- Confirma Account ID y Region

✅ **Despliegue ordenado**
- Respeta dependencias entre recursos
- Captura outputs importantes
- Actualiza configuraciones automáticamente

✅ **Manejo de errores**
- Detiene ejecución si hay errores críticos
- Logs detallados para debugging
- Señales SIGINT/SIGTERM manejadas

✅ **Integración Docker**
- Build automático de imagen
- Push a ECR
- Arquitectura correcta (linux/amd64)

✅ **Actualización dinámica**
- DB_HOST se actualiza automáticamente en Task Definition
- ECR URL se captura y usa en siguientes pasos

### `destroy-all.sh`

✅ **Confirmación de seguridad**
- Requiere confirmación explícita ('yes')
- Lista todos los recursos a eliminar
- Pausa antes de ejecutar

✅ **Destrucción ordenada**
- Orden inverso al despliegue
- Forzar eliminación de servicios ECS
- Eliminar imágenes de ECR antes del repositorio

✅ **Manejo de recursos huérfanos**
- Continúa aunque fallen algunos pasos
- Limpieza de archivos de estado
- Recomendaciones de verificación

✅ **Logs detallados**
- Tracking completo del proceso
- Warnings para recursos no encontrados
- Resumen final de eliminación

---

## 🔍 Solución de Problemas

### Error: "Terraform not found"
```bash
# Instalar Terraform
brew install terraform
```

### Error: "AWS credentials not configured"
```bash
# Configurar AWS CLI
aws configure
```

### Error: "Docker not running"
```bash
# Iniciar Docker Desktop
open -a Docker
```

### Error: "Service can't be deleted"
```bash
# Eliminar service manualmente
aws ecs delete-service --cluster python-app-dev-cluster \
  --service python-app-dev-service --force
```

### Error: "RDS takes too long to delete"
- Es normal, RDS puede tardar 5-10 minutos
- Verifica en AWS Console que esté en estado "deleting"

### Recursos huérfanos después de destroy
```bash
# Listar recursos manualmente
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=python-app

# Eliminar manualmente desde AWS Console
```

---

## 💡 Tips

1. **Primera vez**: Ejecuta `deploy-all.sh` para crear toda la infraestructura
2. **Testing**: Usa `destroy-all.sh` para limpiar y evitar costos
3. **Desarrollo**: Mantén los recursos y actualiza solo lo necesario
4. **Producción**: Modifica `skip_final_snapshot = false` en RDS antes de destroy

---

## 📊 Costos Estimados

Si dejas todos los recursos corriendo:

- **ECS Fargate**: ~$15-20/mes (1 tarea)
- **RDS db.t3.micro**: GRATIS en Free Tier (o ~$15/mes)
- **ALB**: ~$20/mes
- **Data Transfer**: Variable

**Total**: ~$35-55/mes (o ~$20/mes con Free Tier)

💡 **Recomendación**: Usa `destroy-all.sh` cuando no estés usando los recursos.

---

## 🔗 Próximos Pasos

Después de ejecutar `deploy-all.sh`:

1. Verifica que el servicio esté corriendo
2. Prueba la aplicación en el ALB
3. Continúa con el **Paso 5: AWS CodeDeploy**

---

## 📝 Notas

- Los scripts usan `set -e` para detenerse en errores
- Las operaciones de Terraform usan `-input=false` para automatización
- Los logs se guardan automáticamente
- Compatibilidad: macOS / Linux (zsh/bash)
