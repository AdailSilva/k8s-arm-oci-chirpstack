-- =====================================================================
--  V05 - Sessões (visitantes e controle de logoff)
--  Uma linha por login bem-sucedido. É ao mesmo tempo:
--    - o registro de visitantes (quem entrou, quando, de onde e em quê);
--    - a sessão viva: o access token carrega o id (claim "sid") e cada
--      requisição confere se a sessão continua aberta, de modo que um
--      encerramento pelo ADMIN vale na hora, sem esperar o token vencer.
--
--  ultima_atividade : última interação do usuário (teclado, mouse, toque)
--                     informada pelo navegador; base da inatividade.
--  ultimo_sinal     : último contato do navegador (aba aberta); base do
--                     "on-line agora".
--  usuario_nome/email: retrato do usuário no login, para o histórico
--                     continuar legível depois que ele for alterado ou
--                     excluído (usuario_id vira NULL).
--  motivo_encerramento: LOGOUT, INATIVIDADE, EXPIRADA, ENCERRADA_ADMIN,
--                     LIMITE_SESSOES, SENHA_ALTERADA, USUARIO_DESATIVADO,
--                     USUARIO_BLOQUEADO, USUARIO_EXCLUIDO, REUSO_TOKEN,
--                     RESTAURACAO_BACKUP.
-- =====================================================================
CREATE TABLE tb_sessao (
    id                   VARCHAR(36)   NOT NULL,
    usuario_id           BIGINT,
    usuario_nome         VARCHAR(120)  NOT NULL,
    usuario_email        VARCHAR(160)  NOT NULL,
    ip                   VARCHAR(64),
    user_agent           VARCHAR(255),
    dispositivo          VARCHAR(120),
    iniciada_em          TIMESTAMP WITH TIME ZONE NOT NULL,
    ultima_atividade     TIMESTAMP WITH TIME ZONE NOT NULL,
    ultimo_sinal         TIMESTAMP WITH TIME ZONE NOT NULL,
    expira_em            TIMESTAMP WITH TIME ZONE NOT NULL,
    encerrada_em         TIMESTAMP WITH TIME ZONE,
    motivo_encerramento  VARCHAR(30),
    encerrada_por        VARCHAR(160),
    CONSTRAINT pk_tb_sessao PRIMARY KEY (id),
    CONSTRAINT fk_tb_sessao_usuario FOREIGN KEY (usuario_id) REFERENCES tb_usuario (id) ON DELETE SET NULL
);
CREATE INDEX ix_tb_sessao_usuario ON tb_sessao (usuario_id);
CREATE INDEX ix_tb_sessao_iniciada_em ON tb_sessao (iniciada_em);
CREATE INDEX ix_tb_sessao_encerrada_em ON tb_sessao (encerrada_em);

-- O refresh token passa a pertencer a uma sessão: a rotação mantém o mesmo
-- sessao_id e encerrar a sessão revoga os tokens dela.
ALTER TABLE tb_refresh_token ADD COLUMN sessao_id VARCHAR(36);
CREATE INDEX ix_tb_refresh_token_sessao ON tb_refresh_token (sessao_id);
-- =====================================================================
--  Fim da V05
-- =====================================================================
