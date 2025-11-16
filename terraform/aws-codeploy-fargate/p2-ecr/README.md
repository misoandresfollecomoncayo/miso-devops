# Paso 2: Amazon ECR - Elastic Container Registry

Este paso crea un repositorio en Amazon ECR para almacenar las imágenes Docker de tu aplicación.

## 📦 Recursos que se crean

- **Repositorio ECR**: Para almacenar imágenes Docker
- **Política de ciclo de vida**: Mantiene solo las últimas 10 imágenes
- **Escaneo de vulnerabilidades**: Automático al hacer push
- **Cifrado**: AES256 para las imágenes

## 🚀 Instrucciones de uso

### 1. Inicializar Terraform

```bash
cd terraform/aws-codeploy-fargate/p2-ecr
terraform init
```

### 2. Revisar el plan

```bash
terraform plan
```

### 3. Aplicar cambios

```bash
terraform apply
```

### 4. Ver los comandos Docker

```bash
terraform output docker_commands
```

## 📋 Construir y pushear imagen Docker

Después de aplicar Terraform, sigue estos pasos:

### 1. Autenticarse en ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
```

### 2. Construir la imagen

```bash
cd /Users/usuari/Documents/Uniandes_temp/miso-devops
docker build -t python-app-dev .
```

### 3. Etiquetar la imagen

```bash
# Obtén la URL del repositorio
REPO_URL=$(terraform output -raw repository_url)

# Etiqueta la imagen
docker tag python-app-dev:latest $REPO_URL:latest
```

### 4. Pushear a ECR

```bash
docker push $REPO_URL:latest
```

## 🔍 Verificación

1. Ve a la consola de AWS ECR
2. Busca el repositorio `python-app-dev`
3. Verifica que la imagen esté cargada
4. Revisa el resultado del escaneo de vulnerabilidades

## 📝 Notas importantes

- El repositorio mantiene solo las últimas 10 imágenes (configurable)
- Las imágenes se escanean automáticamente en busca de vulnerabilidades
- Los tags son MUTABLES (puedes sobrescribir tags existentes)
- Las imágenes están cifradas con AES256

## 🗑️ Destruir recursos

```bash
# ⚠️ CUIDADO: Esto eliminará el repositorio Y TODAS LAS IMÁGENES
terraform destroy
```

## 💡 Tips

- Usa tags semánticos para tus imágenes: `v1.0.0`, `v1.0.1`, etc.
- También puedes usar el commit SHA: `abc123def`
- Ejemplo: `docker tag app:latest $REPO_URL:v1.0.0`
