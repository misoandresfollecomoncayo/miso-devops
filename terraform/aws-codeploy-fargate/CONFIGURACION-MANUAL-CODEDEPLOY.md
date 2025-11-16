# Configuración Manual de CodeDeploy

## ⚠️ Problema

El deployment group de CodeDeploy no se creó correctamente con el script automático.

## ✅ Solución: Configuración Manual en AWS Console

### Paso 1: Ir a CodeDeploy

1. Abre la consola de AWS: https://console.aws.amazon.com/codesuite/codedeploy/applications
2. Región: **us-east-1**

### Paso 2: Verificar la Aplicación

1. Busca la aplicación: **python-app-dev-app**
2. Si no existe, créala:
   - Click "Create application"
   - Application name: `python-app-dev-app`
   - Compute platform: **Amazon ECS**
   - Click "Create application"

### Paso 3: Crear Deployment Group

1. Dentro de la aplicación `python-app-dev-app`, click "Create deployment group"

2. **Deployment group name**: `python-app-dev-dg`

3. **Service role**: Selecciona `python-app-dev-codedeploy-role`
   - ARN: `arn:aws:iam::148342400171:role/python-app-dev-codedeploy-role`

4. **Environment configuration**:
   - Choose ECS cluster: `python-app-dev-cluster`
   - Choose ECS service name: `python-app-dev-service`

5. **Load balancer**:
   - Choose load balancer: Selecciona el ALB que empieza con `python-app-dev-alb`
   
   - **Production listener port**: 
     - HTTP: 80
     - Target group 1: `python-app-dev-blue-tg`
     - Target group 2: `python-app-dev-green-tg`
   
   - **Test listener port (optional)**:
     - HTTP: 8080
     - Target group 1: `python-app-dev-blue-tg`
     - Target group 2: `python-app-dev-green-tg`

6. **Deployment settings**:
   - Deployment configuration: `CodeDeployDefault.ECSAllAtOnce`
   - (Puedes cambiarlo después a Canary o Linear)

7. **Advanced (optional)**:
   - Reroute traffic immediately: ✅ Checked
   - Terminate original instances: ✅ Checked
   - Wait time: `5` minutes

8. Click "**Create deployment group**"

### Paso 4: Verificar

1. El deployment group `python-app-dev-dg` debe aparecer como "Active"
2. Verifica que muestre:
   - ECS Cluster: python-app-dev-cluster
   - ECS Service: python-app-dev-service
   - Load Balancer configurado

## 🚀 Después de Crear el Deployment Group

### Opción 1: Usar la Consola de AWS

Puedes crear el CodePipeline desde la consola:

1. Ve a CodePipeline: https://console.aws.amazon.com/codesuite/codepipeline/pipelines
2. Click "Create pipeline"
3. Pipeline name: `python-app-dev-pipeline`
4. Service role: Create new role
5. **Source stage**:
   - Source provider: GitHub (Version 2) o GitHub (Version 1)
   - Repository: `ecruzs-uniandes/miso-devops`
   - Branch: `main`
   - Detection: Webhooks
6. **Build stage**:
   - Build provider: AWS CodeBuild
   - Project name: Crear nuevo proyecto `python-app-dev-build`
   - Environment image: Managed image
   - Operating system: Ubuntu
   - Runtime: Standard
   - Image: aws/codebuild/standard:7.0
   - Privileged: ✅ Enabled (para Docker)
   - Buildspec: Use buildspec file (`buildspec.yml`)
7. **Deploy stage**:
   - Deploy provider: Amazon ECS (Blue/Green)
   - Application name: `python-app-dev-app`
   - Deployment group: `python-app-dev-dg`
   - Task Definition: buildspec artifact → `taskdef.json`
   - AppSpec file: buildspec artifact → `appspec.json`
   - Image details: buildspec artifact → `imagedefinitions.json`
8. Review y Create pipeline

### Opción 2: Usar Terraform (Recomendado)

Una vez el deployment group esté creado manualmente:

```bash
cd terraform/aws-codeploy-fargate/p5-codepipeline

# Configurar GitHub token
./setup-github-token.sh

# Desplegar pipeline
terraform init
terraform plan
terraform apply
```

## ✅ Probar el Pipeline

Después de crear el pipeline:

```bash
cd /Users/usuari/Documents/Uniandes_temp/miso-devops

# Hacer un cambio
echo "# Testing Pipeline" >> README.md

# Commit y push
git add .
git commit -m "test: Trigger CodePipeline"
git push origin main
```

El pipeline se ejecutará automáticamente (~10-15 minutos).

## 📋 Valores de Referencia

```
AWS Region: us-east-1
Account ID: 148342400171

CodeDeploy:
- Application: python-app-dev-app
- Deployment Group: python-app-dev-dg
- Service Role: python-app-dev-codedeploy-role

ECS:
- Cluster: python-app-dev-cluster
- Service: python-app-dev-service

ALB:
- Name: python-app-dev-alb
- Blue TG: python-app-dev-blue-tg
- Green TG: python-app-dev-green-tg
- Prod Listener: port 80
- Test Listener: port 8080

GitHub:
- Repo: ecruzs-uniandes/miso-devops
- Branch: main

ECR:
- Repository: 148342400171.dkr.ecr.us-east-1.amazonaws.com/python-app-dev
```

## 🔍 Troubleshooting

### Error: "Service role does not have permissions"

El role ya tiene los permisos correctos. Espera 1-2 minutos después de crear el role para que AWS propague los permisos.

### Error: "Load balancer not found"

Asegúrate de seleccionar el ALB correcto que comienza con `python-app-dev-alb`.

### No aparece el target group

Los target groups deben estar en la misma región (us-east-1) y asociados al ALB.
