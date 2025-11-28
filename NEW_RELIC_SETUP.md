# 🔍 Configuración de New Relic para Monitoreo de Aplicación ECS Fargate

## 📋 Resumen de Cambios

Se ha integrado New Relic APM (Application Performance Monitoring) en la aplicación Python Flask desplegada en ECS Fargate.

## 🎯 Capacidades de Monitoreo Implementadas

### 1. **Tiempo de Respuesta de los Servicios**
- ✅ Monitoreo automático de todas las rutas Flask
- ✅ Distributed tracing habilitado
- ✅ Métricas de throughput (solicitudes por minuto)
- ✅ Breakdown de tiempo por tipo de operación

### 2. **Tiempo de Respuesta de la Base de Datos**
- ✅ Monitoreo de queries SQL a PostgreSQL
- ✅ Slow query detection
- ✅ Obfuscación de SQL para seguridad
- ✅ Database instance reporting

### 3. **Monitoreo del Apdex**
- ✅ Score de satisfacción del usuario
- ✅ Umbral configurable (0.5s por defecto)
- ✅ Desglose por transacción

### 4. **Registro de Errores**
- ✅ Captura automática de excepciones
- ✅ Stack traces completos
- ✅ Error analytics y tendencias
- ✅ Hasta 100 muestras de error almacenadas

### 5. **Configuración de Alertas/Alarmas**
- ✅ Estructura base para alertas
- ✅ Labels para organización (Environment, Service, Platform)

## 📦 Archivos Modificados

### 1. **requirements.txt**
```python
Flask==3.1.0
Flask-SQLAlchemy==3.1.0
psycopg2-binary
pytest
newrelic  # ← NUEVO
```

### 2. **src/app.py**
```python
import newrelic.agent

# Inicializar New Relic antes que nada
newrelic.agent.initialize()

from flask import Flask
# ... resto del código
```

### 3. **Dockerfile**
```dockerfile
# Copiar configuración de New Relic
COPY newrelic.ini /app/newrelic.ini

# Arranque con New Relic
CMD ["newrelic-admin", "run-program", "python", "-m", "src.app"]
```

### 4. **newrelic.ini** (NUEVO)
Archivo de configuración con:
- Nombre de aplicación
- Niveles de log
- Distributed tracing
- Transaction tracing
- Error collector
- Slow SQL detection
- Database monitoring

### 5. **Terraform - variables.tf**
```terraform
variable "new_relic_license_key" {
  description = "License key de New Relic"
  type        = string
  sensitive   = true
  default     = ""
}

variable "new_relic_app_name" {
  description = "Nombre de la aplicación en New Relic"
  type        = string
  default     = "Python Blacklists App - ECS Fargate"
}

variable "new_relic_enabled" {
  description = "Habilitar monitoreo de New Relic"
  type        = bool
  default     = true
}
```

### 6. **Terraform - main.tf**
Variables de entorno agregadas al task definition:
- `NEW_RELIC_LICENSE_KEY`
- `NEW_RELIC_APP_NAME`
- `NEW_RELIC_MONITOR_MODE`
- `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED`
- `NEW_RELIC_LOG`
- `NEW_RELIC_LOG_LEVEL`

### 7. **taskdef.json**
Mismo conjunto de variables de entorno para CodeDeploy

## 🚀 Pasos para Activar New Relic

### Paso 1: Obtener License Key

1. Ve a New Relic: https://one.newrelic.com
2. Crea una cuenta gratuita (o usa una existente)
3. Ve a: **User menu** → **API keys**
4. Copia tu **License key** (o créala si no existe)

### Paso 2: Configurar License Key

Actualiza en **dos archivos**:

#### A. `terraform/aws-codeploy-fargate/p4-ecs-cluster-task/terraform.tfvars`
```terraform
new_relic_license_key = "tu_license_key_aqui"
new_relic_app_name = "Python Blacklists App - ECS Fargate"
new_relic_enabled = true
```

#### B. `taskdef.json` (para CodeDeploy)
```json
{
  "name": "NEW_RELIC_LICENSE_KEY",
  "value": "tu_license_key_aqui"
}
```

### Paso 3: Redesplegar la Aplicación

```bash
# Opción 1: Via Terraform (actualiza el servicio ECS directamente)
cd terraform/aws-codeploy-fargate/p4-ecs-cluster-task
terraform apply

# Opción 2: Via CI/CD Pipeline (recomendado)
cd /Users/usuari/Documents/uniandes/miso-devops
git add .
git commit -m "feat: add New Relic APM monitoring"
git push origin main
```

### Paso 4: Verificar en New Relic

1. Ve a: https://one.newrelic.com/nr1-core
2. Navega a: **APM & Services**
3. Busca: **"Python Blacklists App - ECS Fargate"**
4. Espera 2-5 minutos para ver los primeros datos

## 📊 Dashboards y Vistas en New Relic

### 1. **Service Overview** (Vista Principal)
- Apdex score
- Throughput (requests/min)
- Response time
- Error rate
- Traffic patterns

### 2. **Transactions**
Verás todas tus rutas Flask:
- `GET /ping`
- `POST /blacklists`
- `GET /blacklists/<email>`

Para cada transacción:
- Average response time
- Percentiles (50th, 95th, 99th)
- Throughput
- Error rate

### 3. **Databases**
Monitoreo de PostgreSQL:
- Query time
- Slow queries (> 500ms)
- Database calls per transaction
- Most time-consuming queries

