# API Empleados

API REST con FastAPI que lista los empleados con su cargo, leyendo la vista `empleado_cargo_view` de PostgreSQL.

## Estructura

| Archivo | Descripción |
|---|---|
| `main.py` | API sin autenticación |
| `main_api_key.py` | Misma API protegida con header `X-API-Key` |
| `schema.sql` | Tablas (`cargo`, `empleado`), vistas y datos de ejemplo |
| `Dockerfile` | Imagen de la API |
| `docker-compose.yml` | API + PostgreSQL local |
| `.github/workflows/ci.yml` | Pruebas y build de la imagen en GitHub Actions |
| `.env` | Conexión a Render (no se sube a git) |

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/empleados` | Lista de empleados con su cargo |
| GET | `/docs` | Swagger UI |
| GET | `/redoc` | ReDoc |

## Base de datos

### Tablas

- **cargo**: `cargo_id`, `nom_cargo`, `descripcion`
- **empleado**: `emp_id`, `nombre`, `apellido`, `email`, `telefono`, `fecha_ingreso`, `salario`, `cargo_id` → `cargo`

### Vistas

| Vista | Contenido |
|---|---|
| `empleado_cargo_view` | Empleado con su cargo (la usa la API) |
| `resumen_cargo_view` | Por cargo: cantidad de empleados y salario total, promedio, mínimo y máximo |
| `empleado_antiguedad_view` | Años de antigüedad de cada empleado |
| `empleados_sin_cargo_view` | Empleados sin cargo asignado |

> ⚠️ `schema.sql` empieza con `DROP TABLE` / `DROP VIEW`. No lo ejecutes sobre una base con datos reales.

## Configuración

La conexión se toma de la variable de entorno `DB_DSN`. Si no está definida, se usa:

```
host=localhost port=5432 dbname=empleados_db user=postgres password=123456
```

Para usar Render, crea un archivo `.env` (ya está en `.gitignore`):

```
DB_DSN=host=<host>.oregon-postgres.render.com port=5432 dbname=<base> user=<usuario> password=<password> sslmode=require
```

Render exige `sslmode=require` para conexiones externas.

## Ejecución

### 1. Local con Python

```bash
pip install -r requirements.txt
```

Crear la base y las tablas:

```bash
psql -h localhost -U postgres -c "CREATE DATABASE empleados_db;"
psql -h localhost -U postgres -d empleados_db -f schema.sql
```

Levantar la API:

```bash
python main.py
```

Para conectarse a Render en vez de localhost (PowerShell):

```powershell
$env:DB_DSN = (Get-Content .env -Raw).Trim() -replace '^DB_DSN=',''
python main.py
```

### 2. Docker Compose (API + PostgreSQL local)

```bash
docker compose up --build
```

`schema.sql` se carga automáticamente solo la primera vez. Para recrear la base desde cero (borra los datos):

```bash
docker compose down -v
docker compose up --build
```

### 3. Docker contra Render

```bash
docker build -t appempleado .
docker run --env-file .env -p 8091:8091 appempleado
```

En todos los casos la API queda en http://localhost:8091/docs.

## Qué base usa según cómo se ejecute

| Comando | Base de datos |
|---|---|
| `python main.py` | localhost |
| `python main.py` con `DB_DSN` definida | la de `DB_DSN` (Render) |
| `docker compose up` | contenedor `db` local (no lee `.env`) |
| `docker run --env-file .env` | Render |

## API con API Key

```bash
uvicorn main_api_key:app --port 8091
```

Enviar el header `X-API-Key` (por defecto `empleados-api-key-2026`, configurable con la variable `API_KEY`):

```bash
curl -H "X-API-Key: empleados-api-key-2026" http://localhost:8091/empleados
```

## CI/CD (GitHub Actions)

El workflow `.github/workflows/ci.yml` se ejecuta en cada push a `main`, en pull requests o manualmente:

1. **test**: levanta un PostgreSQL temporal, carga `schema.sql`, arranca la API y verifica que `/empleados` devuelva los 5 empleados de ejemplo.
2. **docker**: construye la imagen y, en push a `main`, la publica en `ghcr.io/<owner>/appempleado`.

Si se agrega un paso de despliegue que use Render, guardar la conexión como secret `DB_DSN` en **Settings → Secrets and variables → Actions**.
