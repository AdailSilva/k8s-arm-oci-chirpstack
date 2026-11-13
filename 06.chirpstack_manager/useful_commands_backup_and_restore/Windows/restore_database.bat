@echo off
REM Configurações do banco de dados.
set DB_NAME=chirpstack_manager
set DB_USER=postgres
set DB_PASSWORD=chirpstack-manager
set DB_HOST=localhost  REM Substitua pelo IP ou nome do servidor.
set DB_PORT=15435  REM Substitua pela porta desejada.
set BACKUP_FILE=c:\Users\adailsilva\Apps\OracleCloud\03.k8s-on-arm-oci-always-free_chirpstack\06.chirpstack_manager\backups\chirpstack_manager_bkp.sql

REM Exporta a senha do PostgreSQL.
set PGPASSWORD=%DB_PASSWORD%

REM Realiza a restauração com o host e a porta especificados.
"C:\Program Files\PostgreSQL\16\bin\pg_restore.exe" -U %DB_USER% -d %DB_NAME% -h %DB_HOST% -p %DB_PORT% -v -F c "%BACKUP_FILE%"

REM Verifica se a restauração foi bem-sucedida.
if %ERRORLEVEL% equ 0 (
    echo Restauração realizada com sucesso!
) else (
    echo Falha ao realizar a restauração!
    exit /b 1
)

REM Remove a senha do ambiente.
set PGPASSWORD=

