#!/bin/bash

# ============================================
# Script para crear GitHub token en AWS Secrets Manager
# ============================================

set -e

AWS_REGION="us-east-1"
SECRET_NAME="github-token"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

log "Configurando GitHub token en AWS Secrets Manager..."
log ""
log "INSTRUCCIONES:"
log "1. Ve a GitHub → Settings → Developer settings → Personal access tokens"
log "2. Genera un token con permisos: repo, admin:repo_hook"
log "3. Copia el token"
log ""

read -sp "Pega tu GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    error "Token no puede estar vacío"
fi

log "Verificando si el secret ya existe..."

if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$AWS_REGION" 2>/dev/null; then
    log "Secret ya existe. Actualizando..."
    aws secretsmanager update-secret \
        --secret-id "$SECRET_NAME" \
        --secret-string "$GITHUB_TOKEN" \
        --region "$AWS_REGION"
    log "[OK] Secret actualizado"
else
    log "Creando nuevo secret..."
    aws secretsmanager create-secret \
        --name "$SECRET_NAME" \
        --description "GitHub Personal Access Token for CodePipeline" \
        --secret-string "$GITHUB_TOKEN" \
        --region "$AWS_REGION"
    log "[OK] Secret creado"
fi

log ""
log "=========================================="
log "[DONE] GitHub Token Configurado"
log "=========================================="
log ""
log "Secret Name: $SECRET_NAME"
log "Region: $AWS_REGION"
log ""
log "Ahora puedes ejecutar:"
log "  terraform init"
log "  terraform plan"
log "  terraform apply"
log ""
