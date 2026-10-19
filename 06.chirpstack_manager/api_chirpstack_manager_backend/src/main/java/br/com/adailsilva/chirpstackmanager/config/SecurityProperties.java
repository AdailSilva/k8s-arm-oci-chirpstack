package br.com.adailsilva.chirpstackmanager.config;

import java.time.Duration;
import java.util.Arrays;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configurações de segurança (prefixo {@code app.security}).
 */
@ConfigurationProperties(prefix = "app.security")
public record SecurityProperties(
        String jwtSecret,
        String jwtIssuer,
        Duration accessTokenTtl,
        Duration refreshTokenTtl,
        Integer maxLoginAttempts,
        Duration lockoutDuration,
        String corsAllowedOrigins,
        Boolean cookieSecure,
        String bootstrapAdminEmail,
        String bootstrapAdminPassword) {

    public SecurityProperties {
        if (jwtIssuer == null || jwtIssuer.isBlank()) {
            jwtIssuer = "chirpstack-manager";
        }
        if (accessTokenTtl == null) {
            accessTokenTtl = Duration.ofMinutes(15);
        }
        if (refreshTokenTtl == null) {
            refreshTokenTtl = Duration.ofDays(7);
        }
        if (maxLoginAttempts == null || maxLoginAttempts < 1) {
            maxLoginAttempts = 5;
        }
        if (lockoutDuration == null) {
            lockoutDuration = Duration.ofMinutes(15);
        }
        if (cookieSecure == null) {
            cookieSecure = Boolean.TRUE;
        }
    }

    public List<String> corsOrigins() {
        if (corsAllowedOrigins == null || corsAllowedOrigins.isBlank()) {
            return List.of();
        }
        return Arrays.stream(corsAllowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }
}
