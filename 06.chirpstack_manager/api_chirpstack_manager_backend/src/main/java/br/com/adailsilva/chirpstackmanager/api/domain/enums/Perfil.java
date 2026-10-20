package br.com.adailsilva.chirpstackmanager.api.domain.enums;

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
