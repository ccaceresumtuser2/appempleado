-- Base de datos: empleados_db (PostgreSQL)
-- Crear la base (ejecutar conectado a "postgres"):
--   CREATE DATABASE empleados_db;
-- Luego ejecutar este script en empleados_db:
--   psql -h localhost -p 5432 -U postgres -d empleados_db -f schema.sql

DROP VIEW IF EXISTS empleados_sin_cargo_view;
DROP VIEW IF EXISTS empleado_antiguedad_view;
DROP VIEW IF EXISTS resumen_cargo_view;
DROP VIEW IF EXISTS empleado_cargo_view;
DROP TABLE IF EXISTS empleado;
DROP TABLE IF EXISTS cargo;

CREATE TABLE cargo (
    cargo_id    SERIAL PRIMARY KEY,
    nom_cargo   VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);

CREATE TABLE empleado (
    emp_id        SERIAL PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    apellido      VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE,
    telefono      VARCHAR(20),
    fecha_ingreso DATE NOT NULL DEFAULT CURRENT_DATE,
    salario       NUMERIC(12, 2) CHECK (salario >= 0),
    cargo_id      INTEGER REFERENCES cargo (cargo_id)
                  ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE INDEX idx_empleado_cargo_id ON empleado (cargo_id);

-- Vista consumida por la API (GET /empleados)
CREATE VIEW empleado_cargo_view AS
SELECT e.emp_id,
       e.nombre,
       e.apellido,
       e.email,
       e.telefono,
       e.fecha_ingreso,
       e.salario,
       c.cargo_id,
       c.nom_cargo,
       c.descripcion
FROM empleado e
LEFT JOIN cargo c ON c.cargo_id = e.cargo_id;

-- Resumen por cargo: cantidad de empleados y estadísticas de salario
CREATE VIEW resumen_cargo_view AS
SELECT c.cargo_id,
       c.nom_cargo,
       COUNT(e.emp_id)              AS total_empleados,
       COALESCE(SUM(e.salario), 0)  AS total_salarios,
       ROUND(AVG(e.salario), 2)     AS salario_promedio,
       MIN(e.salario)               AS salario_minimo,
       MAX(e.salario)               AS salario_maximo
FROM cargo c
LEFT JOIN empleado e ON e.cargo_id = c.cargo_id
GROUP BY c.cargo_id, c.nom_cargo;

-- Antigüedad de cada empleado (en años completos)
CREATE VIEW empleado_antiguedad_view AS
SELECT e.emp_id,
       e.nombre || ' ' || e.apellido                          AS nombre_completo,
       c.nom_cargo,
       e.fecha_ingreso,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.fecha_ingreso))::INT AS anios_antiguedad
FROM empleado e
LEFT JOIN cargo c ON c.cargo_id = e.cargo_id;

-- Empleados que no tienen cargo asignado
CREATE VIEW empleados_sin_cargo_view AS
SELECT e.emp_id,
       e.nombre,
       e.apellido,
       e.email,
       e.fecha_ingreso
FROM empleado e
WHERE e.cargo_id IS NULL;

-- Datos de ejemplo
INSERT INTO cargo (nom_cargo, descripcion) VALUES
    ('Gerente',        'Responsable de la gestión general'),
    ('Desarrollador',  'Desarrollo y mantenimiento de software'),
    ('Analista',       'Análisis de requerimientos y datos'),
    ('Contador',       'Gestión contable y financiera');

INSERT INTO empleado (nombre, apellido, email, telefono, fecha_ingreso, salario, cargo_id) VALUES
    ('Juan',   'Pérez',   'juan.perez@empresa.com',   '70000001', '2020-03-15', 12000.00, 1),
    ('María',  'Gómez',   'maria.gomez@empresa.com',  '70000002', '2021-07-01',  8500.00, 2),
    ('Carlos', 'López',   'carlos.lopez@empresa.com', '70000003', '2022-01-10',  8000.00, 2),
    ('Ana',    'Torres',  'ana.torres@empresa.com',   '70000004', '2023-05-20',  7000.00, 3),
    ('Luis',   'Rojas',   'luis.rojas@empresa.com',   '70000005', '2024-02-05',  7500.00, 4);
