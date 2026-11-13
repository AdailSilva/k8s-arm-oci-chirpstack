@echo off
REM Configurações do banco de dados.
set DB_NAME=chirpstack_manager
set DB_USER=postgres
set DB_PASSWORD=chirpstack-manager
set DB_HOST=localhost  REM Substitua pelo IP ou nome do servidor.
set DB_PORT=15435  REM Substitua pela porta desejada.
set BACKUP_DIR=c:\users\adailsilva\Apps\OracleCloud\03.k8s-on-arm-oci-always-free_chirpstack\06.chirpstack_manager\backups
set BACKUP_FILE=%BACKUP_DIR%\%DB_NAME%_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.sql

REM Cria o diretório de backup se não existir.
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Exporta a senha do PostgreSQL.
set PGPASSWORD=%DB_PASSWORD%

REM Realiza o backup com host e porta especificados.
"C:\Program Files\PostgreSQL\16\bin\pg_dump.exe" -U %DB_USER% -d %DB_NAME% -h %DB_HOST% -p %DB_PORT% -F c -b -v -f "%BACKUP_FILE%"

REM Verifica se o backup foi bem-sucedido.
if %ERRORLEVEL% equ 0 (
    echo Backup realizado com sucesso: %BACKUP_FILE%
) else (
    echo Falha ao realizar o backup!
    exit /b 1
)

REM Remove a senha do ambiente.
set PGPASSWORD=

