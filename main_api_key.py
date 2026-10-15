import os
import secrets
from datetime import date
from decimal import Decimal

import psycopg
import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Security
from fastapi.responses import RedirectResponse
from fastapi.security import APIKeyHeader
from psycopg.rows import dict_row
from pydantic import BaseModel

DB_DSN = os.getenv(
    "DB_DSN",
    "host=localhost port=5432 dbname=empleados_db user=postgres password=123456",
)
API_KEY = os.getenv("API_KEY", "empleados-api-key-2026")

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verificar_api_key(api_key: str | None = Security(api_key_header)):
    if not api_key or not secrets.compare_digest(api_key, API_KEY):
        raise HTTPException(status_code=401, detail="API key inválida o ausente")

app = FastAPI(
    title="API Empleados",
    description="Consulta de empleados con su cargo (vista empleado_cargo_view)",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)


@app.get("/", include_in_schema=False)
def inicio():
    return RedirectResponse(url="/docs")


class EmpleadoCargo(BaseModel):
    emp_id: int
    nombre: str | None = None
    apellido: str | None = None
    email: str | None = None
    telefono: str | None = None
    fecha_ingreso: date | None = None
    salario: Decimal | None = None
    cargo_id: int | None = None
    nom_cargo: str | None = None
    descripcion: str | None = None


def get_connection():
    return psycopg.connect(DB_DSN, row_factory=dict_row)


@app.get(
    "/empleados",
    response_model=list[EmpleadoCargo],
    tags=["Empleados"],
    dependencies=[Depends(verificar_api_key)],
)
def listar_empleados():
    """Lista todos los empleados con su cargo."""
    try:
        with get_connection() as conn:
            return conn.execute(
                "SELECT * FROM empleado_cargo_view ORDER BY emp_id"
            ).fetchall()
    except psycopg.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {e}")


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8091, reload=True)
