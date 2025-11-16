#!/bin/bash
# ============================================
# Script para recrear servicio ECS sin CodeDeploy
# ============================================
# [WARNING] SOLO PARA DESARROLLO/TESTING
# Este script elimina y recrea el servicio con deployment controller ECS
# (en lugar de CODE_DEPLOY) para poder actualizarlo directamente.

set -e  # Salir si hay error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}================================================${NC}"
echo -e "${RED}  [WARNING]  RECREAR SERVICIO SIN CODEDEPLOY${NC}"
echo -e "${RED}================================================${NC}"
echo -e "${YELLOW}Este script es SOLO para desarrollo/testing${NC}"
echo -e "${YELLOW}Eliminará el servicio actual y lo recreará sin CodeDeploy${NC}\n"

# Variables
REGION="us-east-1"
CLUSTER_NAME="python-app-dev-cluster"
SERVICE_NAME="python-app-dev-service"

# Confirmación
read -p "¿Estás seguro de continuar? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Operación cancelada"
  exit 0
fi

# Paso 1: Escalar servicio a 0
echo -e "\n${BLUE}[1/5] Escalando servicio a 0...${NC}"
aws ecs update-service \
  --cluster ${CLUSTER_NAME} \
  --service ${SERVICE_NAME} \
  --desired-count 0 \
  --region ${REGION} \
  --query 'service.{Name:serviceName,DesiredCount:desiredCount}' \
  --output table 2>/dev/null || true

sleep 5

# Paso 2: Eliminar servicio
echo -e "\n${BLUE}[2/5] Eliminando servicio...${NC}"
aws ecs delete-service \
  --cluster ${CLUSTER_NAME} \
  --service ${SERVICE_NAME} \
  --region ${REGION} \
  --force >/dev/null 2>&1 || true

echo -e "${GREEN}[OK] Servicio eliminado${NC}"
echo -e "${YELLOW}Esperando 30 segundos para que se complete la eliminación...${NC}"
sleep 30

# Paso 3: Obtener información necesaria
echo -e "\n${BLUE}[3/5] Obteniendo información de configuración...${NC}"

# Obtener última Task Definition
TASK_DEF=$(aws ecs list-task-definitions \
  --family-prefix python-app-dev \
  --sort DESC \
  --max-items 1 \
  --region ${REGION} \
  --query 'taskDefinitionArns[0]' \
  --output text)

echo "Task Definition: ${TASK_DEF}"

# Obtener Target Group Blue
TG_BLUE_ARN=$(aws elbv2 describe-target-groups \
  --names python-app-dev-blue-tg \
  --region ${REGION} \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group Blue: ${TG_BLUE_ARN}"

# Obtener VPC y Subnets
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=python-app-dev-vpc" \
  --region ${REGION} \
  --query 'Vpcs[0].VpcId' \
  --output text)

SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${VPC_ID}" "Name=tag:Type,Values=Public" \
  --region ${REGION} \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=python-app-dev-ecs-tasks-sg" "Name=vpc-id,Values=${VPC_ID}" \
  --region ${REGION} \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "Subnets: ${SUBNET_IDS}"
echo "Security Group: ${SG_ID}"

# Paso 4: Crear nuevo servicio sin CodeDeploy
echo -e "\n${BLUE}[4/5] Creando nuevo servicio (ECS deployment controller)...${NC}"

aws ecs create-service \
  --cluster ${CLUSTER_NAME} \
  --service-name ${SERVICE_NAME} \
  --task-definition ${TASK_DEF} \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SG_ID}],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=${TG_BLUE_ARN},containerName=python-app,containerPort=5000" \
  --deployment-controller type=ECS \
  --region ${REGION} \
  --query 'service.{Name:serviceName,Status:status,DesiredCount:desiredCount}' \
  --output table

echo -e "${GREEN}[OK] Servicio creado${NC}"

# Paso 5: Esperar a que esté estable
echo -e "\n${BLUE}[5/5] Esperando a que el servicio esté estable...${NC}"
echo -e "${YELLOW}Esto puede tomar varios minutos...${NC}\n"

aws ecs wait services-stable \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${REGION}

echo -e "\n${GREEN}[OK] Servicio estable${NC}"

# Mostrar estado final
echo -e "\n${BLUE}Estado del servicio:${NC}"
aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${REGION} \
  --query 'services[0].{Name:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount,DeploymentController:deploymentController.type}' \
  --output table

# Obtener URL
ALB_URL=$(aws elbv2 describe-load-balancers \
  --names python-app-dev-alb \
  --region ${REGION} \
  --query 'LoadBalancers[0].DNSName' \
  --output text 2>/dev/null || echo "No disponible")

# Resumen final
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  [OK] Servicio recreado exitosamente${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\nDeployment Controller: ${YELLOW}ECS${NC} (ya no es CODE_DEPLOY)"
echo -e "\nAhora puedes actualizar directamente con:"
echo -e "  ${BLUE}./update-service.sh${NC}\n"
echo -e "Accede a tu aplicación en:"
echo -e "  http://${ALB_URL}\n"
