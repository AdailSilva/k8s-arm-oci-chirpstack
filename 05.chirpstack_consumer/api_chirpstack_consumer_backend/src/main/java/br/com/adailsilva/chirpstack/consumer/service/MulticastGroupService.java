package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class MulticastGroupService {

    private final ChirpStackClient client;

    // ── Groups ─────────────────────────────────────────────────────────────────

    public Mono<JsonNode> listGroups(int limit, int offset, String search, String applicationId) {
        String uri = String.format("/api/multicast-groups?limit=%d&offset=%d&search=%s&applicationId=%s",
                limit, offset, nvl(search), nvl(applicationId));
        return client.get(uri);
    }

    public Mono<JsonNode> createGroup(Map<String, Object> body) {
        return client.post("/api/multicast-groups", body);
    }

    public Mono<JsonNode> getGroup(String id) {
        return client.get("/api/multicast-groups/" + id);
    }

    public Mono<JsonNode> updateGroup(String id, Map<String, Object> body) {
        return client.put("/api/multicast-groups/" + id, body);
    }

    public Mono<JsonNode> deleteGroup(String id) {
        return client.delete("/api/multicast-groups/" + id);
    }

    // ── Devices ────────────────────────────────────────────────────────────────

    public Mono<JsonNode> addDevice(String groupId, Map<String, Object> body) {
        return client.post("/api/multicast-groups/" + groupId + "/devices", body);
    }

    public Mono<JsonNode> removeDevice(String groupId, String devEui) {
        return client.delete("/api/multicast-groups/" + groupId + "/devices/" + devEui);
    }

    // ── Gateways ───────────────────────────────────────────────────────────────

    public Mono<JsonNode> addGateway(String groupId, Map<String, Object> body) {
        return client.post("/api/multicast-groups/" + groupId + "/gateways", body);
    }

    public Mono<JsonNode> removeGateway(String groupId, String gatewayId) {
        return client.delete("/api/multicast-groups/" + groupId + "/gateways/" + gatewayId);
    }

    // ── Queue ──────────────────────────────────────────────────────────────────

    public Mono<JsonNode> enqueue(String groupId, Map<String, Object> body) {
        return client.post("/api/multicast-groups/" + groupId + "/queue", body);
    }

    public Mono<JsonNode> listQueue(String groupId) {
        return client.get("/api/multicast-groups/" + groupId + "/queue");
    }

    public Mono<JsonNode> flushQueue(String groupId) {
        return client.delete("/api/multicast-groups/" + groupId + "/queue");
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }
}
