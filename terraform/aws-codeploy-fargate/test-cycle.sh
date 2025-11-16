#!/bin/bash

# ============================================
# Script de Prueba: Destroy + Deploy Cycle
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  TEST: Destroy + Deploy Cycle"
echo "=========================================="
echo ""
echo "Este script probará:"
echo "  1. Destruir toda la infraestructura"
echo "  2. Verificar que terraform.tfvars se resetean"
echo "  3. Redesplegar toda la infraestructura"
echo "  4. Verificar que la aplicación funciona"
echo ""
read -p "¿Continuar? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Cancelado"
    exit 0
fi

echo ""
echo "================================================"
echo "FASE 1: DESTROY"
echo "================================================"
echo ""

cd "$SCRIPT_DIR"
bash destroy-all.sh

echo ""
echo "Esperando 30 segundos para que AWS limpie recursos..."
sleep 30

echo ""
echo "================================================"
echo "FASE 2: VERIFICANDO TERRAFORM.TFVARS"
echo "================================================"
echo ""

echo "Verificando que los valores se resetearon..."
if grep -q "vpc-PLACEHOLDER" p3-rds-postgres/terraform.tfvars && \
   grep -q "sg-PLACEHOLDER" p3-rds-postgres/terraform.tfvars && \
   grep -q "vpc-PLACEHOLDER" p4-ecs-cluster-task/terraform.tfvars; then
    echo "✓ terraform.tfvars reseteados correctamente"
else
    echo "✗ ERROR: terraform.tfvars no se resetearon"
    exit 1
fi

echo ""
echo "================================================"
echo "FASE 3: DEPLOY"
echo "================================================"
echo ""

bash deploy-all.sh

echo ""
echo "================================================"
echo "FASE 4: VERIFICACIÓN"
echo "================================================"
echo ""

echo "Esperando 90 segundos para que la aplicación arranque..."
sleep 90

ALB_DNS=$(cd p3-alb-target-groups && terraform output -raw alb_dns_name)
echo "ALB DNS: $ALB_DNS"

echo ""
echo "Probando endpoint /ping..."
RESPONSE=$(curl -s "http://$ALB_DNS/ping" || echo "ERROR")

if [ "$RESPONSE" = "Ok" ]; then
    echo "✓ Aplicación funcionando correctamente"
    echo ""
    echo "================================================"
    echo "  ✓ TEST EXITOSO"
    echo "================================================"
    exit 0
else
    echo "✗ ERROR: La aplicación no responde correctamente"
    echo "Respuesta: $RESPONSE"
    exit 1
fi
