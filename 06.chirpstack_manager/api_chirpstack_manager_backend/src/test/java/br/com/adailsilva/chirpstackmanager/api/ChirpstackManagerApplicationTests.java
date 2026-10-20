package br.com.adailsilva.chirpstackmanager.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;

import br.com.adailsilva.chirpstackmanager.api.web.AuditoriaInterceptor;
import br.com.adailsilva.chirpstackmanager.api.repository.UsuarioRepository;

/**
 * Sobe o contexto completo com H2 em memória: valida migrations (Flyway + Hibernate validate),
 * configuração de segurança e criação do primeiro administrador.
 */
@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:teste;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
        "app.chirpstack.api-token=token-de-teste",
        "app.security.jwt-secret=segredo-de-teste-com-mais-de-32-caracteres-123",
        "app.security.bootstrap-admin-email=admin@teste.local",
        "app.security.bootstrap-admin-password=Admin12345"
})
class ChirpstackManagerApplicationTests {

    @Autowired
    UsuarioRepository usuarios;

    @Autowired
    PasswordEncoder encoder;

    @Test
    void contextoSobeECriaAdministrador() {
        var admin = usuarios.findByEmailIgnoreCase("admin@teste.local");
        assertThat(admin).isPresent();
        assertThat(encoder.matches("Admin12345", admin.get().getSenhaHash())).isTrue();
    }

    @Test
    void classificaAcoesDeAuditoria() {
        assertThat(AuditoriaInterceptor.acao("POST", "/api/v1/chirpstack/devices/0102030405060708/queue")).isEqualTo("ENFILEIRAR");
        assertThat(AuditoriaInterceptor.acao("DELETE", "/api/v1/chirpstack/gateways/0102030405060708")).isEqualTo("EXCLUIR");
        assertThat(AuditoriaInterceptor.acao("POST", "/api/v1/chirpstack/devices/0102030405060708/get-random-dev-addr")).isEqualTo("CONSULTAR");
    }
}
