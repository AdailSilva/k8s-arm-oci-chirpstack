@echo off
setlocal enabledelayedexpansion

rem ==============================================================
rem  BACKUP DIARIO - ChirpStack v3 (chirpstack_ns + chirpstack_as)
rem  PostgreSQL 16 - via kubectl port-forward (OCI Kubernetes)
rem ==============================================================
rem  Uso:
rem    backup_chirpstack-v3.bat        -> backup de ns e as
rem    backup_chirpstack-v3.bat ns     -> somente chirpstack_ns
rem    backup_chirpstack-v3.bat as     -> somente chirpstack_as
rem
rem  Requer: kubectl no PATH (com kubeconfig do cluster OCI)
rem          PostgreSQL 16 client (pg_dump.exe / pg_isready.exe)
rem  O script abre o port-forward de cada base, gera .backup e .sql
rem  e fecha o port-forward ao final. Se a porta ja estiver aberta
rem  (port-forward manual), ela e reaproveitada.
rem ==============================================================

rem CONFIGURACOES GERAIS
set K8S_NAMESPACE=chirpstack-v3
set PG_HOST=127.0.0.1
set BACKUP_DIR=D:\ChirpStack-v3_Back-UPs
set PG_BIN=C:\Program Files\PostgreSQL\16\bin
set PG_DUMP="%PG_BIN%\pg_dump.exe"
set PG_ISREADY="%PG_BIN%\pg_isready.exe"
set PF_TIMEOUT=30
set RETENTION_DAYS=0

rem CONFIGURACAO DAS BASES
rem  chirpstack_ns
set NS_SVC=chirpstack-v3-ns-postgresql-service
set NS_PORT=5437
set NS_DB=chirpstack_ns
set NS_USER=chirpstack_ns
set NS_PASS=chirpstack_ns
rem  chirpstack_as
set AS_SVC=chirpstack-v3-as-postgresql-service
set AS_PORT=5438
set AS_DB=chirpstack_as
set AS_USER=chirpstack_as
set AS_PASS=chirpstack_as

rem TIMESTAMP via PowerShell
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i
for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set DATE_LABEL=%%i

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
set LOG_FILE=%BACKUP_DIR%\backup_v3_%TIMESTAMP%.log

rem VERIFICACOES INICIAIS
if not exist %PG_DUMP% (
    call :LOG "ERRO: pg_dump nao encontrado em %PG_DUMP%"
    endlocal & exit /b 99
)
if not exist %PG_ISREADY% (
    call :LOG "ERRO: pg_isready nao encontrado em %PG_ISREADY%"
    endlocal & exit /b 99
)
where kubectl >nul 2>&1
if errorlevel 1 (
    call :LOG "ERRO: kubectl nao encontrado no PATH."
    endlocal & exit /b 99
)

rem SELECAO DAS BASES
set TARGETS=%*
if "%TARGETS%"=="" set TARGETS=ns as

set EXIT_CODE=0
set RESUMO=
for %%T in (%TARGETS%) do (
    if /i "%%T"=="ns" (
        call :BACKUP_BASE "!NS_SVC!" !NS_PORT! !NS_DB! !NS_USER! !NS_PASS!
    ) else if /i "%%T"=="as" (
        call :BACKUP_BASE "!AS_SVC!" !AS_PORT! !AS_DB! !AS_USER! !AS_PASS!
    ) else (
        call :LOG "ERRO: base desconhecida '%%T' (use: ns ou as)"
        set RC=2
    )
    if !RC! EQU 0 (set RESUMO=!RESUMO! %%T:SUCESSO) else if !RC! EQU 1 (set RESUMO=!RESUMO! %%T:PARCIAL) else (set RESUMO=!RESUMO! %%T:FALHA)
    if !RC! GTR !EXIT_CODE! set EXIT_CODE=!RC!
)

call :LOG ""
call :LOG "============================================================"
call :LOG " RESUMO GERAL - ChirpStack v3:%RESUMO%"
call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b %EXIT_CODE%


rem ==============================================================
rem  SUB-ROTINA: BACKUP DE UMA BASE
rem  Parametros: service porta database usuario senha
rem  Retorno em RC: 0 sucesso | 1 parcial | 2 falha | 3 port-forward
rem ==============================================================
:BACKUP_BASE
set SVC=%~1
set PORT=%2
set PG_DB=%3
set PG_USER=%4
set PGPASSWORD=%5
set PF_PID=
set RC=0
set STATUS_BACKUP=0
set STATUS_SQL=0
set FILE_BACKUP=%BACKUP_DIR%\%PG_DB%_%TIMESTAMP%.backup
set FILE_SQL=%BACKUP_DIR%\%PG_DB%_%TIMESTAMP%.sql

call :LOG "============================================================"
call :LOG " Iniciando backup: %PG_DB%"
call :LOG " Namespace: %K8S_NAMESPACE% - Service: %SVC%"
call :LOG " Host: %PG_HOST%:%PORT%"
call :LOG " Usuario: %PG_USER%"
call :LOG "============================================================"
for /f "tokens=*" %%v in ('%PG_DUMP% --version 2^>^&1') do call :LOG "Versao: %%v"

