#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  🚀 Solución Pipeline - Migración a CodeStar Connection      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Paso 1: Verificar estado de la conexión
echo "📡 Paso 1: Verificando conexión CodeStar..."
echo ""

CONNECTION_ARN=$(aws codestar-connections list-connections \
  --provider-type-filter GitHub \
  --region us-east-1 \
  --query "Connections[?ConnectionName=='python-app-dev-github'].ConnectionArn | [0]" \
  --output text 2>/dev/null)

if [ -z "$CONNECTION_ARN" ]; then
  echo "❌ No existe conexión. Creándola..."
  ./setup-codestar-connection.sh
  CONNECTION_ARN=$(aws codestar-connections list-connections \
    --provider-type-filter GitHub \
    --region us-east-1 \
    --query "Connections[?ConnectionName=='python-app-dev-github'].ConnectionArn | [0]" \
    --output text)
fi

STATUS=$(aws codestar-connections get-connection \
  --connection-arn "$CONNECTION_ARN" \
  --region us-east-1 \
  --query 'Connection.ConnectionStatus' \
  --output text 2>/dev/null)

echo "Connection ARN: $CONNECTION_ARN"
echo "Estado: $STATUS"
echo ""

if [ "$STATUS" = "PENDING" ]; then
  echo "⚠️  ACCIÓN REQUERIDA: Autorizar conexión en AWS Console"
  echo ""
  echo "┌─────────────────────────────────────────────────────────────┐"
  echo "│  INSTRUCCIONES:                                             │"
  echo "├─────────────────────────────────────────────────────────────┤"
  echo "│                                                             │"
  echo "│  1. Abre esta URL en tu navegador:                         │"
  echo "│     https://console.aws.amazon.com/codesuite/settings/connections?region=us-east-1"
  echo "│                                                             │"
  echo "│  2. Busca: python-app-dev-github                           │"
  echo "│                                                             │"
  echo "│  3. Click en 'Update pending connection'                   │"
  echo "│                                                             │"
  echo "│  4. Click 'Install a new app' o selecciona tu usuario      │"
  echo "│                                                             │"
  echo "│  5. Autoriza el acceso al repositorio:                     │"
  echo "│     ecruzs-uniandes/miso-devops                            │"
  echo "│                                                             │"
  echo "│  6. Espera a que el estado cambie a 'Available'            │"
  echo "│                                                             │"
  echo "│  7. Vuelve aquí y presiona ENTER para continuar           │"
  echo "│                                                             │"
  echo "└─────────────────────────────────────────────────────────────┘"
  echo ""
  read -p "Presiona ENTER cuando hayas completado la autorización..."
  echo ""
  
  # Verificar nuevamente
  STATUS=$(aws codestar-connections get-connection \
    --connection-arn "$CONNECTION_ARN" \
    --region us-east-1 \
    --query 'Connection.ConnectionStatus' \
    --output text)
  
  if [ "$STATUS" != "AVAILABLE" ]; then
    echo "❌ La conexión aún no está disponible (estado: $STATUS)"
    echo "Por favor completa la autorización y ejecuta el script nuevamente"
    exit 1
  fi
fi

echo "✅ Conexión disponible y lista"
echo ""

# Paso 2: Migrar Terraform
echo "📡 Paso 2: Migrando configuración de Terraform..."
echo ""

./migrate-to-codestar.sh

if [ $? -ne 0 ]; then
  echo "❌ Error en migración"
  exit 1
fi

echo ""

# Paso 3: Aplicar Terraform
echo "📡 Paso 3: Aplicando cambios con Terraform..."
echo ""

terraform plan -out=tfplan

echo ""
read -p "¿Aplicar los cambios? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  terraform apply tfplan
  rm tfplan
  
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ✅ MIGRACIÓN COMPLETADA                                      ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "🎉 El pipeline ahora usa CodeStar Connection"
  echo ""
  echo "🚀 Próximos pasos:"
  echo ""
  echo "1. Hacer un commit para probar:"
  echo "   cd /Users/usuari/Documents/Uniandes_temp/miso-devops"
  echo "   echo '# Test' >> README.md"
  echo "   git add . && git commit -m 'test: Pipeline' && git push"
  echo ""
  echo "2. El pipeline se ejecutará automáticamente (~30 seg)"
  echo ""
  echo "3. Monitorear:"
  echo "   aws codepipeline get-pipeline-state --name python-app-dev-pipeline --region us-east-1"
  echo ""
  echo "4. Ver en consola:"
  echo "   https://console.aws.amazon.com/codesuite/codepipeline/pipelines/python-app-dev-pipeline/view?region=us-east-1"
  echo ""
else
  echo "Cancelado. Para aplicar manualmente:"
  echo "  terraform apply tfplan"
  rm tfplan
fi
