# Pipelines de base de datos

## Pipelines

| Archivo | Cuándo corre | Qué hace |
|---|---|---|
| `Pipeline/main-sql-pipeline.yml` | Commit a `main`, o manual | CI → paquete (script + reporte) → CD |
| `Pipeline/pr-sql-validation.yml` | Pull request hacia `main` | Valida scripts de pre/post y compila. No despliega |

## Flujo principal

```
CI_SQL_PROJECT         Validar proyecto y scripts pre/post → compilar → DACPAC
     │
DEPLOYMENT_PACKAGE     Validar destino → DeployReport + Script (SqlPackage)
     │                 Publica: script, reporte, DACPAC, opciones, metadata
     │
CD_<environment>       (aprobación del environment)
                       Validar integridad del paquete → verificar que el script
                       siga vigente → respaldo COPY_ONLY → ejecutar con sqlcmd
```

## Plantillas

| Plantilla | Uso |
|---|---|
| `stage-ci-sql.yml` / `steps-ci-sql.yml` | Build y publicación del DACPAC |
| `stage-pr-sql.yml` / `steps-pr-sql.yml` | Validación de PR |
| `steps-build-sql.yml` | Validar, compilar y localizar DACPAC (CI y PR) |
| `steps-validate-deployment-scripts.yml` | Reglas de los scripts de pre/post |
| `stage-sql-deployment-package.yml` / `steps-sql-deployment-package.yml` | Generar script y reporte |
| `steps-resolve-sqlpackage.yml` | Ubicar SqlPackage (paquete y CD) |
| `stage-cd-sql.yml` / `steps-cd-sql.yml` | Despliegue |

## Variable group (`vg-cicdpipelinetest-cd-sql-staging`)

| Variable | Uso | Obligatoria |
|---|---|---|
| `ConnectionString` | SqlPackage (paquete y verificación en CD). Marcar como secreta | Sí |
| `TargetServer` | sqlcmd. Debe coincidir con el servidor de `ConnectionString` | Sí |
| `TargetDatabase` | sqlcmd. Debe coincidir con la base de `ConnectionString` | Sí |
| `BackupDirectory` | Carpeta de respaldos, vista **desde el servidor SQL** (ej. `\\srv\respaldos\QA`) | Con `backupBeforeDeploy: true` |

## Parámetros al correr manualmente

| Parámetro | Default | Efecto |
|---|---|---|
| Permitir posible pérdida de datos | No | Genera el script con `BlockOnPossibleDataLoss=False` |
| Justificación | — | Obligatoria (mín. 10 caracteres) si se permite pérdida de datos |

## Parámetros de plantilla relevantes

| Parámetro | Default | Dónde |
|---|---|---|
| `timeoutInMinutes` | `60` | Todos los stages (job) |
| `sqlPackageCommandTimeout` | `60` (segundos) | Paquete; CD reutiliza el valor |
| `backupBeforeDeploy` | `false` (main lo activa) | CD |
| `dataLossEnvironment` | vacío | CD: environment alterno para despliegues con pérdida de datos |

## Configuración en Azure DevOps

**Environment `QA_BD`** (Pipelines → Environments → QA_BD → Approvals and checks):
- *Approvals*: quién aprueba el despliegue.
- *Exclusive lock*: evita dos despliegues simultáneos a la misma base.

**Validación de PR** (Repos → Branches → `main` → Branch policies → Build validation):
- Pipeline: el creado desde `Pipeline/pr-sql-validation.yml`.
- Trigger automático, requerido.
- Filtro de rutas opcional: `/Database1/*; /Pipelines/*`.

En Azure Repos la sección `pr:` del YAML se ignora; la política de rama es la que
dispara el pipeline.

## Verificación de vigencia del script (CD)

Entre que se genera el paquete y se aprueba el environment puede pasar tiempo.
Antes de ejecutar, CD vuelve a generar el deployment report contra la base, con el
mismo DACPAC y las mismas opciones (`sqlpackage-options.json`), y lo compara con el
aprobado. Si alguna operación o alerta cambió, falla sin ejecutar nada y muestra
las diferencias. La solución es volver a correr el pipeline.

## Respaldo COPY_ONLY

Con `backupBeforeDeploy: true`, CD ejecuta antes del script:

```sql
BACKUP DATABASE [<TargetDatabase>]
TO DISK = '<BackupDirectory>\<base>_<build>_<fechaUTC>.bak'
WITH COPY_ONLY, CHECKSUM, INIT, COMPRESSION;  -- sin COMPRESSION en Express
```

Requisitos:
- La **cuenta de servicio de SQL Server** necesita escritura en `BackupDirectory`.
- La cuenta del agente necesita permiso de `BACKUP DATABASE` (p. ej. `db_backupoperator`).
- No aplica a Azure SQL Database (usa point-in-time restore).
- La limpieza de respaldos viejos no está en el pipeline: definir retención con el DBA.

El resumen de CD muestra la ruta del respaldo y la **hora del servidor** justo antes
de ejecutar el script. Si la base está en recuperación FULL con respaldos de log,
esa hora sirve para restaurar con `STOPAT` sin usar el respaldo.

### Restaurar (manual, último recurso)

Regresa toda la base al momento del respaldo: se pierde todo lo escrito después.

```sql
USE master;
ALTER DATABASE [Database1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [Database1]
FROM DISK = N'\\srv\respaldos\QA\Database1_20261118.3_20261118_163000.bak'
WITH REPLACE, CHECKSUM, STATS = 10;
ALTER DATABASE [Database1] SET MULTI_USER;
```

## Requisitos del proyecto SQL

Ver `Database1/Deployment/README.md`: `PreDeploy`/`PostDeploy`, scripts como
`None` y variables SQLCMD `BuildNumber` y `RequestedFor`.
