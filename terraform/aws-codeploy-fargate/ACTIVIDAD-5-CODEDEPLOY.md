# Actividad 5 - AWS CodeDeploy con Blue/Green Deployment

## 📋 Descripción

Esta actividad configura AWS CodeDeploy para realizar despliegues Blue/Green automáticos en ECS Fargate. El proceso permite despliegues sin tiempo de inactividad cambiando el tráfico entre dos entornos (Blue y Green).

## 📁 Archivos Configurados

### 1. `appspec.json`
Define cómo CodeDeploy debe desplegar la aplicación en ECS:
- Referencia al Task Definition
- Configuración del contenedor y puerto
- Información del Load Balancer

### 2. `taskdef.json`
Plantilla del Task Definition de ECS con:
- Especificaciones de CPU y memoria
- Definición del contenedor
- Variables de entorno (DB_HOST, DB_USER, etc.)
- Health check en `/ping`
- Logs en CloudWatch

**Nota**: El placeholder `<IMAGE1_NAME>` es reemplazado automáticamente por CodeBuild con la URI de la imagen construida.

### 3. `buildspec.yml` (Actualizado)
Pipeline de construcción con:
- **Install**: Instalación de dependencias Python
- **Pre_build**: 
  - Ejecución de tests con pytest
  - Login en ECR
  - Generación de tags de imagen
- **Build**: 
  - Construcción de imagen Docker (linux/amd64)
  - Tagging con commit hash y latest
- **Post_build**:
  - Push de imágenes a ECR
  - Generación de `imagedefinitions.json`
  - Actualización de `taskdef.json` con nueva imagen
- **Artifacts**: appspec.json, taskdef.json, imagedefinitions.json

## 🚀 Configuración de CodeDeploy

### Opción 1: Script Automatizado (Recomendado)

```bash
cd terraform/aws-codeploy-fargate
./setup-codedeploy.sh
```

Este script:
1. ✅ Crea CodeDeploy Application
2. ✅ Crea IAM Role con permisos necesarios
3. ✅ Crea Deployment Group con configuración Blue/Green
4. ✅ Configura Target Groups y Listeners

### Opción 2: Configuración Manual

#### Paso 1: Crear CodeDeploy Application

```bash
aws deploy create-application \
    --application-name python-app-dev-app \
    --compute-platform ECS \
    --region us-east-1
```

#### Paso 2: Crear IAM Role para CodeDeploy

```bash
# Trust policy
cat > codedeploy-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "codedeploy.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Crear role
aws iam create-role \
    --role-name python-app-dev-codedeploy-role \
    --assume-role-policy-document file://codedeploy-trust-policy.json

# Attach policy
aws iam attach-role-policy \
    --role-name python-app-dev-codedeploy-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS
```

#### Paso 3: Crear Deployment Group

```bash
# Obtener valores necesarios
CLUSTER_NAME=$(cd p4-ecs-cluster-task && terraform output -raw cluster_name)
SERVICE_NAME=$(cd p4-ecs-cluster-task && terraform output -raw service_name)
BLUE_TG=$(cd p3-alb-target-groups && terraform output -raw blue_target_group_name)
GREEN_TG=$(cd p3-alb-target-groups && terraform output -raw green_target_group_name)
PROD_LISTENER=$(cd p3-alb-target-groups && terraform output -raw prod_listener_arn)
TEST_LISTENER=$(cd p3-alb-target-groups && terraform output -raw test_listener_arn)
ROLE_ARN=$(aws iam get-role --role-name python-app-dev-codedeploy-role --query 'Role.Arn' --output text)

# Crear deployment group (ver setup-codedeploy.sh para configuración completa)
```

## 🔄 Flujo de Deployment Blue/Green

```
1. CodeBuild construye nueva imagen
   ├── Ejecuta tests
   ├── Construye Docker image
   ├── Push a ECR
   └── Genera artefactos (appspec.json, taskdef.json)

2. CodeDeploy inicia deployment
   ├── Crea nueva Task Definition con nueva imagen
   ├── Despliega en Green environment
   └── Espera health checks

3. Traffic Shifting
   ├── Test traffic → Green (puerto 8080)
   ├── Validación automática
   └── Production traffic → Green (puerto 80)

4. Terminación
   ├── Blue environment se mantiene 5 minutos
   └── Blue tasks son terminadas automáticamente
```

## 🎯 Estrategias de Deployment

### CodeDeployDefault.ECSAllAtOnce (Por defecto)
- Cambia todo el tráfico de una vez
- Más rápido pero mayor riesgo
- Recomendado para dev/staging

### CodeDeployDefault.ECSLinear10PercentEvery1Minutes
- Incrementa tráfico 10% cada minuto
- 10 minutos para completar
- Mayor control y seguridad

### CodeDeployDefault.ECSCanary10Percent5Minutes
- 10% del tráfico por 5 minutos
- Luego 90% restante si todo está bien
- Ideal para producción

## 📊 Verificación del Deployment

### Durante el Deployment

```bash
# Ver status del deployment
aws deploy get-deployment \
    --deployment-id <deployment-id> \
    --region us-east-1

# Ver tasks en el cluster
aws ecs list-tasks \
    --cluster python-app-dev-cluster \
    --region us-east-1

# Ver target health
aws elbv2 describe-target-health \
    --target-group-arn <blue-tg-arn> \
    --region us-east-1
```

### Endpoints para Pruebas

```bash
# Production (puerto 80)
curl http://<alb-dns>/ping

# Test (puerto 8080) - durante deployment
curl http://<alb-dns>:8080/ping
```

## 🔧 Configuración de CodePipeline

Para automatizar el proceso completo, necesitas crear un CodePipeline con:

1. **Source**: GitHub o CodeCommit
2. **Build**: CodeBuild (usa buildspec.yml)
3. **Deploy**: CodeDeploy (usa appspec.json y taskdef.json)

## ⚠️ Troubleshooting

### Error: Task fails health check
- Verificar que el endpoint `/ping` responda 200
- Revisar logs: `aws logs tail /ecs/python-app-dev --follow`
- Verificar security groups permiten tráfico en puerto 5000

### Error: Deployment timeout
- Aumentar `startPeriod` en health check (actualmente 60s)
- Verificar que la imagen se construyó correctamente
- Revisar que RDS esté accesible

### Error: Role not authorized
- Verificar que CodeDeploy role tiene política `AWSCodeDeployRoleForECS`
- Verificar trust policy del role

## 📝 Variables de Entorno

El `taskdef.json` incluye las siguientes variables:

- `DB_USER`: Usuario de PostgreSQL
- `DB_PASSWORD`: Contraseña de PostgreSQL
- `DB_NAME`: Nombre de la base de datos
- `DB_HOST`: Endpoint de RDS
- `DB_PORT`: Puerto de PostgreSQL (5432)

**⚠️ Seguridad**: En producción, usar AWS Secrets Manager o Parameter Store para credenciales.

## 🎨 Próximos Pasos

1. ✅ Ejecutar `./setup-codedeploy.sh`
2. ⏳ Configurar CodePipeline (Actividad 6)
3. ⏳ Hacer un cambio en el código
4. ⏳ Probar deployment automático
5. ⏳ Verificar Blue/Green deployment funciona

## 📚 Referencias

- [AWS CodeDeploy ECS Blue/Green](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-ecs.html)
- [AppSpec Reference](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-resources.html)
- [ECS Task Definition Parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)
