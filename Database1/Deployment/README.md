# Scripts de pre y post deployment

El pipeline despliega el **esquema** comparando el dacpac contra la base destino.
Todo lo que sea **datos** (DML) o preparación especial va en estos scripts, que se
compilan dentro del dacpac y se ejecutan en el mismo despliegue:

```
DeploymentScript.sql
 ├─ Script.PreDeployment.sql    ← antes del cambio de esquema
 ├─ (cambios de esquema que calcula SqlPackage)
 └─ Script.PostDeployment.sql   ← después del cambio de esquema
```

Quedan versionados en Git, entran por pull request y se pueden revisar en el
`DeploymentScript.sql` que publica el pipeline.

## Estructura

```
Deployment/
├─ Script.PreDeployment.sql      Solo líneas :r (no lógica)
├─ Script.PostDeployment.sql     Solo líneas :r (no lógica)
├─ Infra/ScriptHistory.sql       Tabla de control (no modificar)
├─ Pre/UnaVez/                   Una sola vez, antes del esquema
├─ Post/Recurrentes/             Cada despliegue: catálogos y configuración
├─ Post/UnaVez/                  Una sola vez, después del esquema
└─ _Plantillas/                  Copiar de aquí
```

## ¿Qué tipo de script necesito?

| Necesito… | Tipo | Carpeta | Plantilla |
|---|---|---|---|
| Mantener un catálogo o datos de configuración | Recurrente | `Post/Recurrentes` | `Recurrente.sql` |
| Corregir datos, backfill, migrar datos a una columna nueva | Una vez | `Post/UnaVez` | `UnaVez.sql` |
| Mover o limpiar datos **antes** de un cambio de esquema | Una vez | `Pre/UnaVez` | `UnaVez.sql` (Fase `PRE`) |

## Cómo agregar un script

1. Copia la plantilla a la carpeta que corresponde.
2. Nombre:
   - Una vez: `AAAA-MM-DD_NNN_descripcion.sql` (ej. `2026-11-18_001_corrige_estatus_pedidos.sql`).
   - Recurrente: `Catalogo_<Tabla>.sql` o `Config_<Tema>.sql`.
3. En scripts de una vez, pon el **mismo nombre (sin `.sql`) en `@ScriptId`** y la fase correcta.
4. Agrega la línea `:r` **al final** de la sección correspondiente en
   `Script.PreDeployment.sql` o `Script.PostDeployment.sql`.
5. Verifica que el archivo quede con **Build Action = None** en Visual Studio
   (Propiedades del archivo). Si queda en *Build*, el proyecto no compila.
6. Compila el proyecto localmente y abre el pull request.

## Reglas

- **Todo se ejecuta en cada despliegue.** Los recurrentes deben ser idempotentes
  (`MERGE`, `IF NOT EXISTS`). Los de una vez se protegen solos con la tabla
  `deploy.ScriptHistory`.
- **El `@ScriptId` nunca cambia** después de desplegarse. Si lo cambias, se vuelve
  a ejecutar.
- **No edites un script de una vez que ya se desplegó en algún ambiente.** Si hay
  que corregir algo, crea un script nuevo.
- **Cada archivo termina con `GO`.** Los `:r` pegan los archivos en uno solo, y sin
  `GO` las variables `DECLARE` chocan entre scripts.
- **Si un script falla, el despliegue se detiene.** Los cambios de esquema ya
  aplicados se quedan; el script fallido hace rollback y se reintenta en el
  siguiente despliegue.
- **No metas DDL aquí** (tablas, columnas, índices, procedimientos). El esquema se
  cambia en los archivos del proyecto.

## Casos especiales

### Columnas o tablas que todavía no existen (scripts PRE)

SQL Server compila el lote completo antes de ejecutarlo. Si un script PRE hace
referencia a una columna que el esquema va a crear después (o que va a eliminar),
falla al compilar aunque esa rama no se ejecute. Envuelve esas sentencias en SQL
dinámico:

```sql
EXEC sp_executesql N'
    UPDATE dbo.Cliente
    SET    NombreCompleto = Nombre + N'' '' + Apellido
    WHERE  NombreCompleto IS NULL;';
```

### Tablas grandes

Un `UPDATE` o `DELETE` sobre millones de filas en una sola transacción bloquea la
tabla y hace crecer el log. Hazlo por lotes, sin la transacción de la plantilla, y
registra en `deploy.ScriptHistory` al final:

```sql
DECLARE @Lote int = 5000, @Filas int = 1;

WHILE @Filas > 0
BEGIN
    UPDATE TOP (@Lote) dbo.Pedido
    SET    Estatus = 'C'
    WHERE  Estatus = 'X';

    SET @Filas = @@ROWCOUNT;
END
```

El `WHERE` debe excluir las filas ya procesadas, para que el script pueda
reanudarse si se interrumpe.

### Pérdida de datos

`SqlPackage` calcula los cambios de esquema **antes** de que corra el
pre-deployment. Un script PRE no evita que el despliegue se bloquee por posible
pérdida de datos. Si el cambio la requiere, se aprueba en el pipeline con la
opción *Permitir posible pérdida de datos*.

## Revisión en pull request

- ¿El tipo y la carpeta son correctos?
- ¿Se agregó la línea `:r` en el orden correcto?
- ¿El `@ScriptId` es igual al nombre del archivo y no repite uno existente?
- ¿El script es seguro si se ejecuta dos veces?
- ¿El `WHERE` es correcto? ¿Cuántas filas va a tocar en producción?

## Limpieza

Cuando un script de una vez ya se ejecutó en **todos** los ambientes (incluido
producción), se puede quitar su línea `:r` y borrar el archivo. El registro queda
en `deploy.ScriptHistory` y en el historial de Git.

## Configuración del proyecto (.sqlproj)

Configuración que se agrega una sola vez al proyecto:

```xml
<ItemGroup>
  <PreDeploy Include="Deployment\Script.PreDeployment.sql" />
  <PostDeploy Include="Deployment\Script.PostDeployment.sql" />
  <None Include="Deployment\Infra\*.sql" />
  <None Include="Deployment\Pre\**\*.sql" />
  <None Include="Deployment\Post\**\*.sql" />
  <None Include="Deployment\_Plantillas\*.sql" />
  <None Include="Deployment\README.md" />
</ItemGroup>
```

Solo puede haber **un** `PreDeploy` y **un** `PostDeploy` por proyecto.

Si el proyecto es SDK-style (`<Project Sdk="Microsoft.Build.Sql">`), todos los
`.sql` se compilan por defecto; agrega además:

```xml
<ItemGroup>
  <Build Remove="Deployment\**" />
</ItemGroup>
```
