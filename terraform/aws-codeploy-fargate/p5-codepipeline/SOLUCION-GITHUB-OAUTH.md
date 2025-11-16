# 🔧 Solución: Error de Conexión GitHub

## ⚠️ Problema

```
Unable to connect to the GitHub repository ecruzs-uniandes/miso-devops.
Use the console to reconnect your pipeline to GitHub.
```

**Causa**: GitHub depreció el soporte para OAuth v1 usado por el provider `ThirdParty`. AWS recomienda usar **CodeStar Connections** (GitHub Version 2).

## ✅ Solución Rápida: Usar AWS Console

### Opción 1: Reconectar en la Consola (Más Rápido)

1. **Abre el pipeline**:
   ```
   https://console.aws.amazon.com/codesuite/codepipeline/pipelines/python-app-dev-pipeline/view?region=us-east-1
   ```

2. **Edita el Source Stage**:
   - Click en "Edit" (arriba a la derecha)
   - Click en "Edit" en el stage "Source"

3. **Reconecta GitHub**:
   - Verás un botón "Connect to GitHub" o "Reconnect"
   - Click en el botón
   - Autoriza la aplicación AWS CodePipeline en GitHub
   - Selecciona el repositorio: `ecruzs-uniandes/miso-devops`
   - Branch: `main`

4. **Guarda los cambios**:
   - Click "Done"
   - Click "Save"

5. **Ejecuta el pipeline**:
   - Click "Release change"

### Opción 2: Migrar a CodeStar Connections (Recomendado)

Esta es la solución moderna y recomendada por AWS.

#### Paso 1: Crear CodeStar Connection

```bash
# En la terminal
aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name python-app-dev-github \
  --region us-east-1
```

**Importante**: La conexión se creará en estado `PENDING`. Debes completar el handshake:

1. Ve a CodeStar Connections: https://console.aws.amazon.com/codesuite/settings/connections?region=us-east-1
2. Busca la conexión `python-app-dev-github`
3. Click en "Update pending connection"
4. Sigue el flujo de autorización de GitHub
5. Verifica que el estado cambie a `AVAILABLE`

#### Paso 2: Actualizar Terraform

Modifica `terraform/aws-codeploy-fargate/p5-codepipeline/main.tf`:

```hcl
# Agregar data source para CodeStar Connection
data "aws_codestar_connections_connection" "github" {
  name = "python-app-dev-github"
}

# Actualizar el Source stage en aws_codepipeline
stage {
  name = "Source"

  action {
    name             = "Source"
    category         = "Source"
    owner            = "AWS"                    # Cambiar de ThirdParty a AWS
    provider         = "CodeStarSourceConnection" # Cambiar provider
    version          = "1"
    output_artifacts = ["source_output"]

    configuration = {
      ConnectionArn    = data.aws_codestar_connections_connection.github.arn
      FullRepositoryId = var.github_repo       # "ecruzs-uniandes/miso-devops"
      BranchName       = var.github_branch     # "main"
      DetectChanges    = true                  # Webhook automático
    }
  }
}
```

**Actualizar IAM policy para CodePipeline**:

```hcl
# En aws_iam_role_policy "codepipeline", agregar:
{
  Effect = "Allow"
  Action = [
    "codestar-connections:UseConnection"
  ]
  Resource = data.aws_codestar_connections_connection.github.arn
}
```

#### Paso 3: Aplicar cambios

```bash
cd terraform/aws-codeploy-fargate/p5-codepipeline

# Verificar cambios
terraform plan

# Aplicar
terraform apply
```

## 🚀 Después de Solucionar

### Probar el Pipeline

```bash
cd /Users/usuari/Documents/Uniandes_temp/miso-devops

# Hacer un cambio
echo "# Pipeline funcionando" >> README.md

# Commit y push
git add .
git commit -m "test: Verificar pipeline automático"
git push origin main
```

**Con CodeStar Connections**, el webhook se configura automáticamente y el pipeline se disparará en ~30 segundos.

### Monitorear

```bash
# Ver estado del pipeline
aws codepipeline get-pipeline-state \
  --name python-app-dev-pipeline \
  --region us-east-1 \
  --query 'stageStates[*].[stageName,latestExecution.status]' \
  --output table

# Ver logs de CodeBuild (si la etapa Build está corriendo)
aws logs tail /aws/codebuild/python-app-dev --follow

# Abrir en navegador
open "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/python-app-dev-pipeline/view?region=us-east-1"
```

## 📋 Comparación de Opciones

| Característica | ThirdParty GitHub | CodeStar Connections |
|---|---|---|
| **Estado** | ⚠️ Deprecado | ✅ Recomendado |
| **Webhook automático** | ❌ No | ✅ Sí |
| **Setup inicial** | Simple | Requiere handshake |
| **Seguridad** | OAuth Token | AWS IAM |
| **Soporte futuro** | No garantizado | Soporte completo |

## 🔍 Verificación

### Comprobar que el pipeline funciona:

```bash
# Estado del último pipeline execution
aws codepipeline list-pipeline-executions \
  --pipeline-name python-app-dev-pipeline \
  --region us-east-1 \
  --max-items 1

# Ver deployments de CodeDeploy
aws deploy list-deployments \
  --application-name python-app-dev-app \
  --deployment-group-name python-app-dev-dg \
  --region us-east-1 \
  --max-items 5

# Verificar aplicación
curl http://python-app-dev-alb-1545946443.us-east-1.elb.amazonaws.com/ping
```

## 💡 Notas Importantes

1. **GitHub Personal Access Token**: Si usas Opción 1 (reconectar), el token debe tener permisos:
   - `repo` (full control)
   - `admin:repo_hook` (manage webhooks)

2. **CodeStar Connections**: Más seguro porque usa AWS IAM en lugar de tokens de larga duración.

3. **Webhooks**: Con CodeStar Connections, AWS crea y gestiona el webhook automáticamente en tu repo de GitHub.

4. **Rate Limits**: CodeStar Connections tiene mejores límites de rate que OAuth.

## 🆘 Troubleshooting

### Error: "Connection is in PENDING state"

La conexión de CodeStar necesita autorización manual:
1. Ve a: https://console.aws.amazon.com/codesuite/settings/connections?region=us-east-1
2. Click en "Update pending connection"
3. Autoriza en GitHub

### Error: "Permission denied to repository"

El usuario de GitHub que autoriza debe tener permisos de **admin** en el repositorio.

### Pipeline no se dispara automáticamente

Verifica:
```bash
# Para CodeStar Connections, debe ser true
aws codepipeline get-pipeline --name python-app-dev-pipeline --region us-east-1 \
  | jq -r '.pipeline.stages[0].actions[0].configuration.DetectChanges'
```

### Ver webhooks en GitHub

1. Ve a tu repositorio: https://github.com/ecruzs-uniandes/miso-devops
2. Settings → Webhooks
3. Debe aparecer uno de AWS CodePipeline
