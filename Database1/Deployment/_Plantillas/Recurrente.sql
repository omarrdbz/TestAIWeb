/*
================================================================================
 SCRIPT RECURRENTE  (plantilla: copiar a Post\Recurrentes)

 Se ejecuta en CADA despliegue. Debe dejar los datos en el mismo estado sin
 importar cuántas veces corra (idempotente).

 Uso típico: catálogos y datos de configuración que se controlan desde el código.

 Nombre:      Catalogo_<Tabla>.sql   o   Config_<Tema>.sql
 Ticket:      [ID del work item del último cambio]
 Descripción: [qué datos mantiene]
================================================================================
*/
SET XACT_ABORT ON;

PRINT N'[Recurrente] Catálogo: dbo.EstatusPedido';

MERGE dbo.EstatusPedido AS destino
USING (VALUES
    -- Clave, Descripcion
    ('A', N'Activo'),
    ('C', N'Cancelado'),
    ('E', N'Entregado')
) AS origen (Clave, Descripcion)
    ON destino.Clave = origen.Clave

-- Actualiza solo si algo cambió (comparación segura con NULL)
WHEN MATCHED AND EXISTS (
        SELECT destino.Descripcion
        EXCEPT
        SELECT origen.Descripcion
    ) THEN
    UPDATE SET destino.Descripcion = origen.Descripcion

WHEN NOT MATCHED BY TARGET THEN
    INSERT (Clave, Descripcion)
    VALUES (origen.Clave, origen.Descripcion)

-- Descomentar SOLO si el catálogo se controla 100% desde aquí.
-- Borra lo que no esté en la lista (falla si hay llaves foráneas que lo usan).
-- WHEN NOT MATCHED BY SOURCE THEN
--     DELETE
;

PRINT CONCAT(N'  Filas afectadas: ', @@ROWCOUNT);
GO
