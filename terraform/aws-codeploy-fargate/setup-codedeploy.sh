#!/bin/bash

# ============================================
# Script para configurar AWS CodeDeploy
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="python-app"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Verificar prerequisitos
log "Verificando prerequisitos..."

# Obtener información de ECS
log "Obteniendo información de ECS..."
cd "${SCRIPT_DIR}/p4-ecs-cluster-task"
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null) || error "No se pudo obtener cluster_name"
SERVICE_NAME=$(terraform output -raw service_name 2>/dev/null) || error "No se pudo obtener service_name"

cd "${SCRIPT_DIR}/p3-alb-target-groups"
BLUE_TG_NAME=$(terraform output -raw blue_target_group_name 2>/dev/null) || error "No se pudo obtener blue_target_group_name"
GREEN_TG_NAME=$(terraform output -raw green_target_group_name 2>/dev/null) || error "No se pudo obtener green_target_group_name"
PROD_LISTENER_ARN=$(terraform output -raw http_listener_arn 2>/dev/null) || error "No se pudo obtener http_listener_arn"
TEST_LISTENER_ARN=$(terraform output -raw test_listener_arn 2>/dev/null) || error "No se pudo obtener test_listener_arn"

log "[OK] Cluster: $CLUSTER_NAME"
log "[OK] Service: $SERVICE_NAME"
log "[OK] Blue TG: $BLUE_TG_NAME"
log "[OK] Green TG: $GREEN_TG_NAME"

# Crear CodeDeploy Application
log "Creando CodeDeploy Application..."
aws deploy create-application \
    --application-name "${PROJECT_NAME}-${ENVIRONMENT}-app" \
    --compute-platform ECS \
    --region $AWS_REGION \
    2>/dev/null || log "Application ya existe"

# Crear Service Role para CodeDeploy
log "Creando IAM Role para CodeDeploy..."
ROLE_NAME="${PROJECT_NAME}-${ENVIRONMENT}-codedeploy-role"

# Verificar si el rol ya existe
if aws iam get-role --role-name $ROLE_NAME --region $AWS_REGION 2>/dev/null; then
    log "[OK] Role $ROLE_NAME ya existe"
else
    # Crear trust policy
    cat > /tmp/codedeploy-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/codedeploy-trust-policy.json \
        --region $AWS_REGION

    # Attach managed policy
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS \
        --region $AWS_REGION

    log "[OK] Role creado"
fi

# Obtener ARN del rol
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text --region $AWS_REGION)
log "[OK] Role ARN: $ROLE_ARN"

# Esperar a que el rol esté disponible
sleep 5

# Crear Deployment Group
log "Creando Deployment Group..."

cat > /tmp/deployment-group-config.json << EOF
{
  "applicationName": "${PROJECT_NAME}-${ENVIRONMENT}-app",
  "deploymentGroupName": "${PROJECT_NAME}-${ENVIRONMENT}-dg",
  "serviceRoleArn": "$ROLE_ARN",
  "deploymentConfigName": "CodeDeployDefault.ECSAllAtOnce",
  "ecsServices": [
    {
      "serviceName": "$SERVICE_NAME",
      "clusterName": "$CLUSTER_NAME"
    }
  ],
  "loadBalancerInfo": {
    "targetGroupPairInfoList": [
      {
        "targetGroups": [
          {
            "name": "$BLUE_TG_NAME"
          },
          {
            "name": "$GREEN_TG_NAME"
          }
        ],
        "prodTrafficRoute": {
          "listenerArns": [
            "$PROD_LISTENER_ARN"
          ]
        },
        "testTrafficRoute": {
          "listenerArns": [
            "$TEST_LISTENER_ARN"
          ]
        }
      }
    ]
  },
  "blueGreenDeploymentConfiguration": {
    "terminateBlueInstancesOnDeploymentSuccess": {
      "action": "TERMINATE",
      "terminationWaitTimeInMinutes": 5
    },
    "deploymentReadyOption": {
      "actionOnTimeout": "CONTINUE_DEPLOYMENT"
    }
  },
  "deploymentStyle": {
    "deploymentType": "BLUE_GREEN",
    "deploymentOption": "WITH_TRAFFIC_CONTROL"
  }
}
EOF

aws deploy create-deployment-group \
    --cli-input-json file:///tmp/deployment-group-config.json \
    --region $AWS_REGION \
    2>/dev/null && log "[OK] Deployment Group creado" || log "Deployment Group ya existe"

log ""
log "=========================================="
log "[DONE] CodeDeploy Configurado"
log "=========================================="
log ""
log "Application Name: ${PROJECT_NAME}-${ENVIRONMENT}-app"
log "Deployment Group: ${PROJECT_NAME}-${ENVIRONMENT}-dg"
log "Cluster: $CLUSTER_NAME"
log "Service: $SERVICE_NAME"
log ""
log "Próximos pasos:"
log "1. Configurar CodePipeline para usar CodeDeploy"
log "2. Hacer un commit y push para probar el deployment"
log ""
