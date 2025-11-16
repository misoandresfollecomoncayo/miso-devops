#!/bin/bash

# ============================================
# Script de Despliegue Completo
# Tutorial 5 - AWS CodeDeploy con Fargate
# ============================================

set -e  # Detener en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/deployment.log"
START_TIME=$(date +%s)

# ============================================
# Funciones auxiliares
# ============================================

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "\n${BLUE}========================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}========================================${NC}\n" | tee -a "$LOG_FILE"
}

check_prerequisites() {
    log_step "Verificando prerequisitos"
    
    # Verificar Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform no está instalado"
        exit 1
    fi
    log "✓ Terraform instalado: $(terraform version | head -n1)"
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI no está instalado"
        exit 1
    fi
    log "✓ AWS CLI instalado: $(aws --version)"
    
    # Verificar credenciales AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Credenciales AWS no configuradas"
        exit 1
    fi
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region || echo "us-east-1")
    log "✓ AWS Account ID: $ACCOUNT_ID"
    log "✓ AWS Region: $REGION"
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado"
        exit 1
    fi
    log "✓ Docker instalado: $(docker --version)"
}

terraform_deploy() {
    local step_dir=$1
    local step_name=$2
    
    log_step "Desplegando: $step_name"
    
    cd "$step_dir"
    
    log "Inicializando Terraform..."
    terraform init -input=false >> "$LOG_FILE" 2>&1
    
    log "Validando configuración..."
    terraform validate >> "$LOG_FILE" 2>&1
    
    log "Ejecutando plan..."
    terraform plan -out=tfplan -input=false | tee -a "$LOG_FILE"
    
    log "Aplicando cambios..."
    terraform apply -input=false tfplan | tee -a "$LOG_FILE"
    
    rm -f tfplan
    
    log "${GREEN}✓ $step_name completado${NC}"
}

get_terraform_output() {
    local step_dir=$1
    local output_name=$2
    
    cd "$step_dir"
    terraform output -raw "$output_name" 2>/dev/null || echo ""
}

# ============================================
# Main Deployment Flow
# ============================================