rem --- PORT-FORWARD ---
%PG_ISREADY% -h %PG_HOST% -p %PORT% -q >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    call :LOG "Port-forward: porta %PORT% ja esta ativa - reaproveitando."
    goto :PF_OK
)

call :LOG "Port-forward: kubectl port-forward -n %K8S_NAMESPACE% svc/%SVC% %PORT%:%PORT%"
for /f %%p in ('powershell -NoProfile -Command "(Start-Process -FilePath 'kubectl' -ArgumentList 'port-forward','-n','%K8S_NAMESPACE%','svc/%SVC%','%PORT%:%PORT%' -WindowStyle Hidden -PassThru).Id"') do set PF_PID=%%p

set /a TRIES=0
:PF_WAIT
%PG_ISREADY% -h %PG_HOST% -p %PORT% -q >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    call :LOG "  OK - port-forward ativo (PID %PF_PID%)"
    goto :PF_OK
)
set /a TRIES+=1
if !TRIES! GEQ %PF_TIMEOUT% goto :PF_FAIL
timeout /t 1 /nobreak >nul
goto :PF_WAIT

:PF_FAIL
call :LOG "  ERRO - porta %PORT% nao respondeu em %PF_TIMEOUT%s. Verifique o kubeconfig/contexto."
call :FECHAR_PF
call :LOG " STATUS FINAL (%PG_DB%): FALHA - sem conexao"
call :LOG "============================================================"
set PGPASSWORD=
set RC=3
goto :eof

:PF_OK
rem --- BACKUP 1 - Formato CUSTOM (.backup) ---
call :LOG ""
call :LOG "[1/2] Gerando .backup (formato custom)..."
%PG_DUMP% --host=%PG_HOST% --port=%PORT% --username=%PG_USER% --dbname=%PG_DB% --format=custom --blobs --compress=9 --verbose --no-password --file="%FILE_BACKUP%" >> "%LOG_FILE%" 2>&1
set STATUS_BACKUP=!ERRORLEVEL!
if !STATUS_BACKUP! EQU 0 (
    for %%F in ("%FILE_BACKUP%") do call :LOG "  OK - %%~zF bytes - %FILE_BACKUP%"
) else (
    call :LOG "  ERRO - Falha no .backup - codigo: !STATUS_BACKUP!"
)

rem --- BACKUP 2 - Formato PLAIN SQL (.sql) ---
call :LOG ""
call :LOG "[2/2] Gerando .sql (plain SQL)..."
%PG_DUMP% --host=%PG_HOST% --port=%PORT% --username=%PG_USER% --dbname=%PG_DB% --format=plain --blobs --clean --if-exists --create --verbose --no-password --file="%FILE_SQL%" >> "%LOG_FILE%" 2>&1
set STATUS_SQL=!ERRORLEVEL!
if !STATUS_SQL! EQU 0 (
    for %%F in ("%FILE_SQL%") do call :LOG "  OK - %%~zF bytes - %FILE_SQL%"
) else (
    call :LOG "  ERRO - Falha no .sql - codigo: !STATUS_SQL!"
)

call :FECHAR_PF
set PGPASSWORD=

rem --- LIMPEZA DE BACKUPS ANTIGOS ---
if %RETENTION_DAYS% GTR 0 (
    call :LOG ""
    call :LOG "Limpando backups de %PG_DB% com mais de %RETENTION_DAYS% dia(s)..."
    forfiles /P "%BACKUP_DIR%" /M %PG_DB%_*.backup /D -%RETENTION_DAYS% /C "cmd /c del /Q @path" >> "%LOG_FILE%" 2>&1
    forfiles /P "%BACKUP_DIR%" /M %PG_DB%_*.sql    /D -%RETENTION_DAYS% /C "cmd /c del /Q @path" >> "%LOG_FILE%" 2>&1
    forfiles /P "%BACKUP_DIR%" /M backup_*.log     /D -%RETENTION_DAYS% /C "cmd /c del /Q @path" >> "%LOG_FILE%" 2>&1
    call :LOG "  OK - Limpeza concluida."
)

rem --- RESUMO DA BASE ---
call :LOG ""
if !STATUS_BACKUP! EQU 0 if !STATUS_SQL! EQU 0 (
    call :LOG " STATUS FINAL (%PG_DB%): SUCESSO"
    set RC=0
    goto :BACKUP_FIM
)
if !STATUS_BACKUP! NEQ 0 if !STATUS_SQL! NEQ 0 (
    call :LOG " STATUS FINAL (%PG_DB%): FALHA - ambos os arquivos falharam"
    set RC=2
    goto :BACKUP_FIM
)
call :LOG " STATUS FINAL (%PG_DB%): PARCIAL - um arquivo falhou. Verifique o log."
set RC=1
:BACKUP_FIM
call :LOG "============================================================"
goto :eof


rem SUB-ROTINA: FECHAR PORT-FORWARD (somente o que este script abriu)
:FECHAR_PF
if defined PF_PID (
    taskkill /PID %PF_PID% /F >nul 2>&1
    call :LOG "Port-forward encerrado (PID %PF_PID%)."
    set PF_PID=
)
goto :eof


rem SUB-ROTINA DE LOG
:LOG
set MSG=%~1
echo [%DATE_LABEL%] %MSG%
echo [%DATE_LABEL%] %MSG% >> "%LOG_FILE%"
goto :eof
