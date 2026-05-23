package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class GatewayService {

    private final ChirpStackClient client;

    // ── Gateways ───────────────────────────────────────────────────────────────

    public Mono<JsonNode> listGateways(int limit, int offset, String search,
                                       String tenantId, String multicastGroupId) {
        String uri = String.format("/api/gateways?limit=%d&offset=%d&search=%s&tenantId=%s&multicastGroupId=%s",
                limit, offset, nvl(search), nvl(tenantId), nvl(multicastGroupId));
        return client.get(uri);
    }

    public Mono<JsonNode> createGateway(Map<String, Object> body) {
        return client.post("/api/gateways", body);
    }

    public Mono<JsonNode> getGateway(String gatewayId) {
        return client.get("/api/gateways/" + gatewayId);
    }

    public Mono<JsonNode> updateGateway(String gatewayId, Map<String, Object> body) {
        return client.put("/api/gateways/" + gatewayId, body);
    }

    public Mono<JsonNode> deleteGateway(String gatewayId) {
        return client.delete("/api/gateways/" + gatewayId);
    }

    // ── Metrics ────────────────────────────────────────────────────────────────

    public Mono<JsonNode> getMetrics(String gatewayId, String start, String end, String aggregation) {
        String uri = String.format("/api/gateways/%s/metrics?start=%s&end=%s&aggregation=%s",
                gatewayId, nvl(start), nvl(end), nvl(aggregation));
        return client.get(uri);
    }

    public Mono<JsonNode> getDutyCycleMetrics(String gatewayId, String start, String end) {
        String uri = String.format("/api/gateways/%s/duty-cycle-metrics?start=%s&end=%s",
                gatewayId, nvl(start), nvl(end));
        return client.get(uri);
    }

    // ── Certificate ────────────────────────────────────────────────────────────

    public Mono<JsonNode> generateCertificate(String gatewayId) {
        return client.postEmpty("/api/gateways/" + gatewayId + "/generate-certificate");
    }

    // ── Relay Gateways ─────────────────────────────────────────────────────────

    public Mono<JsonNode> listRelayGateways(int limit, int offset, String tenantId) {
        String uri = String.format("/api/gateways/relay-gateways?limit=%d&offset=%d&tenantId=%s",
                limit, offset, nvl(tenantId));
        return client.get(uri);
    }

    public Mono<JsonNode> getRelayGateway(String tenantId, String relayId) {
        return client.get("/api/gateways/relay-gateways/" + tenantId + "/" + relayId);
    }

    public Mono<JsonNode> updateRelayGateway(String tenantId, String relayId, Map<String, Object> body) {
        return client.put("/api/gateways/relay-gateways/" + tenantId + "/" + relayId, body);
    }

    public Mono<JsonNode> deleteRelayGateway(String tenantId, String relayId) {
        return client.delete("/api/gateways/relay-gateways/" + tenantId + "/" + relayId);
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }
}
