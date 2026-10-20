package br.com.adailsilva.chirpstackmanager.api.config;

import java.security.SecureRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import br.com.adailsilva.chirpstackmanager.api.domain.enums.Perfil;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Usuario;
import br.com.adailsilva.chirpstackmanager.api.repository.UsuarioRepository;

/**
 * Cria o primeiro administrador quando a base está vazia.
 * Usa {@code APP_ADMIN_EMAIL}/{@code APP_ADMIN_PASSWORD}; sem senha definida, gera uma aleatória e
 * mostra uma única vez no log.
 */
@Component
public class AdminBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);
    private static final String ALFABETO = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";

    private final UsuarioRepository repository;
    private final PasswordEncoder encoder;
    private final SecurityProperties props;

    public AdminBootstrap(UsuarioRepository repository, PasswordEncoder encoder, SecurityProperties props) {
        this.repository = repository;
        this.encoder = encoder;
        this.props = props;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (repository.count() > 0) {
            return;
        }
        String senha = props.bootstrapAdminPassword();
        boolean gerada = senha == null || senha.isBlank();
        if (gerada) {
            SecureRandom r = new SecureRandom();
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < 16; i++) {
                sb.append(ALFABETO.charAt(r.nextInt(ALFABETO.length())));
            }
            senha = sb + "9";
        }
        Usuario u = new Usuario();
        u.setNome("Administrador");
        u.setEmail(props.bootstrapAdminEmail().trim().toLowerCase());
        u.setSenhaHash(encoder.encode(senha));
        u.setPerfil(Perfil.ADMIN);
        u.setAtivo(true);
        repository.save(u);
        if (gerada) {
            log.warn("""

                    ================================================================
                     Primeiro administrador criado
                       e-mail: {}
                       senha : {}
                     Troque a senha no primeiro acesso (Meu perfil > Alterar senha).
                    ================================================================""", u.getEmail(), senha);
        } else {
            log.info("Primeiro administrador criado: {}", u.getEmail());
        }
    }
}
