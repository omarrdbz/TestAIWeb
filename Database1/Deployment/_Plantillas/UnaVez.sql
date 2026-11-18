/*
================================================================================
 SCRIPT DE UNA SOLA VEZ  (plantilla: copiar a Pre\UnaVez o Post\UnaVez)

 Id:          AAAA-MM-DD_NNN_descripcion   <- igual al nombre del archivo, sin .sql
 Ticket:      [ID del work item]
 Autor:       [nombre]
 Fase:        PRE | POST
 Descripción: [qué hace y por qué]

 Notas:
   - El Id NUNCA se cambia una vez desplegado: es lo que evita que se repita.
   - Si falla, se hace ROLLBACK y el despliegue se detiene. Al volver a desplegar
     se reintenta, porque no quedó registrado en deploy.ScriptHistory.
   - Si el script usa columnas o tablas que todavía no existen (típico en PRE),
     envolver esas sentencias en EXEC sp_executesql (ver README).
================================================================================
*/
SET XACT_ABORT ON;

DECLARE @ScriptId nvarchar(200) = N'AAAA-MM-DD_NNN_descripcion';
DECLARE @Phase    varchar(4)    = 'POST';   -- 'PRE' o 'POST'

IF EXISTS (SELECT 1 FROM deploy.ScriptHistory WHERE ScriptId = @ScriptId)
BEGIN
    PRINT CONCAT(N'[UnaVez] Omitido, ya ejecutado: ', @ScriptId);
END
ELSE
BEGIN
    PRINT CONCAT(N'[UnaVez] Ejecutando: ', @ScriptId);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ====================================================================
        -- CAMBIOS
        -- ====================================================================

        -- UPDATE dbo.Pedido
        -- SET    Estatus = 'C'
        -- WHERE  Estatus = 'X';

        -- PRINT CONCAT(N'  Filas afectadas: ', @@ROWCOUNT);

        -- ====================================================================

        INSERT INTO deploy.ScriptHistory (ScriptId, Phase)
        VALUES (@ScriptId, @Phase);

        COMMIT TRANSACTION;

        PRINT CONCAT(N'[UnaVez] Completado: ', @ScriptId);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END
GO
