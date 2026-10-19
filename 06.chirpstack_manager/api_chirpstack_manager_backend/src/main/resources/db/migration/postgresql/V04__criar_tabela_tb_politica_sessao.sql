-- =====================================================================
--  V04 - Política de sessão (controle de logoff)
--  Linha única (id = 1) editada pelo ADMIN em Sistema > Controle de sessão.
--
--  inatividade_minutos     : sem interação por esse tempo, a sessão é encerrada
--                            (0 = desligado). O navegador avisa antes e o
--                            servidor confere de novo ao renovar o token.
--  aviso_segundos          : antecedência do aviso "Sua sessão vai expirar".
--  duracao_maxima_horas    : limite absoluto desde o login; depois dele é
--                            preciso entrar de novo, mesmo em uso.
--  max_sessoes_por_usuario : sessões simultâneas por usuário (0 = ilimitado).
--                            Ao passar do limite, a sessão mais antiga cai.
--  manter_conectado        : FALSE = o cookie de renovação some ao fechar o
--                            navegador (logoff ao fechar).
-- =====================================================================
CREATE TABLE tb_politica_sessao (
    id                       SMALLINT      NOT NULL DEFAULT 1,
    inatividade_minutos      INTEGER       NOT NULL DEFAULT 30,
    aviso_segundos           INTEGER       NOT NULL DEFAULT 120,
    duracao_maxima_horas     INTEGER       NOT NULL DEFAULT 12,
    max_sessoes_por_usuario  INTEGER       NOT NULL DEFAULT 0,
    manter_conectado         BOOLEAN       NOT NULL DEFAULT TRUE,
    atualizado_em            TIMESTAMP WITH TIME ZONE NOT NULL,
    atualizado_por           VARCHAR(160),
    CONSTRAINT pk_tb_politica_sessao PRIMARY KEY (id),
    CONSTRAINT ck_tb_politica_sessao_unica CHECK (id = 1),
    CONSTRAINT ck_tb_politica_sessao_inatividade CHECK (inatividade_minutos BETWEEN 0 AND 1440),
    CONSTRAINT ck_tb_politica_sessao_aviso CHECK (aviso_segundos BETWEEN 15 AND 900),
    CONSTRAINT ck_tb_politica_sessao_duracao CHECK (duracao_maxima_horas BETWEEN 1 AND 720),
    CONSTRAINT ck_tb_politica_sessao_simultaneas CHECK (max_sessoes_por_usuario BETWEEN 0 AND 20)
);

INSERT INTO tb_politica_sessao (id, inatividade_minutos, aviso_segundos, duracao_maxima_horas,
                                max_sessoes_por_usuario, manter_conectado, atualizado_em)
VALUES (1, 30, 120, 12, 0, TRUE, CURRENT_TIMESTAMP);
-- =====================================================================
--  Fim da V04
-- =====================================================================
