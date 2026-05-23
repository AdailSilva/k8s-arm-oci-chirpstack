@echo off
setlocal enabledelayedexpansion

rem BACKUP DIARIO - chirpstack - PostgreSQL 16

rem CONFIGURACOES
set PG_HOST=localhost
set PG_PORT=5432
set PG_DB=chirpstack
#set PG_USER=postgres
set PG_USER=chirpstack
set PGPASSWORD=chirpstack
set BACKUP_DIR=D:\ChirpStack-v4_Back-UPs
set PG_DUMP="C:\Program Files\PostgreSQL\16\bin\pg_dump.exe"
set RETENTION_DAYS=0

rem TIMESTAMP via PowerShell
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set DATE_LABEL=%%i

rem ARQUIVOS DE SAIDA
set FILE_BACKUP=%BACKUP_DIR%\%PG_DB%_%TIMESTAMP%.backup
set FILE_SQL=%BACKUP_DIR%\%PG_DB%_%TIMESTAMP%.sql
set LOG_FILE=%BACKUP_DIR%\backup_%TIMESTAMP%.log

rem CRIAR DIRETORIO SE NAO EXISTIR
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem LOG INICIAL
call :LOG "============================================================"
call :LOG " Iniciando backup: %PG_DB%"
call :LOG " Host: %PG_HOST%:%PG_PORT%"
call :LOG " Usuario: %PG_USER%"
call :LOG "============================================================"

rem VERIFICAR pg_dump
if not exist %PG_DUMP% (
    call :LOG "ERRO: pg_dump nao encontrado em %PG_DUMP%"
    goto :FINALIZAR_ERRO
)

for /f "tokens=*" %%v in ('%PG_DUMP% --version 2^>^&1') do (
    call :LOG "Versao: %%v"
    goto :VERSAO_OK
)
:VERSAO_OK

rem BACKUP 1 - Formato CUSTOM (.backup)
call :LOG ""
call :LOG "[1/2] Gerando .backup (formato custom)..."

%PG_DUMP% --host=%PG_HOST% --port=%PG_PORT% --username=%PG_USER% --dbname=%PG_DB% --format=custom --blobs --compress=9 --verbose --no-password --file="%FILE_BACKUP%" >> "%LOG_FILE%" 2>&1

set STATUS_BACKUP=%ERRORLEVEL%

if %STATUS_BACKUP% EQU 0 (
    for %%F in ("%FILE_BACKUP%") do call :LOG "  OK - %%~zF bytes - %FILE_BACKUP%"
) else (
    call :LOG "  ERRO - Falha no .backup - codigo: %STATUS_BACKUP%"
)

rem BACKUP 2 - Formato PLAIN SQL (.sql)
call :LOG ""
call :LOG "[2/2] Gerando .sql (plain SQL)..."

%PG_DUMP% --host=%PG_HOST% --port=%PG_PORT% --username=%PG_USER% --dbname=%PG_DB% --format=plain --blobs --clean --if-exists --create --verbose --no-password --file="%FILE_SQL%" >> "%LOG_FILE%" 2>&1

set STATUS_SQL=%ERRORLEVEL%

if %STATUS_SQL% EQU 0 (
    for %%F in ("%FILE_SQL%") do call :LOG "  OK - %%~zF bytes - %FILE_SQL%"
) else (
    call :LOG "  ERRO - Falha no .sql - codigo: %STATUS_SQL%"
)

rem LIMPEZA DE BACKUPS ANTIGOS
if %RETENTION_DAYS% GTR 0 (
    call :LOG ""
    call :LOG "Limpando backups com mais de %RETENTION_DAYS% dia(s)..."
    forfiles /P "%BACKUP_DIR%" /M *.backup /D -%RETENTION_DAYS% /C "cmd /c del /Q @path" >> "%LOG_FILE%" 2>&1
    forfiles /P "%BACKUP_DIR%" /M *.sql    /D -%RETENTION_DAYS% /C "cmd /c del /Q @path" >> "%LOG_FILE%" 2>&1
    forfiles /P "%BACKUP_DIR%" /M *.log    /D -%RETENTION_DAYS% /C "cmd /c del /Q @path" >> "%LOG_FILE%" 2>&1
    call :LOG "  OK - Limpeza concluida."
)

rem RESUMO FINAL
call :LOG ""
call :LOG "============================================================"

if %STATUS_BACKUP% EQU 0 if %STATUS_SQL% EQU 0 (
    call :LOG " STATUS FINAL: SUCESSO"
    goto :FINALIZAR
)
if %STATUS_BACKUP% NEQ 0 if %STATUS_SQL% NEQ 0 (
    call :LOG " STATUS FINAL: FALHA - ambos os arquivos falharam"
    set EXIT_CODE=2
    goto :FINALIZAR
)
call :LOG " STATUS FINAL: PARCIAL - um arquivo falhou. Verifique o log."
set EXIT_CODE=1

:FINALIZAR
call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b 0

:FINALIZAR_ERRO
call :LOG " STATUS FINAL: FALHA CRITICA"
call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b 99

rem SUB-ROTINA DE LOG
:LOG
set MSG=%~1
echo [%DATE_LABEL%] %MSG%
echo [%DATE_LABEL%] %MSG% >> "%LOG_FILE%"
goto :eof
