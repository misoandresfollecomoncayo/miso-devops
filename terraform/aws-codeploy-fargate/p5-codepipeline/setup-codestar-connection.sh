#!/bin/bash

set -e

echo "🔗 Creando CodeStar Connection para GitHub..."

# Crear la conexión
CONNECTION_ARN=$(aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name python-app-dev-github \
  --region us-east-1 \
  --query 'ConnectionArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$CONNECTION_ARN" ]; then
  echo "❌ Error creando conexión o ya existe"
  
  # Verificar si ya existe
  CONNECTION_ARN=$(aws codestar-connections list-connections \
    --provider-type-filter GitHub \
    --region us-east-1 \
    --query "Connections[?ConnectionName=='python-app-dev-github'].ConnectionArn | [0]" \
    --output text)
  
  if [ -z "$CONNECTION_ARN" ]; then
    echo "❌ No se pudo obtener la conexión"
    exit 1
  fi
  
  echo "✅ Usando conexión existente"
fi

echo ""
echo "📋 Connection ARN: $CONNECTION_ARN"
echo ""

# Verificar el estado
STATUS=$(aws codestar-connections get-connection \
  --connection-arn "$CONNECTION_ARN" \
  --region us-east-1 \
  --query 'Connection.ConnectionStatus' \
  --output text)

echo "📊 Estado actual: $STATUS"
echo ""

if [ "$STATUS" = "PENDING" ]; then
  echo "⚠️  La conexión está en estado PENDING"
  echo ""
  echo "🔧 ACCIÓN REQUERIDA:"
  echo "1. Abre esta URL:"
  echo "   https://console.aws.amazon.com/codesuite/settings/connections?region=us-east-1"
  echo ""
  echo "2. Busca: python-app-dev-github"
  echo ""
  echo "3. Click en 'Update pending connection'"
  echo ""
  echo "4. Autoriza en GitHub (necesitas permisos de admin en el repo)"
  echo ""
  echo "5. Verifica que el estado cambie a AVAILABLE"
  echo ""
  echo "6. Vuelve a ejecutar este script para continuar"
  exit 0
fi

if [ "$STATUS" = "AVAILABLE" ]; then
  echo "✅ La conexión está DISPONIBLE"
  echo ""
  echo "📝 Guarda este ARN para actualizar Terraform:"
  echo "   $CONNECTION_ARN"
  echo ""
  echo "🚀 Próximo paso: Actualizar main.tf para usar CodeStar Connection"
else
  echo "⚠️  Estado inesperado: $STATUS"
  exit 1
fi
