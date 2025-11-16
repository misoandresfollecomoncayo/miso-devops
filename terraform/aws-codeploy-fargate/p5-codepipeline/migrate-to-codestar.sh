#!/bin/bash

set -e

echo "[INFO] Migrando CodePipeline a CodeStar Connection..."
echo ""

# Verificar que la conexión esté AVAILABLE
CONNECTION_ARN=$(aws codestar-connections list-connections \
  --provider-type-filter GitHub \
  --region us-east-1 \
  --query "Connections[?ConnectionName=='python-app-dev-github'].ConnectionArn | [0]" \
  --output text)

if [ -z "$CONNECTION_ARN" ]; then
  echo "[ERROR] No se encontró la conexión python-app-dev-github"
  echo "Ejecuta primero: ./setup-codestar-connection.sh"
  exit 1
fi

STATUS=$(aws codestar-connections get-connection \
  --connection-arn "$CONNECTION_ARN" \
  --region us-east-1 \
  --query 'Connection.ConnectionStatus' \
  --output text)

echo "[STATUS] Estado de conexión: $STATUS"

if [ "$STATUS" != "AVAILABLE" ]; then
  echo ""
  echo "[ERROR] La conexión NO está disponible (estado: $STATUS)"
  echo ""
  echo "Debes autorizarla primero:"
  echo "1. Abre: https://console.aws.amazon.com/codesuite/settings/connections?region=us-east-1"
  echo "2. Click en 'Update pending connection' para python-app-dev-github"
  echo "3. Autoriza en GitHub"
  echo "4. Vuelve a ejecutar este script"
  exit 1
fi

echo "[DONE] Conexión DISPONIBLE"
echo ""
echo "📝 Connection ARN: $CONNECTION_ARN"
echo ""

# Crear backup del main.tf original
echo "💾 Creando backup..."
cp main.tf main.tf.backup-oauth
echo "[DONE] Backup creado: main.tf.backup-oauth"
echo ""

# Actualizar main.tf
echo "🔧 Actualizando main.tf..."

# Eliminar el data source del token de GitHub (ya no se necesita)
sed -i '' '/^data "aws_secretsmanager_secret" "github_token"/,/^}/d' main.tf
sed -i '' '/^data "aws_secretsmanager_secret_version" "github_token"/,/^}/d' main.tf

# Agregar data source para CodeStar Connection después del data de región
sed -i '' "/^data \"aws_region\" \"current\" {}/a\\
\\
# CodeStar Connection para GitHub\\
data \"aws_codestar_connections_connection\" \"github\" {\\
  name = \"python-app-dev-github\"\\
}
" main.tf

# Reemplazar el Source stage (líneas del stage completo)
# Buscar desde "stage {" con name = "Source" hasta el siguiente "stage {"
cat > /tmp/new_source_stage.txt << 'EOFSTAGE'
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestar_connections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
        DetectChanges    = true
      }
    }
  }
EOFSTAGE

# Usar perl para reemplazar el bloque completo del Source stage
perl -i -0pe 's/  stage \{\s*name = "Source".*?\n  \}/`cat \/tmp\/new_source_stage.txt`/se' main.tf

# Actualizar el IAM policy para incluir CodeStar Connections
# Buscar el policy de codepipeline y agregar el permiso
if ! grep -q "codestar-connections:UseConnection" main.tf; then
  # Agregar el permiso después del bloque de CodeDeploy
  sed -i '' '/codedeploy:RegisterApplicationRevision/a\
      },\
      {\
        Effect = "Allow"\
        Action = [\
          "codestar-connections:UseConnection"\
        ]\
        Resource = data.aws_codestar_connections_connection.github.arn
' main.tf
fi

echo "[DONE] main.tf actualizado"
echo ""

# Mostrar los cambios
echo "📋 Verificando cambios..."
echo ""
if grep -q "CodeStarSourceConnection" main.tf; then
  echo "[DONE] Source provider actualizado a CodeStarSourceConnection"
else
  echo "[ERROR] Error: No se actualizó el provider"
  exit 1
fi

if grep -q "codestar-connections:UseConnection" main.tf; then
  echo "[DONE] Permisos de IAM actualizados"
else
  echo "[WARNING]  Advertencia: No se encontraron los permisos IAM"
fi

echo ""
echo "[START] Cambios completados. Próximos pasos:"
echo ""
echo "1. Revisar cambios:"
echo "   git diff main.tf"
echo ""
echo "2. Aplicar con Terraform:"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "3. El pipeline se activará automáticamente con webhooks"
echo ""
echo "Para restaurar el backup en caso de error:"
echo "   cp main.tf.backup-oauth main.tf"
