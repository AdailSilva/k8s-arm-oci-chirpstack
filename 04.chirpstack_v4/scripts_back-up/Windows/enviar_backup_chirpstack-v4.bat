@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  ENVIO DE BACKUP DIARIO - chirpstack
rem  Requer: OpenSSH (nativo Windows 10/11) + chave SSH configurada
rem  Destino: Servidor REMOTO NA INTERNET
rem  Como usar: Execute apos o backup_chirpstack-v4.bat
rem             OU integre chamando este script no final do outro
rem ============================================================

rem ============================================================
rem  CONFIGURACOES - EDITE AQUI
rem ============================================================

rem --- Origem (deve ser o mesmo do backup_chirpstack-v4.bat) ---
set BACKUP_DIR=D:\ChirpStack-v4_Back-UPs
set PG_DB=chirpstack

rem --- Destino Remoto (servidor na internet) ---
set SSH_USER=seu_usuario
set SSH_HOST=seu.servidor.com.br
set SSH_PORT=22
rem     DICA DE SEGURANCA: troque a porta 22 por outra (ex: 2222) no servidor
rem     para reduzir ataques de força bruta automatizados
set REMOTE_DIR=/home/seu_usuario/backups/chirpstack-v4
set SSH_KEY=C:\Users\%USERNAME%\.ssh\id_ed25519
rem     RECOMENDADO para internet: ed25519 é mais seguro e moderno que rsa

rem --- Timeout de conexao (segundos) - importante para internet ---
set CONNECT_TIMEOUT=30

rem --- Retencao remota (0 = nao apagar nada) ---
set RETENTION_DAYS=30

rem --- Enviar apenas os arquivos gerados HOJE? ---
rem     1 = sim (mais rapido, ideal para cron diario)
rem     0 = nao (reenvia tudo, util para recuperacao)
set ONLY_TODAY=1

rem ============================================================

rem TIMESTAMP
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set DATE_LABEL=%%i
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set TODAY=%%i

set LOG_FILE=%BACKUP_DIR%\envio_%TODAY%.log

rem ============================================================

call :LOG "============================================================"
call :LOG " Iniciando envio de backup: %PG_DB%"
call :LOG " Destino: %SSH_USER%@%SSH_HOST%:%REMOTE_DIR%"
call :LOG "============================================================"

rem --- Verificar OpenSSH ---
where ssh >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :LOG "ERRO: OpenSSH nao encontrado. Instale via: Configuracoes > Apps > Recursos opcionais > OpenSSH Client"
    goto :ERRO
)

rem --- Verificar chave SSH ---
if not exist "%SSH_KEY%" (
    call :LOG "ERRO: Chave SSH nao encontrada em %SSH_KEY%"
    call :LOG "  Gere com: ssh-keygen -t ed25519 -C backup_chirpstack-v4"
    call :LOG "  Copie ao servidor: ssh-copy-id -p %SSH_PORT% %SSH_USER%@%SSH_HOST%"
    call :LOG "  Ou manualmente: adicione id_ed25519.pub ao ~/.ssh/authorized_keys no servidor"
    goto :ERRO
)

rem --- Verificar conectividade com o servidor ---
call :LOG ""
call :LOG "Testando conexao com %SSH_HOST%:%SSH_PORT%..."
ssh -i "%SSH_KEY%" -p %SSH_PORT% -o ConnectTimeout=%CONNECT_TIMEOUT% -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -o ServerAliveCountMax=3 %SSH_USER%@%SSH_HOST% "echo OK" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :LOG "ERRO: Nao foi possivel conectar ao servidor."
    call :LOG "  Verifique: host, porta, usuario e se a chave publica esta no servidor."
    goto :ERRO
)
call :LOG "  Conexao OK."

rem --- Criar diretorio remoto se nao existir ---
call :LOG ""
call :LOG "Verificando diretorio remoto..."
ssh -i "%SSH_KEY%" -p %SSH_PORT% -o BatchMode=yes %SSH_USER%@%SSH_HOST% "mkdir -p %REMOTE_DIR%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :LOG "AVISO: Nao foi possivel criar/verificar o diretorio remoto. Continuando..."
)

