-- =====================================================================
--  V07 - Execuções de backup e restauração
--  Estado compartilhado entre réplicas: quem inicia num pod consegue
--  acompanhar o progresso consultando qualquer outro. Também é o
--  histórico (manuais e agendados).
--
--  tipo        : BACKUP ou RESTORE
--  origem      : MANUAL (tela), AGENDADO (relógio) ou EXECUTAR_AGORA
--  status      : PENDENTE, EXECUTANDO, SUCESSO, PARCIAL, ERRO, IGNORADO
--                (IGNORADO = horário agendado pulado porque já havia
--                outra operação em andamento)
--  arquivos    : nomes gerados/restaurados, um por linha
--  drive_*     : resultado do envio ao Google Drive, quando pedido
--  removidos   : arquivos apagados pela retenção nesta execução
--  instancia   : pod (HOSTNAME) que executou
-- =====================================================================
CREATE TABLE tb_backup_job (
    id                VARCHAR(36)   NOT NULL,
    tipo              VARCHAR(10)   NOT NULL,
    origem            VARCHAR(20)   NOT NULL,
    status            VARCHAR(20)   NOT NULL,
    progresso         INTEGER       NOT NULL DEFAULT 0,
    mensagem          VARCHAR(500),
    erro              VARCHAR(2000),
    formatos          VARCHAR(30),
    arquivos          VARCHAR(2000),
    tamanho_bytes     BIGINT,
    enviar_drive      BOOLEAN       NOT NULL DEFAULT FALSE,
    drive_status      VARCHAR(20),
    drive_mensagem    VARCHAR(1000),
    removidos         INTEGER       NOT NULL DEFAULT 0,
    solicitado_por    VARCHAR(160),
    instancia         VARCHAR(120),
    agendado_para     TIMESTAMP WITH TIME ZONE,
    criado_em         TIMESTAMP WITH TIME ZONE NOT NULL,
    iniciado_em       TIMESTAMP WITH TIME ZONE,
    finalizado_em     TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_tb_backup_job PRIMARY KEY (id),
    CONSTRAINT ck_tb_backup_job_tipo CHECK (tipo IN ('BACKUP', 'RESTORE')),
    CONSTRAINT ck_tb_backup_job_origem CHECK (origem IN ('MANUAL', 'AGENDADO', 'EXECUTAR_AGORA')),
    CONSTRAINT ck_tb_backup_job_status CHECK (status IN ('PENDENTE', 'EXECUTANDO', 'SUCESSO', 'PARCIAL', 'ERRO', 'IGNORADO')),
    CONSTRAINT ck_tb_backup_job_progresso CHECK (progresso BETWEEN 0 AND 100)
);
CREATE INDEX ix_tb_backup_job_criado_em ON tb_backup_job (criado_em);
CREATE INDEX ix_tb_backup_job_status ON tb_backup_job (status);
-- =====================================================================
--  Fim da V07
-- =====================================================================
