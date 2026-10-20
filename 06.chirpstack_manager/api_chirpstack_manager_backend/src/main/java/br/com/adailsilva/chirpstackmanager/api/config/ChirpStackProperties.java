package br.com.adailsilva.chirpstackmanager.api.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Conexão com a REST API do ChirpStack (prefixo {@code app.chirpstack}).
 *
 * @param baseUrl        URL da chirpstack-rest-api, sem barra no final
 * @param apiToken       API key (Bearer) gerada no ChirpStack
 * @param connectTimeout tempo máximo para abrir a conexão
 * @param readTimeout    tempo máximo de espera pela resposta
 * @param maxPageSize    limite de itens por página aceito pelo backend
 */
@ConfigurationProperties(prefix = "app.chirpstack")
public record ChirpStackProperties(
        String baseUrl,
        String apiToken,
        Duration connectTimeout,
        Duration readTimeout,
        Integer maxPageSize) {

    public ChirpStackProperties {
        if (baseUrl != null && baseUrl.endsWith("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }
        if (connectTimeout == null) {
            connectTimeout = Duration.ofSeconds(5);
        }
        if (readTimeout == null) {
            readTimeout = Duration.ofSeconds(30);
        }
        if (maxPageSize == null || maxPageSize < 1) {
            maxPageSize = 1000;
        }
    }

    public boolean hasToken() {
        return apiToken != null && !apiToken.isBlank();
    }
}