rem --- Selecionar arquivos para envio ---
call :LOG ""
if %ONLY_TODAY% EQU 1 (
    call :LOG "Buscando arquivos de hoje (%TODAY%)..."
    set PATTERN=*%TODAY%*
) else (
    call :LOG "Buscando todos os arquivos de backup..."
    set PATTERN=*%PG_DB%*
)

set COUNT=0
set ERRORS=0

rem --- Enviar arquivos .backup ---
for %%F in ("%BACKUP_DIR%\!PATTERN!.backup") do (
    set /a COUNT+=1
    call :LOG ""
    call :LOG "[%%~nxF] Enviando..."
    scp -i "%SSH_KEY%" -P %SSH_PORT% -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=%CONNECT_TIMEOUT% -o ServerAliveInterval=30 "%%F" "%SSH_USER%@%SSH_HOST%:%REMOTE_DIR%/" >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! EQU 0 (
        call :LOG "  OK - Enviado com sucesso."
    ) else (
        call :LOG "  ERRO - Falha ao enviar %%~nxF"
        set /a ERRORS+=1
    )
)

rem --- Enviar arquivos .sql ---
for %%F in ("%BACKUP_DIR%\!PATTERN!.sql") do (
    set /a COUNT+=1
    call :LOG ""
    call :LOG "[%%~nxF] Enviando..."
    scp -i "%SSH_KEY%" -P %SSH_PORT% -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=%CONNECT_TIMEOUT% -o ServerAliveInterval=30 "%%F" "%SSH_USER%@%SSH_HOST%:%REMOTE_DIR%/" >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! EQU 0 (
        call :LOG "  OK - Enviado com sucesso."
    ) else (
        call :LOG "  ERRO - Falha ao enviar %%~nxF"
        set /a ERRORS+=1
    )
)

if %COUNT% EQU 0 (
    call :LOG ""
    call :LOG "AVISO: Nenhum arquivo encontrado para enviar com o padrao '!PATTERN!'."
    call :LOG "  Verifique se o backup_chirpstack-v4.bat foi executado antes deste script."
    goto :ERRO
)

rem --- Limpeza remota de arquivos antigos ---
if %RETENTION_DAYS% GTR 0 (
    call :LOG ""
    call :LOG "Limpando backups remotos com mais de %RETENTION_DAYS% dia(s)..."
    ssh -i "%SSH_KEY%" -p %SSH_PORT% -o BatchMode=yes %SSH_USER%@%SSH_HOST% "find %REMOTE_DIR% -name '*.backup' -o -name '*.sql' | xargs -I{} find {} -mtime +%RETENTION_DAYS% -delete 2>/dev/null; find %REMOTE_DIR% -mtime +%RETENTION_DAYS% -name '*.backup' -delete 2>/dev/null; find %REMOTE_DIR% -mtime +%RETENTION_DAYS% -name '*.sql' -delete 2>/dev/null" >> "%LOG_FILE%" 2>&1
    call :LOG "  Limpeza remota concluida."
)

rem --- Resumo ---
call :LOG ""
call :LOG "============================================================"
call :LOG " Arquivos processados : %COUNT%"
call :LOG " Erros               : %ERRORS%"

if %ERRORS% EQU 0 (
    call :LOG " STATUS FINAL: SUCESSO"
) else if %ERRORS% EQU %COUNT% (
    call :LOG " STATUS FINAL: FALHA - todos os envios falharam"
) else (
    call :LOG " STATUS FINAL: PARCIAL - alguns envios falharam"
)

call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b 0

:ERRO
call :LOG ""
call :LOG "============================================================"
call :LOG " STATUS FINAL: FALHA CRITICA"
call :LOG " Log: %LOG_FILE%"
call :LOG "============================================================"
endlocal & exit /b 99

rem --- Sub-rotina de log ---
:LOG
set MSG=%~1
echo [%DATE_LABEL%] %MSG%
echo [%DATE_LABEL%] %MSG% >> "%LOG_FILE%"
goto :eof
