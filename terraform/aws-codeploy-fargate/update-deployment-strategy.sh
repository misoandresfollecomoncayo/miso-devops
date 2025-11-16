#!/bin/bash

echo "[INFO] Actualizando estrategia de despliegue Blue/Green..."
echo ""

# Opciones disponibles:
# - CodeDeployDefault.ECSAllAtOnce (actual)
# - CodeDeployDefault.ECSLinear10PercentEvery1Minutes
# - CodeDeployDefault.ECSLinear10PercentEvery3Minutes  
# - CodeDeployDefault.ECSCanary10Percent5Minutes
# - CodeDeployDefault.ECSCanary10Percent15Minutes

STRATEGY="CodeDeployDefault.ECSCanary10Percent5Minutes"

echo "Nueva estrategia: $STRATEGY"
echo "  - Despliega 10% del tráfico inmediatamente"
echo "  - Espera 5 minutos"
echo "  - Si no hay errores, despliega el 90% restante"
echo ""

aws deploy update-deployment-group \
  --application-name python-app-dev-app \
  --current-deployment-group-name python-app-dev-dg \
  --deployment-config-name "$STRATEGY" \
  --region us-east-1

if [ $? -eq 0 ]; then
  echo ""
  echo "[OK] Estrategia actualizada exitosamente"
  echo ""
  echo "Verificando:"
  aws deploy get-deployment-group \
    --application-name python-app-dev-app \
    --deployment-group-name python-app-dev-dg \
    --region us-east-1 \
    --query 'deploymentGroupInfo.deploymentConfigName' \
    --output text
else
  echo "[ERROR] Error actualizando estrategia"
fi
