# Blacklists Application

Aplicación de gestión de listas negras de correos electrónicos desarrollada para el curso de DevOps de la Maestría en Ingeniería de Software de la Universidad de los Andes.

## Integrantes

|Nombres|Correo Uniandes|
|---|---|
|Edwin Cruz Silva|e.cruzs@uniandes.edu.co|
|Omar Andrés Folleco Moncayo|oa.folleco41@uniandes.edu.co|
|Omar Andrés Pava Perez|o.pava@uniandes.edu.co|
|Pablo José Rivera Herrera|p.riverah@uniandes.edu.co|

## Tecnologías

- Python 3.12
- Flask 3.1.0
- SQLAlchemy
- PostgreSQL
- pytest
- Docker
- AWS ECS Fargate
- Terraform
- New Relic APM

## API Endpoints

### POST /blacklists

Agrega un email a la lista negra global de la organización.

**Autorización:** Bearer token

**Parámetros:**
- `email` (String, requerido): Dirección de correo electrónico
- `app_uuid` (UUID, requerido): Identificador de la aplicación
- `blocked_reason` (String, opcional): Razón del bloqueo

**Respuestas:**

| Código | Descripción |
|--------|-------------|
| 200 | Email agregado correctamente |
| 400 | Parámetros inválidos o incompletos |
| 401 | Token de autorización no proporcionado |
| 403 | Token de autorización inválido |

**Ejemplo:**

```bash
curl -X POST http://localhost:5000/blacklists \
  -H "Authorization: Bearer token_valido" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ejemplo@gmail.com",
    "app_uuid": "66b00d93-26a8-4046-943c-e6c5b62e3be5",
    "blocked_reason": "Bloqueo de Ejemplo 1"
  }'
```

### GET /blacklists/:email

Consulta si un email está en la lista negra.

**Autorización:** Bearer token

**Parámetros:**
- `email` (String, requerido): Dirección de correo electrónico

**Respuestas:**

| Código | Descripción |
|--------|-------------|
| 200 | Retorna `{"blacklist": true}` o `{"blacklist": false}` |
| 400 | Formato de email inválido |
| 401 | Token de autorización no proporcionado |
| 403 | Token de autorización inválido |

**Ejemplo:**

```bash
curl -X GET http://localhost:5000/blacklists/ejemplo@gmail.com \
  -H "Authorization: Bearer token_valido"
```

### GET /ping

Health check endpoint.

**Respuesta:** `200 OK`

## Infraestructura

La aplicación está desplegada en AWS usando los siguientes servicios:

- **ECS Fargate**: Orquestación de contenedores
- **ECR**: Registro de imágenes Docker
- **RDS PostgreSQL**: Base de datos
- **Application Load Balancer**: Balanceador de carga
- **CodePipeline**: CI/CD automatizado
- **CodeBuild**: Construcción de imágenes
- **CodeDeploy**: Despliegue Blue/Green

La infraestructura se gestiona mediante Terraform con módulos organizados en `terraform/aws-codeploy-fargate/`.

## Monitoreo

La aplicación utiliza New Relic APM para monitoreo de:

- Tiempo de respuesta de servicios
- Rendimiento de consultas a base de datos
- Apdex score
- Registro y análisis de errores
- Distributed tracing

## Desarrollo Local

### Requisitos

- Python 3.12
- PostgreSQL
- Docker (opcional)

### Instalación

```bash
pip install -r requirements.txt
```

### Variables de Entorno

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres123
export DB_NAME=miso_devops_blacklists
```

### Ejecutar la Aplicación

```bash
python -m src.app
```

### Ejecutar Pruebas

```bash
pytest src/test/test.py
```

## Despliegue

El despliegue se realiza automáticamente mediante CodePipeline al hacer push a la rama `main`. El pipeline ejecuta:

1. **Source**: Obtiene el código desde GitHub
2. **Build**: Construye la imagen Docker y la sube a ECR
3. **Deploy**: Despliega en ECS Fargate usando estrategia Blue/Green

## Documentación Adicional

- [Configuración de Variables Dinámicas](DYNAMIC-VARIABLES.md)
- [Configuración de New Relic](NEW_RELIC_SETUP.md)
- [Colección Postman](https://www.postman.com/misoandresfollecomoncayo-9717669/miso-devops/collection/p0jwi82/blacklists-app)

## Videos de Entregas

- [Entrega 1](https://drive.google.com/file/d/1zjUT5zi4UIbPUqDhEecvAmYlLivAYw3X/view?usp=sharing)
- [Entrega 2](https://drive.google.com/file/d/1sy7MgLiJfn93papLaZSNCYN77NrFEXWr/view?usp=sharing)
