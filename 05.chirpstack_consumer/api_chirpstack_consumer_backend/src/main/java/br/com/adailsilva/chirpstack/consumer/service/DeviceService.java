package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class DeviceService {

    private final ChirpStackClient client;

    // ── Devices ────────────────────────────────────────────────────────────────

    public Mono<JsonNode> listDevices(int limit, int offset, String search,
                                      String applicationId, String deviceProfileId,
                                      String multicastGroupId) {
        String uri = String.format(
                "/api/devices?limit=%d&offset=%d&search=%s&applicationId=%s&deviceProfileId=%s&multicastGroupId=%s",
                limit, offset, nvl(search), nvl(applicationId), nvl(deviceProfileId), nvl(multicastGroupId));
        return client.get(uri);
    }

    public Mono<JsonNode> createDevice(Map<String, Object> body) {
        return client.post("/api/devices", body);
    }

    public Mono<JsonNode> getDevice(String devEui) {
        return client.get("/api/devices/" + devEui);
    }

    public Mono<JsonNode> updateDevice(String devEui, Map<String, Object> body) {
        return client.put("/api/devices/" + devEui, body);
    }

    public Mono<JsonNode> deleteDevice(String devEui) {
        return client.delete("/api/devices/" + devEui);
    }

    // ── Activation ─────────────────────────────────────────────────────────────

    public Mono<JsonNode> activateDevice(String devEui, Map<String, Object> body) {
        return client.post("/api/devices/" + devEui + "/activate", body);
    }

    public Mono<JsonNode> getDeviceActivation(String devEui) {
        return client.get("/api/devices/" + devEui + "/activation");
    }

    public Mono<JsonNode> deactivateDevice(String devEui) {
        return client.delete("/api/devices/" + devEui + "/activation");
    }

    public Mono<JsonNode> getRandomDevAddr(String devEui) {
        return client.postEmpty("/api/devices/" + devEui + "/get-random-dev-addr");
    }

    // ── Keys ───────────────────────────────────────────────────────────────────

    public Mono<JsonNode> createDeviceKeys(String devEui, Map<String, Object> body) {
        return client.post("/api/devices/" + devEui + "/keys", body);
    }

    public Mono<JsonNode> getDeviceKeys(String devEui) {
        return client.get("/api/devices/" + devEui + "/keys");
    }

    public Mono<JsonNode> updateDeviceKeys(String devEui, Map<String, Object> body) {
        return client.put("/api/devices/" + devEui + "/keys", body);
    }

    public Mono<JsonNode> deleteDeviceKeys(String devEui) {
        return client.delete("/api/devices/" + devEui + "/keys");
    }

    // ── Queue ──────────────────────────────────────────────────────────────────

    public Mono<JsonNode> enqueueDownlink(String devEui, Map<String, Object> body) {
        return client.post("/api/devices/" + devEui + "/queue", body);
    }

    public Mono<JsonNode> listQueue(String devEui) {
        return client.get("/api/devices/" + devEui + "/queue");
    }

    public Mono<JsonNode> flushQueue(String devEui) {
        return client.delete("/api/devices/" + devEui + "/queue");
    }

    public Mono<JsonNode> getNextFCntDown(String devEui) {
        return client.postEmpty("/api/devices/" + devEui + "/get-next-f-cnt-down");
    }

    // ── Nonces & Metrics ───────────────────────────────────────────────────────

    public Mono<JsonNode> flushDevNonces(String devEui) {
        return client.delete("/api/devices/" + devEui + "/dev-nonces");
    }

    public Mono<JsonNode> getLinkMetrics(String devEui, String start, String end, String aggregation) {
        String uri = String.format("/api/devices/%s/link-metrics?start=%s&end=%s&aggregation=%s",
                devEui, nvl(start), nvl(end), nvl(aggregation));
        return client.get(uri);
    }

    public Mono<JsonNode> getMetrics(String devEui, String start, String end, String aggregation) {
        String uri = String.format("/api/devices/%s/metrics?start=%s&end=%s&aggregation=%s",
                devEui, nvl(start), nvl(end), nvl(aggregation));
        return client.get(uri);
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }
}
