/*
================================================================================
 POST-DEPLOYMENT
 Se ejecuta en CADA despliegue, DESPUÉS de aplicar los cambios de esquema.

 Reglas:
   - Este archivo solo contiene líneas :r. La lógica va en archivos aparte.
   - El orden de ejecución es el orden de las líneas :r.
   - Todo script incluido aquí debe poder ejecutarse N veces sin efecto adicional.
   - Ver Deployment\README.md antes de agregar un script.
================================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. Scripts recurrentes (catálogos y datos de configuración)
--    Se ejecutan siempre. Deben ser idempotentes (MERGE / IF NOT EXISTS).
--    Van primero porque los scripts de una sola vez pueden depender de ellos.
-- ---------------------------------------------------------------------------
-- :r .\Post\Recurrentes\Catalogo_EstatusPedido.sql

-- ---------------------------------------------------------------------------
-- 2. Scripts de una sola vez (POST)
--    Correcciones de datos, backfills, migraciones.
--    Agregar al final, en orden: AAAA-MM-DD_NNN_descripcion.sql
-- ---------------------------------------------------------------------------
-- :r .\Post\UnaVez\2026-11-18_001_ejemplo.sql
