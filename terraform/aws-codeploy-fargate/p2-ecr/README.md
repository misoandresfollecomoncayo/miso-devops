# Paso 2: Amazon ECR

Repositorio de contenedores para almacenar imágenes Docker de la aplicación con políticas de ciclo de vida y escaneo de vulnerabilidades.

## Recursos Creados

- **Repositorio ECR**: `python-app-dev`
- **Lifecycle Policy**: Mantiene últimas 10 imágenes, elimina antiguas
- **Image Scanning**: Escaneo automático de vulnerabilidades al push
- **Encryption**: AES256 para todas las imágenes

## Uso

### Despliegue

```bash
terraform init
terraform plan
terraform apply
```

### Build y Push de Imagen Docker

Opción 1: Script automatizado (recomendado)

```bash
./rebuild-and-push.sh
```

Opción 2: Manual

```bash
# 1. Autenticación
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw repository_url)

# 2. Build para linux/amd64 (requerido para Fargate)
docker buildx build --platform linux/amd64 \
  -t $(terraform output -raw repository_url):latest \
  -f ../../Dockerfile \
  ../../

# 3. Push
docker push $(terraform output -raw repository_url):latest
```

## Outputs

- `repository_url` - URL completa del repositorio
- `repository_arn` - ARN del repositorio
- `docker_commands` - Comandos listos para copiar/pegar

## Variables

```hcl
project_name         = "python-app"
environment          = "dev"
max_image_count      = 10            # Límite de imágenes
```

## Costos

Storage: $0.10/GB/mes (ejemplo: 1GB = ~$0.10/mes)

## Limpieza

```bash
terraform destroy
```