reset_terraform_vars() {
    log "Reseteando terraform.tfvars a valores placeholder..."
    
    # Reset RDS vars
    sed -i.bak "s/vpc_id *= *\".*\"/vpc_id = \"vpc-PLACEHOLDER\"/" "${SCRIPT_DIR}/p3-rds-postgres/terraform.tfvars"
    sed -i.bak "s/ecs_tasks_security_group_id *= *\".*\"/ecs_tasks_security_group_id = \"sg-PLACEHOLDER\"/" "${SCRIPT_DIR}/p3-rds-postgres/terraform.tfvars"
    
    # Reset ECS vars
    sed -i.bak "s/vpc_id *= *\".*\"/vpc_id = \"vpc-PLACEHOLDER\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    sed -i.bak "s/ecs_tasks_security_group_id *= *\".*\"/ecs_tasks_security_group_id = \"sg-PLACEHOLDER\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    sed -i.bak "s/subnet_ids *= *\[.*\]/subnet_ids = [\"subnet-PLACEHOLDER1\", \"subnet-PLACEHOLDER2\"]/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    sed -i.bak "s/db_host *= *\".*\"/db_host = \"db-PLACEHOLDER.rds.amazonaws.com\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    
    log "✓ Variables reseteadas"
}

main() {
    log_step "🚀 Iniciando Despliegue Completo"
    log "Log file: $LOG_FILE"
    
    # Resetear variables a placeholders
    reset_terraform_vars
    
    # Verificar prerequisitos
    check_prerequisites
    
    # Paso 1: IAM Roles
    terraform_deploy "${SCRIPT_DIR}/p1-iam-roles" "Paso 1: IAM Roles para CodeDeploy"
    
    # Paso 2a: ECR Repository
    terraform_deploy "${SCRIPT_DIR}/p2-ecr" "Paso 2a: ECR Repository"
    
    # Obtener ECR URL
    ECR_URL=$(get_terraform_output "${SCRIPT_DIR}/p2-ecr" "repository_url")
    log "ECR Repository URL: $ECR_URL"
    
    # Paso 2b: Build y Push Docker Image
    log_step "Paso 2b: Build y Push de Docker Image"
    
    if [ -f "${SCRIPT_DIR}/p2-ecr/rebuild-and-push.sh" ]; then
        log "Ejecutando build y push de imagen Docker..."
        cd "${SCRIPT_DIR}/p2-ecr"
        bash rebuild-and-push.sh | tee -a "$LOG_FILE"
        log "${GREEN}✓ Docker image creada y subida a ECR${NC}"
    else
        log_warning "Script rebuild-and-push.sh no encontrado, saltando..."
    fi
    
    # Paso 3: ALB y Target Groups (incluye VPC)
    terraform_deploy "${SCRIPT_DIR}/p3-alb-target-groups" "Paso 3: VPC, ALB y Target Groups"
    
    # Obtener outputs del Paso 3
    ALB_DNS=$(get_terraform_output "${SCRIPT_DIR}/p3-alb-target-groups" "alb_dns_name")
    VPC_ID=$(get_terraform_output "${SCRIPT_DIR}/p3-alb-target-groups" "vpc_id")
    ECS_SG_ID=$(get_terraform_output "${SCRIPT_DIR}/p3-alb-target-groups" "ecs_tasks_security_group_id")
    SUBNET_IDS=$(cd "${SCRIPT_DIR}/p3-alb-target-groups" && terraform output -json public_subnet_ids | jq -r 'join(",")')
    log "ALB DNS: $ALB_DNS"
    log "VPC ID: $VPC_ID"
    log "ECS Tasks Security Group ID: $ECS_SG_ID"
    log "Subnet IDs: $SUBNET_IDS"
    
    # Actualizar terraform.tfvars de RDS con los valores del Paso 3
    if [ -n "$VPC_ID" ] && [ -n "$ECS_SG_ID" ]; then
        log "Actualizando terraform.tfvars en p3-rds-postgres con VPC y SG..."
        sed -i.bak "s/vpc_id = \".*\"/vpc_id = \"$VPC_ID\"/" "${SCRIPT_DIR}/p3-rds-postgres/terraform.tfvars"
        sed -i.bak "s/ecs_tasks_security_group_id = \".*\"/ecs_tasks_security_group_id = \"$ECS_SG_ID\"/" "${SCRIPT_DIR}/p3-rds-postgres/terraform.tfvars"
        log "✓ Variables de red actualizadas en RDS terraform.tfvars"
    fi
    
    # Paso 3.5: RDS PostgreSQL
    terraform_deploy "${SCRIPT_DIR}/p3-rds-postgres" "Paso 3.5: RDS PostgreSQL"
    
    # Obtener DB Host
    DB_HOST=$(get_terraform_output "${SCRIPT_DIR}/p3-rds-postgres" "db_host")
    log "Database Host: $DB_HOST"
    
    # Actualizar Task Definition con DB_HOST, VPC_ID y ECS_SG_ID
    if [ -n "$DB_HOST" ]; then
        log "Actualizando terraform.tfvars en p4-ecs-cluster-task..."
        sed -i.bak "s/db_host = \".*\"/db_host = \"$DB_HOST\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
        log "✓ DB_HOST actualizado en terraform.tfvars"
    fi
    
    if [ -n "$VPC_ID" ] && [ -n "$ECS_SG_ID" ]; then
        sed -i.bak "s/vpc_id = \".*\"/vpc_id = \"$VPC_ID\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
        sed -i.bak "s/ecs_tasks_security_group_id = \".*\"/ecs_tasks_security_group_id = \"$ECS_SG_ID\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
        log "✓ Variables de red actualizadas en ECS terraform.tfvars"
    fi
    
    if [ -n "$SUBNET_IDS" ]; then
        # Convertir "subnet-xxx,subnet-yyy" a ["subnet-xxx", "subnet-yyy"]
        SUBNET_ARRAY=$(echo "$SUBNET_IDS" | awk '{split($0,a,","); printf "["; for(i in a) printf "\"%s\"%s", a[i], (i<length(a)?", ":""); print "]"}')
        sed -i.bak "s/subnet_ids *= *\[.*\]/subnet_ids = $SUBNET_ARRAY/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
        log "✓ Subnet IDs actualizados en ECS terraform.tfvars"
    fi
    
    # Paso 4: ECS Cluster, Task Definition y Service
    terraform_deploy "${SCRIPT_DIR}/p4-ecs-cluster-task" "Paso 4: ECS Cluster y Task Definition"
    
    # Obtener información del cluster
    CLUSTER_NAME=$(get_terraform_output "${SCRIPT_DIR}/p4-ecs-cluster-task" "cluster_name")
    SERVICE_NAME=$(get_terraform_output "${SCRIPT_DIR}/p4-ecs-cluster-task" "service_name")
    log "ECS Cluster: $CLUSTER_NAME"
    log "ECS Service: $SERVICE_NAME"
    
    # Resumen final
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    log_step "✅ Despliegue Completado Exitosamente"
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          DESPLIEGUE COMPLETADO EXITOSAMENTE                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "\n${BLUE}📊 Resumen de Recursos Creados:${NC}\n"
    echo -e "  🔐 IAM Roles:          Creados para CodeDeploy"
    echo -e "  📦 ECR Repository:     $ECR_URL"
    echo -e "  🐳 Docker Image:       Subida a ECR con linux/amd64"
    echo -e "  🌐 VPC:                $VPC_ID"
    echo -e "  🔒 Security Groups:    $ECS_SG_ID"
    echo -e "  📡 Subnets:            $(echo $SUBNET_IDS | tr ',' ' ')"
    echo -e "  ⚖️  Load Balancer:      $ALB_DNS"
    echo -e "  🗄️  Database:           $DB_HOST (auto-inicializada)"
    echo -e "  🐳 ECS Cluster:        $CLUSTER_NAME"
    echo -e "  🚀 ECS Service:        $SERVICE_NAME"
    
    echo -e "\n${BLUE}🔗 URLs de Acceso:${NC}\n"
    echo -e "  Application (Blue):  http://$ALB_DNS"
    echo -e "  Application (Green): http://$ALB_DNS:8080"
    
    echo -e "\n${BLUE}⏱️  Tiempo de Despliegue:${NC} ${MINUTES}m ${SECONDS}s\n"
    
    echo -e "\n${YELLOW}📝 Próximos Pasos:${NC}\n"
    echo -e "  1. Verificar que el servicio ECS esté corriendo:"
    echo -e "     ${GREEN}aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME${NC}"
    echo -e ""
    echo -e "  2. Esperar 2-3 minutos para que la aplicación inicialice la BD"
    echo -e ""
    echo -e "  3. Revisar logs de la aplicación:"
    echo -e "     ${GREEN}aws logs tail /ecs/python-app-dev --follow${NC}"
    echo -e ""
    echo -e "  4. Probar la aplicación:"
    echo -e "     ${GREEN}curl http://$ALB_DNS/blacklists/ping${NC}"
    echo -e ""
    echo -e "  5. Continuar con el Paso 5: AWS CodeDeploy"
    echo -e "     ${GREEN}cd ${SCRIPT_DIR}/p5-codedeploy${NC}"
    echo -e ""
    
    echo -e "${BLUE}💡 Nota:${NC} La aplicación crea automáticamente:"
    echo -e "   - Base de datos 'miso_devops_blacklists' si no existe"
    echo -e "   - Tablas necesarias (blacklists, etc.)"
    echo -e ""
    
    log "Despliegue completado en ${MINUTES}m ${SECONDS}s"
    log "Log guardado en: $LOG_FILE"
}

# ============================================
# Manejo de señales
# ============================================

cleanup() {
    log_error "Script interrumpido por el usuario"
    exit 1
}

trap cleanup SIGINT SIGTERM

# ============================================
# Ejecutar main
# ============================================

main "$@"
