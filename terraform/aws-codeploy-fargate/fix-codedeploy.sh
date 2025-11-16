#!/bin/bash

# Script para recrear el deployment group de CodeDeploy con los listeners correctos

set -e

PROJECT="python-app"
ENV="dev"
REGION="us-east-1"
APP_NAME="${PROJECT}-${ENV}-app"
DG_NAME="${PROJECT}-${ENV}-dg"
CLUSTER_NAME="${PROJECT}-${ENV}-cluster"
SERVICE_NAME="${PROJECT}-${ENV}-service"

# Obtener listeners del ALB actual
echo "[INFO] Obteniendo ARNs de listeners..."
HTTP_LISTENER=$(cd p3-alb-target-groups && terraform state show aws_lb_listener.http | grep "arn.*=" | head -1 | awk '{print $3}' | tr -d '"')
TEST_LISTENER=$(cd p3-alb-target-groups && terraform state show aws_lb_listener.test | grep "arn.*=" | head -1 | awk '{print $3}' | tr -d '"')

echo "HTTP Listener: $HTTP_LISTENER"
echo "Test Listener: $TEST_LISTENER"

# Obtener target groups
BLUE_TG=$(cd p3-alb-target-groups && terraform state show aws_lb_target_group.blue | grep "name.*=" | head -1 | awk '{print $3}' | tr -d '"')
GREEN_TG=$(cd p3-alb-target-groups && terraform state show aws_lb_target_group.green | grep "name.*=" | head -1 | awk '{print $3}' | tr -d '"')

echo "Blue TG: $BLUE_TG"
echo "Green TG: $GREEN_TG"

# Obtener rol de CodeDeploy
CODEDEPLOY_ROLE=$(cd p1-iam-roles && terraform output -raw codedeploy_role_arn)

echo "CodeDeploy Role: $CODEDEPLOY_ROLE"

# Eliminar deployment group existente
echo "[INFO] Eliminando deployment group existente..."
aws deploy delete-deployment-group \
  --application-name "$APP_NAME" \
  --deployment-group-name "$DG_NAME" \
  --region "$REGION" || echo "[WARNING] Deployment group no existe o no se pudo eliminar"

sleep 5

# Crear nuevo deployment group
echo "[INFO] Creando nuevo deployment group..."
aws deploy create-deployment-group \
  --application-name "$APP_NAME" \
  --deployment-group-name "$DG_NAME" \
  --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
  --service-role-arn "$CODEDEPLOY_ROLE" \
  --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE,DEPLOYMENT_STOP_ON_ALARM \
  --blue-green-deployment-configuration "{
    \"terminateBlueInstancesOnDeploymentSuccess\": {
      \"action\": \"TERMINATE\",
      \"terminationWaitTimeInMinutes\": 5
    },
    \"deploymentReadyOption\": {
      \"actionOnTimeout\": \"CONTINUE_DEPLOYMENT\"
    }
  }" \
  --load-balancer-info "{
    \"targetGroupPairInfoList\": [{
      \"targetGroups\": [
        {\"name\": \"$BLUE_TG\"},
        {\"name\": \"$GREEN_TG\"}
      ],
      \"prodTrafficRoute\": {
        \"listenerArns\": [\"$HTTP_LISTENER\"]
      },
      \"testTrafficRoute\": {
        \"listenerArns\": [\"$TEST_LISTENER\"]
      }
    }]
  }" \
  --ecs-services clusterName="$CLUSTER_NAME",serviceName="$SERVICE_NAME" \
  --region "$REGION"

echo "[DONE] Deployment group recreado exitosamente"
echo ""
echo "Verificar en: https://console.aws.amazon.com/codesuite/codedeploy/applications/$APP_NAME/deployment-groups/$DG_NAME?region=$REGION"
