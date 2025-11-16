#!/bin/bash
# ============================================
# Script para reconstruir y subir imagen a ECR
# ============================================
# Este script:
# 1. Autentica con ECR
# 2. Construye la imagen Docker
# 3. Etiqueta la imagen
# 4. Sube la imagen a ECR

set -e  # Salir si hay error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Rebuild y Push de Imagen Docker a ECR${NC}"
echo -e "${BLUE}================================================${NC}"

# Variables
REGION="us-east-1"
ACCOUNT_ID="148342400171"
REPOSITORY_NAME="python-app-dev"
IMAGE_TAG="latest"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URL}/${REPOSITORY_NAME}:${IMAGE_TAG}"

# Directorio raíz del proyecto (donde está el Dockerfile)
PROJECT_ROOT="$(cd ../../../ && pwd)"

echo -e "\n${YELLOW}Configuración:${NC}"
echo "  - Región: ${REGION}"
echo "  - Account ID: ${ACCOUNT_ID}"
echo "  - Repositorio: ${REPOSITORY_NAME}"
echo "  - Tag: ${IMAGE_TAG}"
echo "  - Proyecto: ${PROJECT_ROOT}"

# Paso 1: Autenticar con ECR
echo -e "\n${BLUE}[1/4] Autenticando con Amazon ECR...${NC}"
aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin ${ECR_URL}

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK] Autenticación exitosa${NC}"
else
  echo -e "${RED}✗ Error en autenticación${NC}"
  exit 1
fi

# Paso 2: Construir imagen Docker para linux/amd64 (Fargate)
echo -e "\n${BLUE}[2/4] Construyendo imagen Docker para linux/amd64...${NC}"
cd ${PROJECT_ROOT}

# Verificar si buildx está disponible
if ! docker buildx version &> /dev/null; then
  echo -e "${YELLOW}[WARNING]  Docker buildx no disponible, usando build normal${NC}"
  echo -e "${YELLOW}[WARNING]  ADVERTENCIA: La imagen puede no ser compatible con Fargate${NC}"
  docker build --platform linux/amd64 -t ${REPOSITORY_NAME}:${IMAGE_TAG} .
else
  echo -e "${GREEN}[OK] Usando docker buildx para multi-arquitectura${NC}"
  docker buildx build \
    --platform linux/amd64 \
    --load \
    --no-cache \
    -t ${REPOSITORY_NAME}:${IMAGE_TAG} \
    .
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK] Imagen construida exitosamente para linux/amd64${NC}"
else
  echo -e "${RED}✗ Error al construir imagen${NC}"
  exit 1
fi

# Paso 3: Etiquetar imagen
echo -e "\n${BLUE}[3/4] Etiquetando imagen para ECR...${NC}"
docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK] Imagen etiquetada: ${FULL_IMAGE_NAME}${NC}"
else
  echo -e "${RED}✗ Error al etiquetar imagen${NC}"
  exit 1
fi

# Paso 4: Subir imagen a ECR
echo -e "\n${BLUE}[4/4] Subiendo imagen a ECR...${NC}"
docker push ${FULL_IMAGE_NAME}

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK] Imagen subida exitosamente${NC}"
else
  echo -e "${RED}✗ Error al subir imagen${NC}"
  exit 1
fi

# Resumen
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  [OK] Proceso completado exitosamente${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\nImagen disponible en:"
echo -e "  ${FULL_IMAGE_NAME}\n"

# Verificar imagen en ECR
echo -e "${BLUE}Verificando imagen en ECR...${NC}"
aws ecr describe-images \
  --repository-name ${REPOSITORY_NAME} \
  --region ${REGION} \
  --image-ids imageTag=${IMAGE_TAG} \
  --query 'imageDetails[0].{Pushed:imagePushedAt,Size:imageSizeInBytes,Tags:imageTags}' \
  --output table

echo -e "\n${YELLOW}Próximo paso:${NC}"
echo "  Para actualizar el servicio ECS, ejecuta el deploy de CodeDeploy"
echo "  o actualiza manualmente el servicio ECS con la nueva imagen."
