package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class DeviceProfileService {

    private final ChirpStackClient client;

    public Mono<JsonNode> listDeviceProfiles(int limit, int offset, String search, String tenantId) {
        String uri = String.format("/api/device-profiles?limit=%d&offset=%d&search=%s&tenantId=%s",
                limit, offset, nvl(search), nvl(tenantId));
        return client.get(uri);
    }

    public Mono<JsonNode> createDeviceProfile(Map<String, Object> body) {
        return client.post("/api/device-profiles", body);
    }

    public Mono<JsonNode> getDeviceProfile(String id) {
        return client.get("/api/device-profiles/" + id);
    }

    public Mono<JsonNode> updateDeviceProfile(String id, Map<String, Object> body) {
        return client.put("/api/device-profiles/" + id, body);
    }

    public Mono<JsonNode> deleteDeviceProfile(String id) {
        return client.delete("/api/device-profiles/" + id);
    }

    public Mono<JsonNode> listAdrAlgorithms() {
        return client.get("/api/device-profiles/adr-algorithms");
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }
}
