/*
================================================================================
 PRE-DEPLOYMENT
 Se ejecuta en CADA despliegue, ANTES de aplicar los cambios de esquema.

 Reglas:
   - Este archivo solo contiene líneas :r. La lógica va en archivos aparte.
   - El orden de ejecución es el orden de las líneas :r.
   - Todo script incluido aquí debe poder ejecutarse N veces sin efecto adicional.
   - Ver Deployment\README.md antes de agregar un script.
================================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. Infraestructura (no modificar)
--    Crea el esquema [deploy] y la tabla de control si no existen.
-- ---------------------------------------------------------------------------
:r .\Infra\ScriptHistory.sql

-- ---------------------------------------------------------------------------
-- 2. Scripts de una sola vez (PRE)
--    Preparar datos antes del cambio de esquema.
--    Agregar al final, en orden: AAAA-MM-DD_NNN_descripcion.sql
-- ---------------------------------------------------------------------------
-- :r .\Pre\UnaVez\2026-11-18_001_ejemplo.sql
