package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class TenantService {

    private final ChirpStackClient client;

    // ── Tenants ────────────────────────────────────────────────────────────────

    public Mono<JsonNode> listTenants(int limit, int offset, String search, String userId) {
        String uri = String.format("/api/tenants?limit=%d&offset=%d&search=%s&userId=%s",
                limit, offset, nvl(search), nvl(userId));
        return client.get(uri);
    }

    public Mono<JsonNode> createTenant(Map<String, Object> body) {
        return client.post("/api/tenants", body);
    }

    public Mono<JsonNode> getTenant(String id) {
        return client.get("/api/tenants/" + id);
    }

    public Mono<JsonNode> updateTenant(String id, Map<String, Object> body) {
        return client.put("/api/tenants/" + id, body);
    }

    public Mono<JsonNode> deleteTenant(String id) {
        return client.delete("/api/tenants/" + id);
    }

    // ── Tenant Users ───────────────────────────────────────────────────────────

    public Mono<JsonNode> listTenantUsers(String tenantId, int limit, int offset) {
        String uri = String.format("/api/tenants/%s/users?limit=%d&offset=%d", tenantId, limit, offset);
        return client.get(uri);
    }

    public Mono<JsonNode> addTenantUser(String tenantId, Map<String, Object> body) {
        return client.post("/api/tenants/" + tenantId + "/users", body);
    }

    public Mono<JsonNode> getTenantUser(String tenantId, String userId) {
        return client.get("/api/tenants/" + tenantId + "/users/" + userId);
    }

    public Mono<JsonNode> updateTenantUser(String tenantId, String userId, Map<String, Object> body) {
        return client.put("/api/tenants/" + tenantId + "/users/" + userId, body);
    }

    public Mono<JsonNode> deleteTenantUser(String tenantId, String userId) {
        return client.delete("/api/tenants/" + tenantId + "/users/" + userId);
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }
}
