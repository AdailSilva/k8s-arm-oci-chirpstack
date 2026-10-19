package br.com.adailsilva.chirpstackmanager.usuario;

/**
 * Perfis de acesso ao painel.
 */
public enum Perfil {
    /** Acesso total, inclusive tenants, usuários e auditoria. */
    ADMIN,
    /** Cria, altera e exclui recursos de rede (aplicações, dispositivos, gateways...). */
    OPERADOR,
    /** Somente leitura. */
    VISUALIZADOR
}
