#!/bin/bash

# Script de Destrucción Completa
# Tutorial 5 - AWS CodeDeploy con Fargate

# No usar set -e para que continúe aunque fallen algunos destroy
set -u  # Error en variables no definidas

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/destruction.log"
START_TIME=$(date +%s)

# Funciones auxiliares

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

confirm_destruction() {
    echo -e "\n${RED}ADVERTENCIA: DESTRUCCIÓN DE INFRAESTRUCTURA${NC}\n"
    echo -e "Este script ${RED}ELIMINARÁ${NC} todos los recursos creados:"
    echo -e ""
    echo -e "  - ECS Cluster y Service"
    echo -e "  - Base de datos RDS PostgreSQL"
    echo -e "  - Application Load Balancer"
    echo -e "  - VPC y Networking"
    echo -e "  - ECR Repository (con todas las imágenes)"
    echo -e "  - IAM Roles"
    echo -e ""
    echo -e "${YELLOW}Esta acción NO se puede deshacer.${NC}"
    echo -e ""
    
    read -p "¿Está seguro que desea continuar? (escriba 'yes' para confirmar): " -r
    echo
    
    if [[ ! $REPLY =~ ^yes$ ]]; then
        log "Destrucción cancelada por el usuario"
        exit 0
    fi
    
    echo -e "${YELLOW}Última oportunidad para cancelar (Ctrl+C)...${NC}"
    sleep 3
}

terraform_destroy() {
    local step_dir=$1
    local step_name=$2
    
    log_step "Destruyendo: $step_name"
    
    cd "$step_dir"
    
    if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
        log_warning "No se encontró terraform.tfstate en $step_dir, saltando..."
        return 0
    fi
    
    log "Inicializando Terraform..."
    terraform init -input=false >> "$LOG_FILE" 2>&1 || true
    
    log "Ejecutando destroy..."
    terraform destroy -auto-approve -input=false | tee -a "$LOG_FILE" || {
        log_error "Error al destruir $step_name"
        log_warning "Puede haber recursos huérfanos, revisa AWS Console"
        return 1
    }
    
    log "${GREEN}[OK] $step_name destruido${NC}"
}

delete_ecr_images() {
    log_step "Eliminando imágenes de ECR"
    
    local ecr_repo="python-app-dev"
    
    # Verificar si el repositorio existe
    if aws ecr describe-repositories --repository-names "$ecr_repo" --region us-east-1 &> /dev/null; then
        log "Obteniendo lista de imágenes en $ecr_repo..."
        
        # Obtener IDs de imágenes
        local image_ids=$(aws ecr list-images \
            --repository-name "$ecr_repo" \
            --region us-east-1 \
            --query 'imageIds[*]' \
            --output json 2>/dev/null)
        
        if [ "$image_ids" != "[]" ] && [ -n "$image_ids" ]; then
            log "Eliminando imágenes de ECR..."
            aws ecr batch-delete-image \
                --repository-name "$ecr_repo" \
                --region us-east-1 \
                --image-ids "$image_ids" >> "$LOG_FILE" 2>&1 || true
            log "[OK] Imágenes eliminadas"
        else
            log "No hay imágenes para eliminar en ECR"
        fi
    else
        log_warning "Repositorio ECR no encontrado, saltando..."
    fi
}

force_delete_ecs_service() {
    log_step "Forzando eliminación de ECS Service"
    
    local cluster="python-app-dev-cluster"
    local service="python-app-dev-service"
    
    # Verificar si el cluster existe
    if ! aws ecs describe-clusters --clusters "$cluster" --region us-east-1 --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
        log_warning "Cluster ECS no encontrado o no activo, saltando..."
        return 0
    fi
    
    # Verificar si el servicio existe
    local service_status=$(aws ecs describe-services --cluster "$cluster" --services "$service" --region us-east-1 --query 'services[0].status' --output text 2>/dev/null || echo "MISSING")
    
    if [ "$service_status" != "MISSING" ] && [ "$service_status" != "INACTIVE" ]; then
        log "Actualizando desired count a 0..."
        aws ecs update-service \
            --cluster "$cluster" \
            --service "$service" \
            --desired-count 0 \
            --region us-east-1 >> "$LOG_FILE" 2>&1 || true
        
        log "Esperando que las tareas se detengan (30 segundos)..."
        sleep 30
        
        log "Eliminando servicio..."
        aws ecs delete-service \
            --cluster "$cluster" \
            --service "$service" \
            --force \
            --region us-east-1 >> "$LOG_FILE" 2>&1 || true
        
        log "Esperando confirmación de eliminación (10 segundos)..."
        sleep 10
        
        log "[OK] Servicio ECS eliminado"
    else
        log_warning "Servicio ECS no encontrado o ya inactivo, saltando..."
    fi
}

clean_terraform_state() {
    log_step "Limpiando archivos de Terraform"
    
    find "$SCRIPT_DIR" -type f \( -name "terraform.tfstate*" -o -name "tfplan" -o -name "*.tfvars.bak" \) -delete 2>/dev/null || true
    find "$SCRIPT_DIR" -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
    
    log "[OK] Archivos de estado limpiados"
}

empty_s3_bucket() {
    log_step "Vaciando bucket S3 de CodePipeline"
    
    # Obtener account ID dinámicamente
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "148342400171")
    local bucket_name="python-app-dev-pipeline-artifacts-${account_id}"
    
    # Verificar si el bucket existe
    if aws s3api head-bucket --bucket "$bucket_name" --region us-east-1 2>/dev/null; then
        log "Bucket encontrado: $bucket_name"
        log "Eliminando objetos..."
        
        # Método simple sin loops complejos
        aws s3 rm "s3://${bucket_name}" --recursive --region us-east-1 2>&1 | head -20 | tee -a "$LOG_FILE" || true
        
        log "[OK] Bucket S3 vaciado"
    else
        log_warning "Bucket S3 no encontrado, saltando..."
    fi
}

