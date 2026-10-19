package br.com.adailsilva.chirpstackmanager.security;

/**
 * Expressões de autorização usadas em {@code @PreAuthorize}.
 * <ul>
 *   <li><b>ADMIN</b>: tudo, inclusive tenants, usuários do ChirpStack, usuários do painel e auditoria;</li>
 *   <li><b>OPERADOR</b>: cria, altera e exclui aplicações, dispositivos, gateways, perfis, multicast e integrações;</li>
 *   <li><b>VISUALIZADOR</b>: somente leitura, sem acesso a chaves, sessões e segredos.</li>
 * </ul>
 */
public final class Perfis {

    public static final String LEITURA = "hasAnyRole('ADMIN','OPERADOR','VISUALIZADOR')";
    public static final String ESCRITA = "hasAnyRole('ADMIN','OPERADOR')";
    public static final String SEGREDOS = "hasAnyRole('ADMIN','OPERADOR')";
    public static final String ADMIN = "hasRole('ADMIN')";

    private Perfis() {
    }
}
