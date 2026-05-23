@echo off
setlocal enabledelayedexpansion

rem RESTORE - chirpstack - PostgreSQL 16
rem
rem Uso:
rem   restore_chirpstack-v4.bat arquivo.backup   (formato custom - pg_restore)
rem   restore_chirpstack-v4.bat arquivo.sql      (plain SQL - psql)
rem
rem Se nenhum arquivo for informado, lista os disponiveis em BACKUP_DIR.

rem CONFIGURACOES
set PG_HOST=localhost
set PG_PORT=5432
set PG_DB=chirpstack
#set PG_USER=postgres
set PG_USER=chirpstack
set PGPASSWORD=chirpstack
set BACKUP_DIR=D:\ChirpStack-v4_Back-UPs
set PG_RESTORE="C:\Program Files\PostgreSQL\16\bin\pg_restore.exe"
set PSQL="C:\Program Files\PostgreSQL\16\bin\psql.exe"
set CREATEDB="C:\Program Files\PostgreSQL\16\bin\createdb.exe"
set DROPDB="C:\Program Files\PostgreSQL\16\bin\dropdb.exe"

rem TIMESTAMP via PowerShell
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set DATE_LABEL=%%i

rem LOG FILE
set LOG_FILE=%BACKUP_DIR%\restore_%TIMESTAMP%.log

rem CRIAR DIRETORIO SE NAO EXISTIR
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem ============================================================
rem VERIFICAR ARGUMENTO
rem ============================================================
if "%~1"=="" (
    call :LOG "Nenhum arquivo informado. Arquivos disponiveis em %BACKUP_DIR%:"
    call :LOG ""
    echo.
    echo Arquivos .backup:
    dir /b /o-d "%BACKUP_DIR%\*.backup" 2>nul || echo   Nenhum encontrado.
    echo.
    echo Arquivos .sql:
    dir /b /o-d "%BACKUP_DIR%\*.sql" 2>nul || echo   Nenhum encontrado.
    echo.
    echo Uso: restore_chirpstack-v4.bat nome_do_arquivo.backup
    echo      restore_chirpstack-v4.bat nome_do_arquivo.sql
    exit /b 1
)

rem ARQUIVO INFORMADO
set INPUT_FILE=%~1

rem Se nao tiver caminho completo, assume BACKUP_DIR
if not exist "%INPUT_FILE%" (
    set INPUT_FILE=%BACKUP_DIR%\%~1
)

rem VERIFICAR SE ARQUIVO EXISTE
if not exist "%INPUT_FILE%" (
    echo ERRO: Arquivo nao encontrado: %INPUT_FILE%
    exit /b 1
)

rem DETECTAR EXTENSAO
set EXT=%~x1

rem ============================================================
rem LOG INICIAL
rem ============================================================
call :LOG "============================================================"
call :LOG " Iniciando restore: %PG_DB%"
call :LOG " Host: %PG_HOST%:%PG_PORT%"
call :LOG " Usuario: %PG_USER%"
call :LOG " Arquivo: %INPUT_FILE%"
call :LOG " Extensao detectada: %EXT%"
call :LOG "============================================================"

rem ============================================================
rem VERIFICAR BINARIOS
rem ============================================================
if not exist %PG_RESTORE% (
    call :LOG "ERRO: pg_restore nao encontrado em %PG_RESTORE%"
    goto :FINALIZAR_ERRO
)
if not exist %PSQL% (
    call :LOG "ERRO: psql nao encontrado em %PSQL%"
    goto :FINALIZAR_ERRO
)

rem ============================================================
rem DROPAR E RECRIAR O BANCO
rem ============================================================
call :LOG ""
call :LOG "Dropando banco existente (se houver)..."

%PSQL% --host=%PG_HOST% --port=%PG_PORT% --username=%PG_USER% --no-password --dbname=postgres -c "DROP DATABASE IF EXISTS %PG_DB%;" >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :LOG "  AVISO: Nao foi possivel dropar o banco. Pode estar em uso."
    call :LOG "  Feche todas as conexoes e tente novamente."
    goto :FINALIZAR_ERRO
)
call :LOG "  OK - Banco dropado."

call :LOG ""
call :LOG "Criando banco vazio..."

%PSQL% --host=%PG_HOST% --port=%PG_PORT% --username=%PG_USER% --no-password --dbname=postgres -c "CREATE DATABASE %PG_DB% TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';" >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :LOG "  ERRO: Nao foi possivel criar o banco."
    goto :FINALIZAR_ERRO
)
call :LOG "  OK - Banco criado."

rem ============================================================
rem RESTORE - FORMATO CUSTOM (.backup) via pg_restore
rem ============================================================
if /i "%EXT%"==".backup" (
    call :LOG ""
    call :LOG "Formato: CUSTOM - usando pg_restore..."

    %PG_RESTORE% --host=%PG_HOST% --port=%PG_PORT% --username=%PG_USER% --dbname=%PG_DB% --no-password --verbose "%INPUT_FILE%" >> "%LOG_FILE%" 2>&1

    set STATUS=%ERRORLEVEL%
    goto :VERIFICAR_STATUS
)

rem ============================================================
rem RESTORE - FORMATO PLAIN SQL (.sql) via psql
rem ============================================================
if /i "%EXT%"==".sql" (
    call :LOG ""
    call :LOG "Formato: PLAIN SQL - usando psql..."

    %PSQL% --host=%PG_HOST% --port=%PG_PORT% --username=%PG_USER% --dbname=%PG_DB% --no-password --file="%INPUT_FILE%" >> "%LOG_FILE%" 2>&1

    set STATUS=%ERRORLEVEL%
    goto :VERIFICAR_STATUS
)

rem Extensao nao reconhecida
call :LOG "ERRO: Extensao nao reconhecida: %EXT%"
call :LOG "Use .backup (pg_restore) ou .sql (psql)."
goto :FINALIZAR_ERRO

rem ============================================================
rem VERIFICAR STATUS DO RESTORE
rem ============================================================
:VERIFICAR_STATUS
call :LOG ""
if %STATUS% EQU 0 (
    call :LOG "  OK - Restore concluido com sucesso."
) else (
    call :LOG "  AVISO: Restore finalizado com codigo: %STATUS%"
    call :LOG "  Verifique o log para detalhes: %LOG_FILE%"
)

rem ============================================================
rem RESUMO FINAL
rem ============================================================
call :LOG ""
call :LOG "============================================================"
call :LOG " STATUS FINAL: SUCESSO"
call :LOG " Banco restaurado: %PG_DB%"
call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b 0

:FINALIZAR_ERRO
call :LOG ""
call :LOG "============================================================"
call :LOG " STATUS FINAL: FALHA"
call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b 99

rem SUB-ROTINA DE LOG
:LOG
set MSG=%~1
echo [%DATE_LABEL%] %MSG%
echo [%DATE_LABEL%] %MSG% >> "%LOG_FILE%"
goto :eof
