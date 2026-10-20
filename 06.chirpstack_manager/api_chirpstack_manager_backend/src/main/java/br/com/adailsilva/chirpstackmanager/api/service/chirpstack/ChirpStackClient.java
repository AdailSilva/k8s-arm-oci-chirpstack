package br.com.adailsilva.chirpstackmanager.api.service.chirpstack;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriBuilder;

import br.com.adailsilva.chirpstackmanager.api.config.ChirpStackProperties;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.JsonNodeFactory;

/**
 * Cliente da REST API do ChirpStack v4.
 * <p>
 * Envia a API key no cabeçalho {@code Grpc-Metadata-Authorization} (o mesmo usado pelo Swagger da
 * chirpstack-rest-api) e converte qualquer resposta de erro em {@link ChirpStackException}.
 * Os caminhos são sempre montados com variáveis de URI, que são codificadas pelo Spring.
 */
@Component
public class ChirpStackClient {

    private static final Logger log = LoggerFactory.getLogger(ChirpStackClient.class);

    private final RestClient rest;
    private final JsonMapper mapper;
    private final ChirpStackProperties props;

    public ChirpStackClient(RestClient.Builder builder, ChirpStackProperties props, JsonMapper mapper) {
        this.props = props;
        this.mapper = mapper;

        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(props.connectTimeout())
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();
        JdkClientHttpRequestFactory requestFactory = new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(props.readTimeout());

        this.rest = builder
                .baseUrl(props.baseUrl())
                .requestFactory(requestFactory)
                .defaultHeader("Grpc-Metadata-Authorization", "Bearer " + (props.hasToken() ? props.apiToken() : ""))
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .defaultStatusHandler(HttpStatusCode::isError, (request, response) -> {
                    throw toException(response);
                })
                .build();

        if (!props.hasToken()) {
            log.warn("CHIRPSTACK_API_TOKEN não configurado: as chamadas ao ChirpStack serão recusadas.");
        }
        log.info("ChirpStack REST API: {}", props.baseUrl());
    }

    public int maxPageSize() {
        return props.maxPageSize();
    }

    public JsonNode get(String path, Query query, Object... uriVars) {
        return execute(() -> rest.get()
                .uri(b -> build(b, path, query, uriVars))
                .retrieve()
                .body(JsonNode.class));
    }

    public JsonNode post(String path, JsonNode body, Object... uriVars) {
        return execute(() -> rest.post()
                .uri(b -> build(b, path, null, uriVars))
                .contentType(MediaType.APPLICATION_JSON)
                .body(body != null ? body : JsonNodeFactory.instance.objectNode())
                .retrieve()
                .body(JsonNode.class));
    }

    public JsonNode put(String path, JsonNode body, Object... uriVars) {
        return execute(() -> rest.put()
                .uri(b -> build(b, path, null, uriVars))
                .contentType(MediaType.APPLICATION_JSON)
                .body(body != null ? body : JsonNodeFactory.instance.objectNode())
                .retrieve()
                .body(JsonNode.class));
    }

    public JsonNode delete(String path, Object... uriVars) {
        return execute(() -> rest.delete()
                .uri(b -> build(b, path, null, uriVars))
                .retrieve()
                .body(JsonNode.class));
    }

    private static URI build(UriBuilder b, String path, Query query, Object... uriVars) {
        b.path(path);
        if (query != null) {
            for (Map.Entry<String, Object> e : query.asMap().entrySet()) {
                b.queryParam(e.getKey(), e.getValue());
            }
        }
        return b.build(uriVars);
    }

    private JsonNode execute(Call call) {
        if (!props.hasToken()) {
            throw new ChirpStackException(401, 16, "API key do ChirpStack não configurada no backend");
        }
        try {
            JsonNode result = call.run();
            return result != null ? result : JsonNodeFactory.instance.objectNode();
        } catch (ResourceAccessException e) {
            log.error("Falha de comunicação com o ChirpStack: {}", e.getMessage());
            throw new ChirpStackException(503, 14, "Não foi possível conectar ao ChirpStack");
        }
    }

    private ChirpStackException toException(ClientHttpResponse response) throws IOException {
        int status = response.getStatusCode().value();
        String raw = new String(response.getBody().readAllBytes(), StandardCharsets.UTF_8);
        Integer code = null;
        String message = null;
        try {
            JsonNode node = mapper.readTree(raw);
            if (node != null && node.has("code")) {
                code = node.get("code").asInt();
            }
            if (node != null && node.has("message")) {
                message = node.get("message").asString();
            }
        } catch (RuntimeException ignored) {
            message = raw.length() > 300 ? raw.substring(0, 300) : raw;
        }
        log.debug("ChirpStack erro HTTP {} gRPC {}: {}", status, code, message);
        return new ChirpStackException(status, code, message);
    }

    @FunctionalInterface
    private interface Call {
        JsonNode run();
    }
}
