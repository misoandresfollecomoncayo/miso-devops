# Paso 5 - AWS CodePipeline con Blue/Green Deployment

##  Descripción

Este paso configura AWS CodePipeline para automatizar el flujo completo de CI/CD desde GitHub hasta el deployment en ECS Fargate con estrategia Blue/Green.

##  Arquitectura del Pipeline

```
GitHub → CodePipeline → CodeBuild → CodeDeploy → ECS Fargate
   ↓           ↓            ↓            ↓           ↓
 Source    Orchestration  Build&Test  Blue/Green  Running App
```

##  Recursos Creados

- **CodePipeline**: Orquesta todo el flujo de CI/CD
- **CodeBuild Project**: Ejecuta tests, build Docker y push a ECR
- **S3 Bucket**: Almacena artefactos del pipeline
- **IAM Roles**: Permisos para CodePipeline y CodeBuild
- **CloudWatch Logs**: Logs de CodeBuild

##  Etapas del Pipeline

### 1. Source (GitHub)
- Detecta cambios en el repositorio
- Descarga código fuente
- Trigger automático en cada push a `main`

### 2. Build (CodeBuild)
- Ejecuta `buildspec.yml`
- Corre tests con pytest
- Construye imagen Docker
- Push a ECR
- Genera artefactos:
  - `imagedefinitions.json`
  - `appspec.json` (actualizado)
  - `taskdef.json` (con nueva imagen)

### 3. Deploy (CodeDeploy)
- Lee `appspec.json` y `taskdef.json`
- Crea nueva Task Definition
- Inicia deployment Blue/Green
- Realiza health checks
- Cambia tráfico de Blue a Green
- Termina tasks antiguas después de 5 minutos

##  Configuración

### Prerequisitos