Ejemplo de queries monitoreadas:
```sql
SELECT * FROM blacklists WHERE email = ?
INSERT INTO blacklists (email, app_uuid, ...) VALUES (?, ?, ...)
```

### 4. **Errors**
- Lista de errores recientes
- Stack traces completos
- Frecuencia de errores
- Affected transactions

### 5. **Distributed Tracing**
- Trace completo de cada request
- Tiempo en cada componente:
  - Flask middleware
  - Database queries
  - External calls

### 6. **Service Maps**
Visualización de:
- Tu aplicación Flask
- Conexión a PostgreSQL RDS
- External dependencies

## 🔔 Configuración de Alertas

### Desde la UI de New Relic:

1. **Alerta de Tiempo de Respuesta Alto**
   - Condición: Response time > 1 segundo por 5 minutos
   - Severidad: Warning

2. **Alerta de Error Rate Alto**
   - Condición: Error rate > 5% por 5 minutos
   - Severidad: Critical

3. **Alerta de Apdex Bajo**
   - Condición: Apdex score < 0.7 por 10 minutos
   - Severidad: Warning

4. **Alerta de Database Slow Queries**
   - Condición: Avg DB query time > 500ms
   - Severidad: Warning

5. **Alerta de Throughput Anormal**
   - Condición: Throughput < 1 req/min por 10 minutos
   - Severidad: Critical (servicio caído)

### Crear Alerta desde UI:

```
1. Ve a: Alerts & AI → Alert conditions
2. Click: "Create alert condition"
3. Selecciona: APM
4. Elige tu aplicación: "Python Blacklists App - ECS Fargate"
5. Define la métrica (Response time, Error rate, etc.)
6. Configura umbrales
7. Selecciona canal de notificación (email, Slack, PagerDuty, etc.)
```

## 🧪 Generar Tráfico para Probar

```bash
# 1. Requests exitosos
for i in {1..50}; do
  curl -s http://python-app-dev-alb-1251671227.us-east-1.elb.amazonaws.com/ping > /dev/null
  echo "Request $i sent"
  sleep 0.5
done

# 2. Consultar blacklist
for i in {1..20}; do
  curl -s -H "Authorization: Bearer token_valido" \
    http://python-app-dev-alb-1251671227.us-east-1.elb.amazonaws.com/blacklists/test$i@example.com
  sleep 1
done

# 3. Agregar a blacklist
curl -X POST http://python-app-dev-alb-1251671227.us-east-1.elb.amazonaws.com/blacklists \
  -H "Authorization: Bearer token_valido" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "app_uuid": "123e4567-e89b-12d3-a456-426614174000",
    "blocked_reason": "Testing New Relic"
  }'

# 4. Generar errores (sin token)
for i in {1..10}; do
  curl -s http://python-app-dev-alb-1251671227.us-east-1.elb.amazonaws.com/blacklists/test@example.com
  sleep 0.5
done
```

## 📈 Métricas Clave a Validar

### ✅ Checklist de Validación

- [ ] **Eventos llegando a New Relic** - Verifica que aparezca la aplicación
- [ ] **Tiempo de respuesta de servicios** - Gráfica visible en Transactions
- [ ] **Tiempo de respuesta de DB** - Queries SQL visibles en Databases
- [ ] **Monitoreo del Apdex** - Score visible en dashboard principal
- [ ] **Registro de errores** - Errors tab mostrando errores capturados
- [ ] **Alertas configuradas** - Al menos 2 alertas creadas

### Valores Esperados

| Métrica | Valor Esperado |
|---------|---------------|
| Apdex Score | > 0.85 (Satisfecho) |
| Avg Response Time | < 200ms |
| Error Rate | < 1% |
| Throughput | Según tráfico |
| DB Query Time | < 100ms |

## 🔒 Seguridad

- ✅ License key como variable de entorno (no hardcodeada)
- ✅ SQL obfuscado en reportes
- ✅ Variable marcada como `sensitive` en Terraform
- ✅ No se exponen credenciales en logs

## 📚 Referencias

- [New Relic Python Agent](https://docs.newrelic.com/docs/apm/agents/python-agent/)
- [Flask Instrumentation](https://docs.newrelic.com/docs/apm/agents/python-agent/python-agent-api/recordlogmessage-python-agent-api/)
- [Database Monitoring](https://docs.newrelic.com/docs/apm/agents/python-agent/supported-features/python-database-instrumentation/)
- [Distributed Tracing](https://docs.newrelic.com/docs/distributed-tracing/concepts/introduction-distributed-tracing/)

## 🆘 Troubleshooting

### Problema: No aparece la aplicación en New Relic

**Solución**:
1. Verifica que NEW_RELIC_LICENSE_KEY esté configurado
2. Revisa logs de CloudWatch: `/ecs/python-app-dev`
3. Busca errores de New Relic en los logs
4. Confirma que el agente se inicializó: `grep -i "newrelic" en logs`

### Problema: Queries SQL no aparecen

**Solución**:
1. Verifica que `slow_sql.enabled = true` en newrelic.ini
2. Genera más queries (el threshold es 500ms)
3. Espera 5-10 minutos para agregación de datos

### Problema: License key inválido

**Solución**:
1. Ve a New Relic → API Keys
2. Verifica que copiaste la **License Key** (no API Key)
3. Actualiza en terraform.tfvars y taskdef.json
4. Redesplega la aplicación
