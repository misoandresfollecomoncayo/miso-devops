# ✅ Correcciones Aplicadas al Deploy Script

## 🔧 Problemas Identificados y Solucionados

### 1. **Referencia incorrecta a `p2-vpc-network`**
   
**Problema:** El script `deploy-all.sh` intentaba desplegar `p2-vpc-network` que NO existe.

**Causa:** Confusión en la estructura del tutorial. Según el PDF:
- **Actividad 2**: Solo crea ECR Repository
- **Actividad 3**: Crea VPC, ALB y Target Groups (todo junto)

**Solución:**
- ✅ Eliminada referencia a `p2-vpc-network` del deploy script
- ✅ VPC ahora se crea dentro de `p3-alb-target-groups`
- ✅ Orden correcto: p1 IAM → p2 ECR → p3 VPC+ALB → p3.5 RDS → p4 ECS

---

### 2. **VPC no se creaba, solo se buscaba**

**Problema:** `p3-alb-target-groups/main.tf` usaba `data sources` para buscar VPC/subnets existentes, pero nunca los creaba.

**Solución:**
✅ Agregados recursos de creación:
- `aws_vpc.main` - VPC 10.0.0.0/16
- `aws_internet_gateway.main` - Internet Gateway
- `aws_subnet.public` - 2 subnets públicas (10.0.1.0/24, 10.0.2.0/24)
- `aws_route_table.public` - Tabla de rutas con salida a Internet
- `aws_security_group.alb` - Security Group para ALB (puertos 80, 8080)
- `aws_security_group.ecs_tasks` - Security Group para ECS Tasks (puerto 5000)

✅ Actualizados outputs para exportar:
- `vpc_id`
- `public_subnet_ids`
- `alb_security_group_id`
- `ecs_tasks_security_group_id`

---

### 3. **Base de datos no se inicializaba**

**Problema:** No estaba claro si la BD se auto-inicializaba o necesitaba scripts.

**Solución:**
✅ **La aplicación ya lo hace automáticamente:**
- `src/database.py` tiene función `create_database_if_not_exists()`
- `src/app.py` ejecuta `db.create_all()` para crear tablas
- Solo necesita variables de entorno correctas (DB_HOST, DB_USER, DB_PASSWORD, etc.)

✅ Agregada nota en el deploy script explicando esto
✅ Añadido paso de "esperar 2-3 minutos" para que la app inicialice la BD

---

### 4. **Subnets privadas vs públicas**

**Problema:** `p4-ecs-cluster-task` buscaba subnets "privadas" pero solo existen "públicas".

**Solución:**
- ✅ Cambiado `data.aws_subnets.private` → `data.aws_subnets.public`
- ✅ Configuración correcta con `assign_public_ip = true` (necesario para Fargate en subnets públicas)

---

### 5. **Health check path incorrecto**

**Problema:** Health check configurado con path `/` pero la app usa `/blacklists/ping`.

**Solución:**
- ✅ Actualizado `terraform.tfvars` en `p3-alb-target-groups`: `health_check_path = "/blacklists/ping"`

---

## 📋 Estructura Final Correcta

```
terraform/aws-codeploy-fargate/
├── deploy-all.sh           ✅ Script maestro de despliegue
├── destroy-all.sh          ✅ Script de destrucción
│
├── p1-iam-roles/           ✅ Paso 1: IAM Roles para CodeDeploy
│
├── p2-ecr/                 ✅ Paso 2: ECR Repository + Docker Build/Push
│
├── p3-alb-target-groups/   ✅ Paso 3: VPC + ALB + Target Groups (TODO EN UNO)
│   ├── main.tf             ✅ Ahora incluye VPC, Subnets, IGW, SGs, ALB, TGs
│   ├── variables.tf        ✅ Agregadas: vpc_cidr, public_subnet_cidrs
│   ├── outputs.tf          ✅ Agregados: vpc_id, subnet_ids, sg_ids
│   └── terraform.tfvars    ✅ Actualizado health_check_path
│
├── p3-rds-postgres/        ✅ Paso 3.5: Base de datos PostgreSQL
│   └── main.tf             ✅ Usa data sources que ahora existen
│
└── p4-ecs-cluster-task/    ✅ Paso 4: ECS Cluster + Task + Service
    └── main.tf             ✅ Corregido: usa subnets públicas
```

