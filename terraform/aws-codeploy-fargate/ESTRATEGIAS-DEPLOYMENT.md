# Estrategias de Despliegue Blue/Green para ECS

## 📊 Estrategia Actual

**`CodeDeployDefault.ECSCanary10Percent5Minutes`**

- ✅ Despliega **10%** del tráfico inmediatamente a la versión nueva (Green)
- ⏱️ Espera **5 minutos** monitoreando métricas y alarmas
- ✅ Si no hay errores, despliega el **90%** restante del tráfico
- 🔄 Si hay errores, hace rollback automático al 100% Blue

## 🎯 Estrategias Disponibles

### 1. All At Once (Instantáneo)
```bash
CodeDeployDefault.ECSAllAtOnce
```
- **Tráfico**: 100% inmediatamente
- **Tiempo total**: ~30 segundos
- **Riesgo**: Alto (sin validación gradual)
- **Uso**: Entornos de desarrollo, cambios menores

### 2. Canary (Prueba inicial pequeña)

#### Canary 10% - 5 minutos ⭐ (Actual)
```bash
CodeDeployDefault.ECSCanary10Percent5Minutes
```
- **Fase 1**: 10% del tráfico → espera 5 min
- **Fase 2**: 90% del tráfico
- **Tiempo total**: ~6 minutos
- **Uso**: Balance entre velocidad y seguridad

#### Canary 10% - 15 minutos
```bash
CodeDeployDefault.ECSCanary10Percent15Minutes
```
- **Fase 1**: 10% del tráfico → espera 15 min
- **Fase 2**: 90% del tráfico  
- **Tiempo total**: ~16 minutos
- **Uso**: Cambios críticos con más tiempo de validación

### 3. Linear (Migración gradual)

#### Linear 10% cada 1 minuto
```bash
CodeDeployDefault.ECSLinear10PercentEvery1Minutes
```
- **Incrementos**: 10% cada 1 minuto
- **Fases**: 10 incrementos (10%, 20%, 30%... 100%)
- **Tiempo total**: ~10 minutos
- **Uso**: Migración controlada paso a paso

#### Linear 10% cada 3 minutos
```bash
CodeDeployDefault.ECSLinear10PercentEvery3Minutes
```
- **Incrementos**: 10% cada 3 minutos
- **Fases**: 10 incrementos
- **Tiempo total**: ~30 minutos
- **Uso**: Máxima precaución, observación detallada

## 🔧 Cambiar Estrategia

### Opción 1: Usar el script
```bash
cd terraform/aws-codeploy-fargate
./update-deployment-strategy.sh
```

Edita el script para cambiar `STRATEGY` a la opción deseada.

### Opción 2: AWS CLI directamente
```bash
aws deploy update-deployment-group \
  --application-name python-app-dev-app \
  --current-deployment-group-name python-app-dev-dg \
  --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes \
  --region us-east-1
```

### Opción 3: AWS Console
1. Ve a: CodeDeploy → Applications → python-app-dev-app
2. Click en deployment group: python-app-dev-dg
3. Click "Edit"
4. En "Deployment settings", selecciona la configuración deseada
5. Save

## 📈 Monitoreo Durante Despliegue

### Ver despliegue en progreso
```bash
# Listar despliegues
aws deploy list-deployments \
  --application-name python-app-dev-app \
  --deployment-group-name python-app-dev-dg \
  --region us-east-1

# Ver detalles de un despliegue
aws deploy get-deployment \
  --deployment-id <deployment-id> \
  --region us-east-1
```

### Monitorear en consola
```
https://console.aws.amazon.com/codesuite/codedeploy/deployments?region=us-east-1
```

### Ver tráfico en ALB
```bash
# Production listener (port 80)
curl http://python-app-dev-alb-1545946443.us-east-1.elb.amazonaws.com/blacklists/ping

# Test listener (port 8080) - apunta a Green durante deployment
curl http://python-app-dev-alb-1545946443.us-east-1.elb.amazonaws.com:8080/blacklists/ping
```

## 🛡️ Rollback Automático

CodeDeploy hace rollback automático si:
- ❌ El health check de ECS falla en las nuevas tareas
- ❌ Las alarmas de CloudWatch se activan
- ❌ El target group marca las tareas como unhealthy
- ❌ Errores en la configuración del deployment

Durante el rollback:
1. Detiene el shift de tráfico
2. Revierte todo el tráfico a Blue (versión anterior)
3. Termina las tareas Green
4. Marca el deployment como FAILED

## 📊 Comparación de Estrategias

| Estrategia | Tiempo | Fases | Riesgo | Observabilidad | Uso Recomendado |
|-----------|--------|-------|--------|----------------|-----------------|
| **AllAtOnce** | 30s | 1 | 🔴 Alto | ⚪ Baja | Dev, hotfixes |
| **Canary10-5m** ⭐ | 6m | 2 | 🟡 Medio | 🟢 Alta | Producción general |
| **Canary10-15m** | 16m | 2 | 🟢 Bajo | 🟢 Alta | Cambios críticos |
| **Linear10-1m** | 10m | 10 | 🟢 Bajo | 🟢 Muy Alta | Migración controlada |
| **Linear10-3m** | 30m | 10 | 🟢 Muy Bajo | 🟢 Máxima | Máxima precaución |

## 💡 Recomendaciones

### Para Desarrollo
- `ECSAllAtOnce` - Velocidad máxima

### Para Staging
- `ECSCanary10Percent5Minutes` - Balance ideal

### Para Producción (Normal)
- `ECSCanary10Percent5Minutes` - Rápido con validación

### Para Producción (Crítico)
- `ECSCanary10Percent15Minutes` o `ECSLinear10PercentEvery3Minutes`

### Para Black Friday / Eventos Críticos
- `ECSLinear10PercentEvery3Minutes` - Máximo control

## 🔍 Logs y Troubleshooting

### Ver logs de deployment
```bash
# CodeDeploy events
aws deploy get-deployment \
  --deployment-id <deployment-id> \
  --region us-east-1 \
  --query 'deploymentInfo.errorInformation'

# ECS task logs
aws logs tail /ecs/python-app-dev --follow --region us-east-1
```

### Verificar health checks
```bash
# Ver estado de tasks
aws ecs describe-services \
  --cluster python-app-dev-cluster \
  --services python-app-dev-service \
  --region us-east-1 \
  --query 'services[0].deployments'

# Ver target groups
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region us-east-1
```

## 📚 Referencias

- [AWS CodeDeploy Deployment Configurations](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html)
- [Blue/Green Deployments on AWS](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/introduction.html)
- [ECS Deployment Types](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html)
