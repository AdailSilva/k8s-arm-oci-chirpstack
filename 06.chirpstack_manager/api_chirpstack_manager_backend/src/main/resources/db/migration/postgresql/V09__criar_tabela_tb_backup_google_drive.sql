-- =====================================================================
--  V09 - Destino Google Drive dos backups (linha única, id = 1)
--
--  Nunca há senha do Google aqui. O que fica é o REFRESH TOKEN devolvido
--  pelo consentimento OAuth, CIFRADO com AES-256-GCM (chave fora do banco,
--  em APP_CHAVE_CIFRAGEM). O Client Secret também é gravado cifrado.
--  Escopo pedido: drive.file -- o sistema só enxerga o que ele mesmo criou.
--
--  pasta_nome    : caminho no Drive, com níveis ("ChirpStack Manager/Backups")
--  pasta_id      : id da última pasta; refeito sozinho se for apagada
--  enviar_manuais: backups gerados pela tela também vão para o Drive
--  retencao_dias : apaga do Drive os mais velhos (0 = nunca)
--  manter_minimo : os N mais recentes de cada formato nunca são apagados
--  oauth_state   : nonce anti-CSRF da autorização em andamento (10 minutos)
-- =====================================================================
CREATE TABLE tb_backup_google_drive (
    id                     SMALLINT       NOT NULL DEFAULT 1,
    client_id              VARCHAR(255),
    client_secret_cifrado  VARCHAR(1024),
    conta_email            VARCHAR(255),
    conta_nome             VARCHAR(255),
    refresh_token_cifrado  VARCHAR(2048),
    conectado_em           TIMESTAMP WITH TIME ZONE,
    conectado_por          VARCHAR(160),
    erro_conexao           VARCHAR(1000),
    pasta_nome             VARCHAR(200)   NOT NULL DEFAULT 'ChirpStack Manager/Backups',
    pasta_id               VARCHAR(200),
    enviar_manuais         BOOLEAN        NOT NULL DEFAULT FALSE,
    retencao_dias          INTEGER        NOT NULL DEFAULT 30,
    manter_minimo          INTEGER        NOT NULL DEFAULT 5,
    oauth_state            VARCHAR(100),
    oauth_state_expira     TIMESTAMP WITH TIME ZONE,
    oauth_state_usuario    VARCHAR(160),
    ultimo_envio_em        TIMESTAMP WITH TIME ZONE,
    ultimo_envio_status    VARCHAR(20),
    ultimo_envio_mensagem  VARCHAR(1000),
    atualizado_em          TIMESTAMP WITH TIME ZONE NOT NULL,
    atualizado_por         VARCHAR(160),
    CONSTRAINT pk_tb_backup_google_drive PRIMARY KEY (id),
    CONSTRAINT ck_tb_backup_google_drive_unico CHECK (id = 1),
    CONSTRAINT ck_tb_backup_google_drive_retencao CHECK (retencao_dias BETWEEN 0 AND 3650),
    CONSTRAINT ck_tb_backup_google_drive_minimo CHECK (manter_minimo BETWEEN 1 AND 100)
);

INSERT INTO tb_backup_google_drive (id, pasta_nome, enviar_manuais, retencao_dias, manter_minimo, atualizado_em)
VALUES (1, 'ChirpStack Manager/Backups', FALSE, 30, 5, CURRENT_TIMESTAMP);
-- =====================================================================
--  Fim da V09
-- =====================================================================
