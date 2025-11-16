# Ciclo Destroy + Deploy

## ¿Funcionará después de un destroy?

**SÍ**, el ciclo completo `destroy → deploy` funciona correctamente gracias a las mejoras implementadas:

## ✅ Mejoras Implementadas

### 1. **Reset Automático en `destroy-all.sh`**
Después de destruir toda la infraestructura, el script resetea automáticamente los `terraform.tfvars` a valores placeholder:
- `vpc_id = "vpc-PLACEHOLDER"`
- `ecs_tasks_security_group_id = "sg-PLACEHOLDER"`
- `subnet_ids = ["subnet-PLACEHOLDER1", "subnet-PLACEHOLDER2"]`
- `db_host = "db-PLACEHOLDER.rds.amazonaws.com"`

### 2. **Reset al Inicio en `deploy-all.sh`**
Antes de desplegar, el script resetea los valores a placeholders para asegurar que no haya IDs viejos.

### 3. **Actualización Automática de Variables**
Durante el deploy, el script captura los outputs de Terraform y actualiza automáticamente:
- VPC ID del paso 3 → RDS y ECS
- Security Group IDs → RDS y ECS
- Subnet IDs → ECS
- DB Host del RDS → ECS

## 🔄 Flujo Completo

```bash
# 1. Destruir toda la infraestructura
cd /Users/usuari/Documents/Uniandes_temp/miso-devops/terraform/aws-codeploy-fargate
./destroy-all.sh

# 2. Redesplegar (los valores se actualizan automáticamente)
./deploy-all.sh

# 3. La aplicación quedará funcional en 2-3 minutos
```

## 🧪 Script de Prueba

Para validar que el ciclo completo funciona:

```bash
./test-cycle.sh
```

Este script:
1. Ejecuta `destroy-all.sh`
2. Verifica que los terraform.tfvars se resetearon
3. Ejecuta `deploy-all.sh`
4. Espera a que la aplicación arranque
5. Prueba el endpoint `/ping`
6. Reporta si todo funcionó correctamente

## ⚠️ Consideraciones Importantes

### Tiempos de Espera
- **RDS Creation**: ~8-10 minutos
- **ECS Task Startup**: ~1-2 minutos
- **ALB Health Checks**: ~1-2 minutos
- **Total deploy**: ~15-20 minutos

### Recursos que Persisten
Algunos recursos pueden quedar huérfanos si hay errores:
- **CloudWatch Log Groups**: Revisa `/ecs/python-app-dev`
- **ECR Images**: Se eliminan automáticamente
- **VPC Endpoints**: Ninguno (no se crean)

### Verificación Post-Deploy

```bash
# 1. Verificar que el servicio ECS está running
CLUSTER=$(cd p4-ecs-cluster-task && terraform output -raw cluster_name)
SERVICE=$(cd p4-ecs-cluster-task && terraform output -raw service_name)
aws ecs describe-services --cluster $CLUSTER --services $SERVICE --query 'services[0].runningCount'

# 2. Ver logs de la aplicación
aws logs tail /ecs/python-app-dev --follow

# 3. Probar la aplicación
ALB_DNS=$(cd p3-alb-target-groups && terraform output -raw alb_dns_name)
curl "http://$ALB_DNS/ping"
# Debería devolver: Ok

# 4. Probar endpoint con autenticación (debería dar 401)
curl -X POST "http://$ALB_DNS/blacklists" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","app_uuid":"123"}'
# Debería devolver: {"error":"No hay token de autorización"}
```

## 📋 Checklist de Validación

Después de ejecutar el ciclo destroy → deploy, verifica:

- [ ] Todos los pasos de Terraform ejecutaron sin errores
- [ ] El servicio ECS tiene `runningCount = 1`
- [ ] Los logs muestran: `✓ Base de datos 'miso_devops_blacklists' ya existe`
- [ ] Los logs muestran: `* Running on http://10.0.x.x:5000`
- [ ] `curl http://$ALB_DNS/ping` devuelve `Ok`
- [ ] El endpoint `/blacklists` requiere autenticación (401)
- [ ] No hay recursos huérfanos en AWS Console

## 🐛 Troubleshooting

### Problema: "Target group ARN is invalid"
**Solución**: Los target groups del paso anterior aún existen. Espera 5 minutos o elimínalos manualmente.

### Problema: "VPC not found"
**Solución**: El script ya resetea los valores. Si persiste, verifica que los placeholders estén en terraform.tfvars.

### Problema: ECS tasks se reinician constantemente
**Solución**: Revisa los logs. Usualmente es un problema de health check o conectividad a RDS.

### Problema: 502/503/504 en el ALB
**Solución**: 
1. Verifica que hay tareas running: `aws ecs describe-services ...`
2. Espera 2-3 minutos para health checks
3. Verifica logs: `aws logs tail /ecs/python-app-dev`

## 💡 Mejores Prácticas

1. **Siempre usa los scripts de automatización** (`deploy-all.sh` y `destroy-all.sh`)
2. **No edites manualmente** los IDs en terraform.tfvars
3. **Espera 30 segundos** entre destroy y deploy para que AWS limpie recursos
4. **Verifica AWS Console** después del destroy para recursos huérfanos
5. **Revisa los logs** (`deployment.log` y `destruction.log`) si hay errores

## 📊 Estado Actual

✅ **Configuración Completa**:
- Docker Image: Puerto 5000, arquitectura AMD64
- Health Check: `/ping` (devuelve 200)
- Database: Auto-inicialización de schema
- Networking: VPC con 2 subnets públicas
- Security: Security Groups configurados correctamente

✅ **Scripts Actualizados**:
- `deploy-all.sh`: Reset inicial + actualización automática
- `destroy-all.sh`: Reset final de variables
- `test-cycle.sh`: Prueba del ciclo completo

✅ **Siguiente Paso**:
- Actividad 5: AWS CodeDeploy con Blue/Green Deployment
