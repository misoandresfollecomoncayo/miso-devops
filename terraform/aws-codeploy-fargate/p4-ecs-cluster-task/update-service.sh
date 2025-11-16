#!/bin/bash
# ============================================
# Script para actualizar Task Definition con nueva imagen
# ============================================
# Este script solo actualiza la Task Definition.
# Para servicios con CODE_DEPLOY, usa CodeDeploy para desplegar.
# Para servicios con ECS deployment controller, usa update-service-ecs.sh

set -e  # Salir si hay error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Actualizar Servicio ECS con Nueva Imagen${NC}"
echo -e "${BLUE}================================================${NC}"

# Variables
REGION="us-east-1"
CLUSTER_NAME="python-app-dev-cluster"
SERVICE_NAME="python-app-dev-service"

echo -e "\n${YELLOW}Configuración:${NC}"
echo "  - Región: ${REGION}"
echo "  - Cluster: ${CLUSTER_NAME}"
echo "  - Servicio: ${SERVICE_NAME}"

# Paso 1: Obtener la Task Definition actual
echo -e "\n${BLUE}[1/4] Obteniendo Task Definition actual...${NC}"
TASK_DEFINITION=$(aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${REGION} \
  --query 'services[0].taskDefinition' \
  --output text)

echo -e "${GREEN}[OK] Task Definition actual: ${TASK_DEFINITION}${NC}"

# Paso 2: Crear nueva revisión de la Task Definition
echo -e "\n${BLUE}[2/4] Creando nueva revisión de Task Definition...${NC}"

# Obtener la definición actual
TASK_DEF_JSON=$(aws ecs describe-task-definition \
  --task-definition ${TASK_DEFINITION} \
  --region ${REGION} \
  --query 'taskDefinition')

# Extraer campos necesarios y crear nueva revisión
NEW_TASK_DEF=$(echo ${TASK_DEF_JSON} | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')

# Registrar nueva Task Definition
NEW_TASK_ARN=$(aws ecs register-task-definition \
  --cli-input-json "${NEW_TASK_DEF}" \
  --region ${REGION} \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo -e "${GREEN}[OK] Nueva Task Definition creada: ${NEW_TASK_ARN}${NC}"

# Paso 3: Verificar deployment controller
echo -e "\n${BLUE}[3/4] Verificando deployment controller...${NC}"
DEPLOYMENT_CONTROLLER=$(aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${REGION} \
  --query 'services[0].deploymentController.type' \
  --output text)

echo -e "${YELLOW}Deployment Controller: ${DEPLOYMENT_CONTROLLER}${NC}"

if [ "${DEPLOYMENT_CONTROLLER}" == "CODE_DEPLOY" ]; then
  echo -e "\n${YELLOW}[WARNING]  El servicio usa CODE_DEPLOY como deployment controller${NC}"
  echo -e "${YELLOW}No se puede actualizar directamente con ECS.${NC}\n"
  
  echo -e "${BLUE}Opciones:${NC}"
  echo -e "  1. Usar AWS CodeDeploy para hacer despliegue Blue/Green"
  echo -e "  2. Recrear el servicio sin CodeDeploy (solo para desarrollo)\n"
  
  echo -e "${GREEN}[OK] Nueva Task Definition creada: ${NEW_TASK_ARN}${NC}"
  echo -e "${BLUE}Esta Task Definition está lista para usar con CodeDeploy${NC}\n"
  
  echo -e "${YELLOW}Para hacer el despliegue, necesitas configurar CodeDeploy primero.${NC}"
  echo -e "${YELLOW}O ejecuta ./recreate-service-without-codedeploy.sh para desarrollo.${NC}\n"
  
  exit 0
fi

# Si no es CODE_DEPLOY, actualizar normalmente
echo -e "\n${BLUE}[4/4] Actualizando servicio ECS...${NC}"
aws ecs update-service \
  --cluster ${CLUSTER_NAME} \
  --service ${SERVICE_NAME} \
  --task-definition ${NEW_TASK_ARN} \
  --force-new-deployment \
  --region ${REGION} \
  --query 'service.{Name:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount}' \
  --output table

echo -e "${GREEN}[OK] Servicio actualizado${NC}"

# Obtener URL del ALB
ALB_URL=$(aws elbv2 describe-load-balancers \
  --names python-app-dev-alb \
  --region ${REGION} \
  --query 'LoadBalancers[0].DNSName' \
  --output text 2>/dev/null || echo "No disponible")

# Resumen final
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  [OK] Task Definition actualizada${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\nNueva Task Definition: ${NEW_TASK_ARN}"
echo -e "\nAccede a tu aplicación en:"
echo -e "  http://${ALB_URL}\n"
