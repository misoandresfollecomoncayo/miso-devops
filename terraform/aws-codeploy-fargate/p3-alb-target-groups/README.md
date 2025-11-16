# Paso 3: Application Load Balancer y Target Groups

Este paso crea el Application Load Balancer (ALB) y los Target Groups necesarios para el despliegue Blue/Green con CodeDeploy.

## 📦 Recursos que se crean

### Load Balancer
- **Application Load Balancer**: Balanceador de carga en 2 zonas de disponibilidad

### Target Groups
- **Blue Target Group**: Para el ambiente de producción (activo)
- **Green Target Group**: Para el ambiente de staging (despliegue Blue/Green)

### Listeners
- **HTTP Listener (Puerto 80)**: Tráfico de producción → Blue Target Group
- **Test Listener (Puerto 8080)**: Tráfico de test → Green Target Group

## ⚠️ Prerequisitos

**IMPORTANTE**: Antes de ejecutar este paso, debes crear primero la VPC y subnets. Ejecuta:

```bash
# Primero crea la VPC (si no lo has hecho)
cd ../p2-vpc-network
terraform init
terraform apply
```

## 🚀 Instrucciones de uso

### 1. Inicializar Terraform

```bash
cd terraform/aws-codeploy-fargate/p3-alb-target-groups
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

### 4. Obtener la URL del ALB

```bash
terraform output application_url
```

## 📋 Configuración

Edita el archivo `terraform.tfvars` para personalizar:
- `project_name`: DEBE coincidir con el paso 2 (VPC)
- `environment`: DEBE coincidir con el paso 2 (VPC)
- `app_port`: Puerto donde escucha tu aplicación (5000 por defecto)
- `health_check_path`: Ruta para el health check (/ por defecto)

## 🔍 Verificación

Después de aplicar:

1. Ve a la consola de AWS EC2 → Load Balancers
2. Verifica que exista el ALB con el nombre `{project_name}-{environment}-alb`
3. Revisa los Target Groups (ambos deben estar vacíos inicialmente)
4. Verifica los Listeners (puerto 80 y 8080)

### Probar el ALB

```bash
# Obtener la URL
ALB_URL=$(terraform output -raw application_url)

# Probar (fallará hasta que despliegues ECS)
curl $ALB_URL
```

## 📊 Despliegue Blue/Green

El ALB está configurado para soportar despliegues Blue/Green:

- **Puerto 80 (Producción)**: Apunta al Target Group Blue
- **Puerto 8080 (Test)**: Apunta al Target Group Green

Durante un despliegue:
1. La nueva versión se despliega en Green
2. Se prueba en el puerto 8080
3. CodeDeploy intercambia los target groups
4. La nueva versión queda en producción (puerto 80)

## 🗑️ Destruir recursos

```bash
terraform destroy
```

## 💡 Tips

- El health check está configurado para 30 segundos de intervalo
- El deregistration delay es de 30 segundos
- Los Target Groups son de tipo `ip` (necesario para Fargate)
- El ALB está en modo público (internet-facing)
