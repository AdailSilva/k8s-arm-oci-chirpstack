package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class DeviceProfileTemplateService {

    private final ChirpStackClient client;

    public Mono<JsonNode> listTemplates(int limit, int offset) {
        return client.get(String.format("/api/device-profile-templates?limit=%d&offset=%d", limit, offset));
    }

    public Mono<JsonNode> createTemplate(Map<String, Object> body) {
        return client.post("/api/device-profile-templates", body);
    }

    public Mono<JsonNode> getTemplate(String id) {
        return client.get("/api/device-profile-templates/" + id);
    }

    public Mono<JsonNode> updateTemplate(String id, Map<String, Object> body) {
        return client.put("/api/device-profile-templates/" + id, body);
    }

    public Mono<JsonNode> deleteTemplate(String id) {
        return client.delete("/api/device-profile-templates/" + id);
    }
}
