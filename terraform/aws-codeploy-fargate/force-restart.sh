#!/bin/bash

# Script para forzar restart de tareas ECS cuando usa CODE_DEPLOY

CLUSTER="python-app-dev-cluster"
SERVICE="python-app-dev-service"
REGION="us-east-1"

echo "[INFO] Obteniendo tareas en ejecución..."
TASKS=$(aws ecs list-tasks \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --region "$REGION" \
  --query 'taskArns[]' \
  --output text)

if [ -z "$TASKS" ]; then
  echo "[OK] No hay tareas en ejecución"
  exit 0
fi

echo "🛑 Deteniendo tareas..."
for TASK in $TASKS; do
  echo "  - Deteniendo: $TASK"
  aws ecs stop-task \
    --cluster "$CLUSTER" \
    --task "$TASK" \
    --reason "Forzar restart con nueva imagen" \
    --region "$REGION" \
    --output text > /dev/null 2>&1
done

echo "[OK] Tareas detenidas"
echo ""
echo "⏳ Esperando que el servicio arranque nuevas tareas (esto toma ~30 segundos)..."
sleep 10

for i in {1..6}; do
  RUNNING=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$REGION" \
    --query 'services[0].runningCount' \
    --output text)
  
  PENDING=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$REGION" \
    --query 'services[0].pendingCount' \
    --output text)
  
  echo "  [${i}/6] Running: $RUNNING, Pending: $PENDING"
  
  if [ "$RUNNING" -gt 0 ]; then
    echo ""
    echo "[OK] Nueva tarea en ejecución!"
    echo ""
    echo "[STATUS] Ver logs:"
    echo "   aws logs tail /ecs/python-app-dev --follow --region $REGION"
    exit 0
  fi
  
  sleep 5
done

echo ""
echo "[WARNING]  Las tareas aún no están en estado RUNNING"
echo "   Verifica los logs para más detalles"
echo "   aws logs tail /ecs/python-app-dev --follow --region $REGION"