---

## 🚀 Orden de Ejecución Correcto

```bash
./deploy-all.sh
```

**Pasos internos:**
1. ✅ Verificar prerequisitos (Terraform, AWS CLI, Docker, credenciales)
2. ✅ **p1-iam-roles**: Crear roles IAM para CodeDeploy
3. ✅ **p2-ecr**: Crear ECR repository
4. ✅ **p2-ecr**: Build & Push Docker image (linux/amd64)
5. ✅ **p3-alb-target-groups**: Crear VPC, Subnets, IGW, SGs, ALB, Target Groups
6. ✅ **p3-rds-postgres**: Crear base de datos RDS PostgreSQL
7. ✅ Actualizar `DB_HOST` en p4 Task Definition automáticamente
8. ✅ **p4-ecs-cluster-task**: Crear ECS Cluster, Task Definition, Service
9. ✅ Mostrar resumen con URLs y próximos pasos

---

## 🧪 Verificación Post-Despliegue

```bash
# 1. Verificar que el servicio esté corriendo
aws ecs describe-services --cluster python-app-dev-cluster --services python-app-dev-service

# 2. Ver logs (esperar 2-3 minutos para inicialización)
aws logs tail /ecs/python-app-dev --follow

# 3. Probar la aplicación
ALB_DNS=$(cd p3-alb-target-groups && terraform output -raw alb_dns_name)
curl http://$ALB_DNS/blacklists/ping
# Respuesta esperada: {"status": "ok"}
```

---

## 💡 Notas Importantes

### Base de Datos Auto-Inicializada
La aplicación Flask incluye lógica para:
1. Conectarse a PostgreSQL
2. Crear la base de datos `miso_devops_blacklists` si no existe
3. Crear todas las tablas automáticamente (`db.create_all()`)

**No se necesitan scripts SQL adicionales.**

### Variables de Entorno en Task Definition
```json
{
  "name": "DB_HOST",
  "value": "<RDS_ENDPOINT>"  // Se actualiza automáticamente
},
{
  "name": "DB_USER",
  "value": "postgres"
},
{
  "name": "DB_PASSWORD",
  "value": "postgres123"
},
{
  "name": "DB_PORT",
  "value": "5432"
},
{
  "name": "DB_NAME",
  "value": "miso_devops_blacklists"
}
```

### Arquitectura de Red
- **VPC**: 10.0.0.0/16
- **Subnets públicas**: 10.0.1.0/24, 10.0.2.0/24 (2 AZs)
- **Sin NAT Gateway**: ECS Tasks con IP pública en subnets públicas
- **Ahorro de costos**: NAT Gateway cuesta ~$32/mes, no necesario para desarrollo

---

## 🗑️ Destrucción

```bash
./destroy-all.sh
```

**Orden inverso:**
1. ECS Service y Cluster
2. RDS PostgreSQL (~5-10 min)
3. ALB y Target Groups
4. VPC y Networking
5. ECR Repository (elimina imágenes primero)
6. IAM Roles

---

## ✅ Checklist de Validación

- [x] No hay referencias a `p2-vpc-network`
- [x] VPC se crea en `p3-alb-target-groups`
- [x] Security Groups correctos (ALB y ECS)
- [x] Subnets públicas (no privadas)
- [x] Health check path: `/blacklists/ping`
- [x] DB auto-inicializada por la app
- [x] Task Definition actualizada con DB_HOST
- [x] Docker image con arquitectura linux/amd64
- [x] Scripts con logs detallados
- [x] Manejo de errores y confirmaciones

---

## 📚 Referencia

- **Tutorial**: Tutorial 5 – AWS Code Deploy con AWS Fargate
- **Región**: us-east-1
- **Account ID**: 148342400171
- **Repositorio**: miso-devops
