package br.com.adailsilva.chirpstackmanager.api.config;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.List;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import br.com.adailsilva.chirpstackmanager.api.security.filter.SessaoAtivaFilter;
import br.com.adailsilva.chirpstackmanager.api.exception.SessaoEncerradaException;
import br.com.adailsilva.chirpstackmanager.api.service.SessaoService;

/**
 * Segurança da API:
 * <ul>
 *   <li>sem sessão no servidor (stateless), autenticação por JWT HS256 assinado pelo próprio backend;</li>
 *   <li>autorização por perfil com {@code @PreAuthorize} em cada operação;</li>
 *   <li>CORS restrito às origens configuradas;</li>
 *   <li>cabeçalhos de segurança (HSTS, no-sniff, frame deny, referrer policy, CSP).</li>
 * </ul>
 * CSRF fica desligado porque a API não usa cookie para autenticar (só o refresh, com SameSite=Strict).
 * <p>
 * Depois do JWT, o {@link SessaoAtivaFilter} confere se a sessão do token continua aberta: um
 * encerramento pelo administrador (ou por inatividade) vale na hora, sem esperar o token vencer.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private static final Logger log = LoggerFactory.getLogger(SecurityConfig.class);

    private static final String[] PUBLICOS = {
            "/api/v1/auth/login",
            "/api/v1/auth/refresh",
            "/api/v1/auth/logout",
            // Retorno do consentimento do Google: o navegador volta sem o cabeçalho Authorization.
            // A proteção é o "state" de uso único conferido no banco.
            "/api/v1/backup/google-drive/callback",
            "/actuator/health",
            "/actuator/health/**",
            "/actuator/info",
            "/error"
    };

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthenticationConverter jwtConverter,
                                            SessaoService sessoes) throws Exception {
        http
                .addFilterAfter(new SessaoAtivaFilter(sessoes), BearerTokenAuthenticationFilter.class)
                .csrf(csrf -> csrf.disable())
                .cors(cors -> {
                })
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(f -> f.disable())
                .httpBasic(b -> b.disable())
                .logout(l -> l.disable())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers(PUBLICOS).permitAll()
                        .requestMatchers("/api/**").authenticated()
                        .anyRequest().denyAll())
                .oauth2ResourceServer(o -> o
                        .jwt(j -> j.jwtAuthenticationConverter(jwtConverter))
                        .authenticationEntryPoint((req, res, ex) -> escreverErro(res, HttpStatus.UNAUTHORIZED,
                                "NAO_AUTENTICADO", "Sessão expirada ou inválida. Entre novamente."))
                        .accessDeniedHandler((req, res, ex) -> escreverErro(res, HttpStatus.FORBIDDEN,
                                "ACESSO_NEGADO", "Seu perfil não tem permissão para esta operação.")))
                .exceptionHandling(e -> e
                        .authenticationEntryPoint((req, res, ex) -> escreverErro(res, HttpStatus.UNAUTHORIZED,
                                "NAO_AUTENTICADO", "Sessão expirada ou inválida. Entre novamente.")))
                .headers(h -> h
                        .contentTypeOptions(c -> {
                        })
                        .frameOptions(f -> f.deny())
                        .httpStrictTransportSecurity(hsts -> hsts.includeSubDomains(true).maxAgeInSeconds(31_536_000))
                        .referrerPolicy(r -> r.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER))
                        .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'none'; frame-ancestors 'none'")));
        return http.build();
    }

    private static void escreverErro(jakarta.servlet.http.HttpServletResponse res, HttpStatus status, String erro,
                                     String mensagem) throws java.io.IOException {
        res.setStatus(status.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding(StandardCharsets.UTF_8.name());
        res.getWriter().write("{\"status\":" + status.value() + ",\"erro\":\"" + erro + "\",\"mensagem\":\""
                + mensagem + "\"}");
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter roles = new JwtGrantedAuthoritiesConverter();
        roles.setAuthoritiesClaimName("roles");
        roles.setAuthorityPrefix("ROLE_");
        JwtAuthenticationConverter conv = new JwtAuthenticationConverter();
        conv.setJwtGrantedAuthoritiesConverter(roles);
        return conv;
    }

    @Bean
    SecretKey jwtSecretKey(SecurityProperties props, Environment env) {
        String secret = props.jwtSecret();
        if (secret == null || secret.isBlank()) {
            if (env.acceptsProfiles(Profiles.of("production"))) {
                throw new IllegalStateException("APP_JWT_SECRET é obrigatório no perfil production (mínimo de 32 caracteres).");
            }
            byte[] bytes = new byte[48];
            new SecureRandom().nextBytes(bytes);
            secret = Base64.getEncoder().encodeToString(bytes);
            log.warn("APP_JWT_SECRET não definido: usando segredo aleatório (as sessões caem a cada reinício).");
        }
        byte[] key = secret.getBytes(StandardCharsets.UTF_8);
        if (key.length < 32) {
            throw new IllegalStateException("APP_JWT_SECRET precisa ter pelo menos 32 caracteres.");
        }
        return new SecretKeySpec(key, "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey jwtSecretKey) {
        return NimbusJwtEncoder.withSecretKey(jwtSecretKey).algorithm(MacAlgorithm.HS256).build();
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey jwtSecretKey, SecurityProperties props) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(jwtSecretKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(props.jwtIssuer()));
        return decoder;
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(SecurityProperties props) {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(props.corsOrigins());
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        cfg.setExposedHeaders(List.of(SessaoEncerradaException.HEADER, SessaoEncerradaException.HEADER_MOTIVO,
                "Content-Disposition"));
        cfg.setAllowCredentials(true);
        cfg.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", cfg);
        return source;
    }
}
