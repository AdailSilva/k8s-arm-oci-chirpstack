-- =====================================================================
--  V08 - Backup automático (agendamento)
--  Configuração em linha única (id = 1) e grade semanal de horários.
--
--  formatos         : "backup", "sql" ou "backup,sql"
--  destino_servidor : grava na pasta agendados/ do volume de backups
--  destino_drive    : envia ao Google Drive conectado
--  retencao_dias    : apaga backups agendados mais velhos (0 = nunca)
--  manter_minimo    : os N mais recentes de cada formato nunca são apagados
--  ultimo_disparo   : TRAVA DE EXECUÇÃO ÚNICA. Horário (local) já disparado;
--                     a réplica que consegue avançá-lo com UPDATE condicional
--                     é a única que executa aquele horário.
-- =====================================================================
CREATE TABLE tb_backup_agendamento (
    id                SMALLINT      NOT NULL DEFAULT 1,
    ativo             BOOLEAN       NOT NULL DEFAULT FALSE,
    formatos          VARCHAR(30)   NOT NULL DEFAULT 'backup',
    destino_servidor  BOOLEAN       NOT NULL DEFAULT TRUE,
    destino_drive     BOOLEAN       NOT NULL DEFAULT FALSE,
    retencao_dias     INTEGER       NOT NULL DEFAULT 30,
    manter_minimo     INTEGER       NOT NULL DEFAULT 3,
    ultimo_disparo    TIMESTAMP,
    atualizado_em     TIMESTAMP WITH TIME ZONE NOT NULL,
    atualizado_por    VARCHAR(160),
    CONSTRAINT pk_tb_backup_agendamento PRIMARY KEY (id),
    CONSTRAINT ck_tb_backup_agendamento_unico CHECK (id = 1),
    CONSTRAINT ck_tb_backup_agendamento_destino CHECK (destino_servidor OR destino_drive),
    CONSTRAINT ck_tb_backup_agendamento_retencao CHECK (retencao_dias BETWEEN 0 AND 3650),
    CONSTRAINT ck_tb_backup_agendamento_minimo CHECK (manter_minimo BETWEEN 1 AND 100)
);

INSERT INTO tb_backup_agendamento (id, ativo, formatos, destino_servidor, destino_drive, retencao_dias,
                                   manter_minimo, atualizado_em)
VALUES (1, FALSE, 'backup', TRUE, FALSE, 30, 3, CURRENT_TIMESTAMP);

-- Vários horários por dia. dia_semana no padrão ISO: 1 = segunda ... 7 = domingo.
CREATE TABLE tb_backup_agendamento_horario (
    dia_semana  SMALLINT  NOT NULL,
    hora        TIME      NOT NULL,
    CONSTRAINT pk_tb_backup_agendamento_horario PRIMARY KEY (dia_semana, hora),
    CONSTRAINT ck_tb_backup_agendamento_horario_dia CHECK (dia_semana BETWEEN 1 AND 7)
);
-- =====================================================================
--  Fim da V08
-- =====================================================================
