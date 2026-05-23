package br.com.adailsilva.chirpstack.consumer.client;

import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.fasterxml.jackson.databind.JsonNode;

import reactor.core.publisher.Mono;

@Component
public class ChirpStackClient {

    private final WebClient webClient;

    public ChirpStackClient(WebClient chirpStackWebClient) {
        this.webClient = chirpStackWebClient;
    }

    public Mono<JsonNode> get(String uri) {
        return webClient.get()
                .uri(uri)
                .retrieve()
                .bodyToMono(JsonNode.class);
    }

    public Mono<JsonNode> post(String uri, Object body) {
        return webClient.post()
                .uri(uri)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(JsonNode.class);
    }

    public Mono<JsonNode> put(String uri, Object body) {
        return webClient.put()
                .uri(uri)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(JsonNode.class);
    }

    public Mono<JsonNode> delete(String uri) {
        return webClient.method(HttpMethod.DELETE)
                .uri(uri)
                .retrieve()
                .bodyToMono(JsonNode.class);
    }

    public Mono<JsonNode> postEmpty(String uri) {
        return webClient.post()
                .uri(uri)
                .retrieve()
                .bodyToMono(JsonNode.class);
    }
}