1. **GitHub Personal Access Token**
   - Permisos necesarios: `repo`, `admin:repo_hook`
   - [Crear token aquí](https://github.com/settings/tokens)

2. **Pasos anteriores completados**:
   - p1-iam-roles
   - p2-ecr
   - p3-alb-target-groups
   - p3-rds-postgres
   - p4-ecs-cluster-task
   - CodeDeploy configurado (setup-codedeploy.sh)

### Paso 1: Configurar GitHub Token

```bash
cd p5-codepipeline
./setup-github-token.sh
```

Este script:
1. Solicita tu GitHub Personal Access Token
2. Lo almacena en AWS Secrets Manager
3. Nombre del secret: `github-token`

### Paso 2: Revisar terraform.tfvars

```bash
cat terraform.tfvars
```

Verificar valores:
- `github_repo`: "ecruzs-uniandes/miso-devops"
- `github_branch`: "main"
- `ecr_repository_url`: URL de tu ECR
- `codedeploy_app_name`: "python-app-dev-app"
- `ecs_cluster_name`: "python-app-dev-cluster"

### Paso 3: Desplegar con Terraform

```bash
terraform init
terraform plan
terraform apply
```

Tiempo estimado: 2-3 minutos

##  Verificación

### Ver el Pipeline creado

```bash
# Obtener URL de la consola
terraform output console_url

# Ver resumen del pipeline
terraform output pipeline_summary
```

### Probar el Pipeline

1. **Hacer un cambio en el código**:
```bash
# Ejemplo: modificar el mensaje de /ping
vim src/routes.py

# Commit y push
git add .
git commit -m "test: Update ping message"
git push origin main
```

2. **Monitorear en AWS Console**:
   - Ve a CodePipeline
   - Observa las 3 etapas: Source → Build → Deploy
   - Tiempo total: ~10-15 minutos

3. **Ver logs de CodeBuild**:
```bash
aws logs tail /aws/codebuild/python-app-dev --follow
```

4. **Ver deployment de CodeDeploy**:
```bash
aws deploy list-deployments \
    --application-name python-app-dev-app \
    --deployment-group-name python-app-dev-dg \
    --region us-east-1
```

5. **Verificar aplicación**:
```bash
# Production (puerto 80)
curl http://<alb-dns>/ping

# Durante deployment - Test (puerto 8080)
curl http://<alb-dns>:8080/ping
```

##  Variables de Entorno en CodeBuild

El proyecto de CodeBuild incluye estas variables:

- `AWS_DEFAULT_REGION`: us-east-1
- `AWS_ACCOUNT_ID`: Tu account ID
- `ECR_REPO_URI`: URL completa del repositorio ECR
- `IMAGE_REPO_NAME`: Nombre del repositorio
- `IMAGE_TAG`: latest (por defecto)

## 🔍 Troubleshooting

### Error: "Secret not found"
**Problema**: GitHub token no está configurado en Secrets Manager

**Solución**:
```bash
./setup-github-token.sh
```

### Error: "CodeDeploy application not found"
**Problema**: CodeDeploy no está configurado

**Solución**:
```bash
cd ../
./setup-codedeploy.sh
```

### Pipeline falla en Build
**Problema**: Tests fallan o imagen no se construye

**Solución**:
1. Ver logs: `aws logs tail /aws/codebuild/python-app-dev --follow`
2. Verificar que tests pasen localmente: `pytest src/test/test.py`
3. Verificar que Docker build funcione: `docker build .`

### Pipeline falla en Deploy
**Problema**: Health checks fallan o deployment timeout

**Solución**:
1. Verificar que `/ping` responda 200
2. Ver logs del contenedor:
```bash
aws logs tail /ecs/python-app-dev --follow
```
3. Verificar que RDS esté accesible
4. Revisar security groups

### GitHub webhook no se crea
**Problema**: Token no tiene permisos suficientes

**Solución**:
1. Crear nuevo token con permisos: `repo`, `admin:repo_hook`
2. Ejecutar `./setup-github-token.sh` nuevamente
3. Recrear el pipeline: `terraform destroy && terraform apply`

##  Flujo Completo del Deployment

```
1. Developer hace push a main
   ↓
2. GitHub webhook notifica a CodePipeline
   ↓
3. CodePipeline inicia (Source stage)
   ├─ Descarga código de GitHub
   └─ Guarda en S3 artifacts bucket
   ↓
4. Build stage (CodeBuild)
   ├─ Ejecuta pytest
   ├─ Construye imagen Docker (linux/amd64)
   ├─ Tag: <commit-hash>
   ├─ Push a ECR
   ├─ Genera imagedefinitions.json
   ├─ Actualiza taskdef.json con nueva imagen
   └─ Genera artefactos para CodeDeploy
   ↓
5. Deploy stage (CodeDeploy)
   ├─ Lee appspec.json y taskdef.json
   ├─ Crea Task Definition revision nueva
   ├─ Despliega en GREEN environment
   ├─ Health check: http://localhost:5000/ping
   ├─ Espera 60s (startPeriod)
   ├─ Test traffic → GREEN (puerto 8080)
   ├─ Validación automática
   ├─ Production traffic → GREEN (puerto 80)
   ├─ Espera 5 minutos
   └─ Termina BLUE tasks
   ↓
6. Deployment completado
   └─ Nueva versión corriendo sin downtime
```

## 📈 Métricas y Monitoreo

### CloudWatch Metrics

```bash
# Ver métricas del pipeline
aws cloudwatch get-metric-statistics \
    --namespace AWS/CodePipeline \
    --metric-name PipelineExecutionSuccess \
    --dimensions Name=PipelineName,Value=python-app-dev-pipeline \
    --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Sum \
    --region us-east-1
```

### Ver historial de deployments

```bash
aws codepipeline list-pipeline-executions \
    --pipeline-name python-app-dev-pipeline \
    --max-items 5 \
    --region us-east-1
```

##  Seguridad

### Secrets Manager
- GitHub token encriptado en reposo
- Acceso controlado por IAM
- Rotación manual recomendada cada 90 días

### S3 Artifacts
- Versionado habilitado
- Encriptación AES256
- Public access bloqueado
- Lifecycle policy recomendada (eliminar después de 30 días)

### IAM Roles
- Least privilege principle
- Roles separados para Pipeline y Build
- PassRole permissions controladas

##  Rollback

Si un deployment falla, CodeDeploy automáticamente:
1. Detiene el proceso
2. Mantiene BLUE environment activo
3. Todo el tráfico permanece en la versión anterior

Para rollback manual:
```bash
# Listar deployments
aws deploy list-deployments \
    --application-name python-app-dev-app \
    --deployment-group-name python-app-dev-dg \
    --include-only-statuses Failed,Stopped \
    --region us-east-1

# Redeploy versión anterior
aws deploy create-deployment \
    --application-name python-app-dev-app \
    --deployment-group-name python-app-dev-dg \
    --revision revisionType=S3,s3Location={bucket=<bucket>,key=<key>,bundleType=zip} \
    --region us-east-1
```

## 📚 Archivos Importantes

- `main.tf`: Recursos de Terraform
- `variables.tf`: Variables configurables
- `outputs.tf`: Outputs del módulo
- `terraform.tfvars`: Valores específicos
- `setup-github-token.sh`: Script para configurar token
- `README.md`: Esta documentación

## 🎓 Próximos Pasos

1. Hacer un cambio en el código
2. Push a GitHub
3. Ver pipeline ejecutarse automáticamente
4. Verificar deployment Blue/Green
5. ⏳ Configurar notificaciones (SNS)
6. ⏳ Agregar stage de aprobación manual
7. ⏳ Configurar múltiples ambientes (dev, staging, prod)

## 📞 Soporte

Para más información:
- [AWS CodePipeline Docs](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Docs](https://docs.aws.amazon.com/codebuild/)
- [Blue/Green Deployments](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-blue-green.html)
# test
