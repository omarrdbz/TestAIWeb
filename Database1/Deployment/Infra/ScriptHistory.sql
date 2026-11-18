/*
================================================================================
 Tabla de control de scripts de una sola vez.
 NO MODIFICAR. Se incluye desde Script.PreDeployment.sql.

 La tabla NO forma parte del modelo del proyecto (no hay un .sql en el esquema):
 se crea aquí para que exista desde el primer despliegue, incluso para los
 scripts PRE, que corren antes de que SqlPackage aplique el esquema.
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

        CONSTRAINT PK_ScriptHistory PRIMARY KEY CLUSTERED (ScriptId),
        CONSTRAINT CK_ScriptHistory_Phase CHECK (Phase IN ('PRE', 'POST'))
    );
END
GO
