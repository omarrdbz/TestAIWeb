/*
================================================================================
 Tabla de control de scripts de una sola vez.
 NO MODIFICAR. Se incluye desde Script.PreDeployment.sql.

 La tabla NO forma parte del modelo del proyecto (no hay un .sql en el esquema):
 se crea aquí para que exista desde el primer despliegue, incluso para los
 scripts PRE, que corren antes de que SqlPackage aplique el esquema.

 BuildNumber y RequestedFor vienen de las variables SQLCMD $(BuildNumber) y
 $(RequestedFor), que el pipeline pasa al generar el script.
================================================================================
*/
IF SCHEMA_ID(N'deploy') IS NULL
    EXEC (N'CREATE SCHEMA [deploy] AUTHORIZATION [dbo];');
GO

IF OBJECT_ID(N'deploy.ScriptHistory', N'U') IS NULL
BEGIN
    CREATE TABLE deploy.ScriptHistory
    (
        ScriptId      nvarchar(200) NOT NULL,
        Phase         varchar(4)    NOT NULL,
        ExecutedAtUtc datetime2(0)  NOT NULL
            CONSTRAINT DF_ScriptHistory_ExecutedAtUtc DEFAULT (SYSUTCDATETIME()),
        ExecutedBy    sysname       NOT NULL
            CONSTRAINT DF_ScriptHistory_ExecutedBy DEFAULT (SUSER_SNAME()),
        BuildNumber   nvarchar(100) NULL,
        RequestedFor  nvarchar(256) NULL,

        CONSTRAINT PK_ScriptHistory PRIMARY KEY CLUSTERED (ScriptId),
        CONSTRAINT CK_ScriptHistory_Phase CHECK (Phase IN ('PRE', 'POST'))
    );
END
GO

-- Bases donde la tabla se creó con la versión anterior (sin trazabilidad).
IF COL_LENGTH(N'deploy.ScriptHistory', N'BuildNumber') IS NULL
    ALTER TABLE deploy.ScriptHistory ADD BuildNumber nvarchar(100) NULL;
GO

IF COL_LENGTH(N'deploy.ScriptHistory', N'RequestedFor') IS NULL
    ALTER TABLE deploy.ScriptHistory ADD RequestedFor nvarchar(256) NULL;
GO
