-- =====================================================================
--  V06 - Bloqueio manual de acesso (tela de Visitantes)
--  bloqueado_ate já existia para o bloqueio automático por senha errada.
--  Com motivo_bloqueio preenchido o bloqueio foi feito por um ADMIN e o
--  login mostra o motivo e a data de liberação.
-- =====================================================================
ALTER TABLE tb_usuario ADD COLUMN motivo_bloqueio VARCHAR(255);
ALTER TABLE tb_usuario ADD COLUMN bloqueado_por VARCHAR(160);
-- =====================================================================
--  Fim da V06
-- =====================================================================
