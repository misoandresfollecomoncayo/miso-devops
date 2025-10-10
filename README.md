**Universidad de los Andes<br/>
Departamento de Ingeniería de Sistemas y Computación<br/>
Maestría en Ingeniería de Software<br/>
Curso: DevOps - Agilizando el Despliegue Continuo de Aplicaciones**

# Integrantes

|Nombres|Correo Uniandes|
|---|---|
|Edwin Cruz Silva|e.cruzs@uniandes.edu.co|
|Omar Andrés Folleco Moncayo|oa.folleco41@uniandes.edu.co|
|Omar Andrés Pava Perez|o.pava@uniandes.edu.co|
|Pablo José Rivera Herrera|p.riverah@uniandes.edu.co|

# Descripción

Este repositorio contiene el código fuente del aplicativo "Blacklists".

# Tecnologías de desarrollo

- Python
- Flask
- SQLAlchemy
- PostgreSQL

# Endpoints

## 1. Agregar un email a la lista negra global de la organización

### Definición del endpoint:
|**Endpoint**|/blacklists|
|---|---|
|**Método**|POST|
|**Retorno**|<code>application/json</code> Un mensaje de confirmación notificando si el email fue bloqueado o no.|
|**Parámetros**|email: String<br/>app_uuid: UUID<br/>blocked_reason: String (opcional)|
|**Autorización**|bearer token|

### Respuestas:

|Detalle|Código|Mensaje|
|---|---|---|
|No existe cabecera de autorización|401|<code>{"error": "No hay token de autorización"}</code>|
|Token de autorización inválido|403|<code>{"error": "Token inválido"}</code>|
|Cuerpo de la solicitud inválido|400|<code>{"error": "El cuerpo de la solicitud debe ser JSON"}</code>|
|Parámetros de la solicitud incompletos|400|<code>{"error": "Faltan parámetros requeridos"}</code>|
|El formato del parámetro email no es válido|400|<code>{"error": "El parámetro email no es válido"}</code>|
|El formato del parámetro app_uuid no es válido|400|<code>{"error": "El parámetro app_uuid no es válido"}</code>|
|El email fue agregado correctamente a la lista negra de la organización|200|<code>{"status": "success", "message": "El email fue agregado correctamente"}</code>|

### Pruebas y documentación Postman:

https://documenter.getpostman.com/view/49159728/2sB3QKsq3t

## 2. Consultar si un email está en la lista negra global o no