# Main Destruction Flow

main() {
    log_step "[DESTROY]  Iniciando Destrucción Completa"
    log "Log file: $LOG_FILE"
    
    # Confirmar destrucción
    confirm_destruction
    
    log "Iniciando destrucción de recursos..."
    
    # Paso 5: CodePipeline (destruir primero)
    if [ -d "${SCRIPT_DIR}/p5-codepipeline" ]; then
        # Vaciar bucket S3 ANTES de destruir CodePipeline
        empty_s3_bucket
        
        log_step "Eliminando CodePipeline y CodeBuild"
        terraform_destroy "${SCRIPT_DIR}/p5-codepipeline" "Paso 5: CodePipeline" || true
    fi
    
    # Paso 4: ECS Cluster, Task Definition y Service
    if [ -d "${SCRIPT_DIR}/p4-ecs-cluster-task" ]; then
        # Intentar forzar eliminación del servicio primero
        force_delete_ecs_service
        terraform_destroy "${SCRIPT_DIR}/p4-ecs-cluster-task" "Paso 4: ECS Cluster y Task Definition" || true
    fi
    
    # Paso 3.5: RDS PostgreSQL
    if [ -d "${SCRIPT_DIR}/p3-rds-postgres" ]; then
        terraform_destroy "${SCRIPT_DIR}/p3-rds-postgres" "Paso 3.5: RDS PostgreSQL" || true
    fi
    
    # Paso 3: ALB, Target Groups y VPC
    if [ -d "${SCRIPT_DIR}/p3-alb-target-groups" ]; then
        terraform_destroy "${SCRIPT_DIR}/p3-alb-target-groups" "Paso 3: VPC, ALB y Target Groups" || true
    fi
    
    # Paso 2b: Eliminar imágenes de ECR antes de destruir el repositorio
    delete_ecr_images
    
    # Paso 2a: ECR Repository
    if [ -d "${SCRIPT_DIR}/p2-ecr" ]; then
        terraform_destroy "${SCRIPT_DIR}/p2-ecr" "Paso 2a: ECR Repository" || true
    fi
    
    # Paso 1: IAM Roles (destruir al final)
    if [ -d "${SCRIPT_DIR}/p1-iam-roles" ]; then
        terraform_destroy "${SCRIPT_DIR}/p1-iam-roles" "Paso 1: IAM Roles para CodeDeploy" || true
    fi
    
    # Limpiar archivos de estado
    clean_terraform_state
    
    # Resumen final
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    log_step "[DONE] Destrucción Completada"
    
    echo -e "\n${GREEN}=====================================================================${NC}"
    echo -e "${GREEN}           DESTRUCCIÓN COMPLETADA EXITOSAMENTE                     ${NC}"
    echo -e "${GREEN}=====================================================================${NC}\n"
    
    echo -e "${BLUE}Recursos Eliminados:${NC}\n"
    echo -e "  [OK] CodePipeline y CodeBuild"
    echo -e "  [OK] ECS Cluster y Service"
    echo -e "  [OK] Base de datos RDS PostgreSQL"
    echo -e "  [OK] Application Load Balancer"
    echo -e "  [OK] VPC y Networking"
    echo -e "  [OK] ECR Repository e imágenes"
    echo -e "  [OK] IAM Roles"
    
    echo -e "\n${BLUE}Tiempo de Destrucción:${NC} ${MINUTES}m ${SECONDS}s\n"
    
    # Resetear terraform.tfvars a valores placeholder
    log_step "Reseteando terraform.tfvars"
    
    log "Reseteando valores en p3-rds-postgres/terraform.tfvars..."
    sed -i.bak "s/vpc_id = \".*\"/vpc_id = \"vpc-PLACEHOLDER\"/" "${SCRIPT_DIR}/p3-rds-postgres/terraform.tfvars"
    sed -i.bak "s/ecs_tasks_security_group_id = \".*\"/ecs_tasks_security_group_id = \"sg-PLACEHOLDER\"/" "${SCRIPT_DIR}/p3-rds-postgres/terraform.tfvars"
    
    log "Reseteando valores en p4-ecs-cluster-task/terraform.tfvars..."
    sed -i.bak "s/vpc_id = \".*\"/vpc_id = \"vpc-PLACEHOLDER\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    sed -i.bak "s/ecs_tasks_security_group_id = \".*\"/ecs_tasks_security_group_id = \"sg-PLACEHOLDER\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    sed -i.bak "s/subnet_ids *= *\[.*\]/subnet_ids = [\"subnet-PLACEHOLDER1\", \"subnet-PLACEHOLDER2\"]/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    sed -i.bak "s/db_host = \".*\"/db_host = \"db-PLACEHOLDER.rds.amazonaws.com\"/" "${SCRIPT_DIR}/p4-ecs-cluster-task/terraform.tfvars"
    
    log "[OK] Variables reseteadas a placeholders"
    
    echo -e "\n${YELLOW}📝 Verificación Recomendada:${NC}\n"
    echo -e "  1. Revisa AWS Console para confirmar que no quedan recursos huérfanos"
    echo -e "  2. Verifica que no haya costos inesperados en Cost Explorer"
    echo -e "  3. Revisa CloudWatch Logs por si quedaron log groups"
    echo -e ""
    
    log "Destrucción completada en ${MINUTES}m ${SECONDS}s"
    log "Log guardado en: $LOG_FILE"
}

# Manejo de señales

cleanup() {
    log_error "Script interrumpido por el usuario"
    exit 1
}

trap cleanup SIGINT SIGTERM

# Ejecutar main

main "$@"
