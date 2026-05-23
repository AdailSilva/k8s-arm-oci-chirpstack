package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class ApplicationService {

    private final ChirpStackClient client;

    // ── Applications ───────────────────────────────────────────────────────────

    public Mono<JsonNode> listApplications(int limit, int offset, String search, String tenantId) {
        String uri = String.format("/api/applications?limit=%d&offset=%d&search=%s&tenantId=%s",
                limit, offset, nvl(search), nvl(tenantId));
        return client.get(uri);
    }

    public Mono<JsonNode> createApplication(Map<String, Object> body) {
        return client.post("/api/applications", body);
    }

    public Mono<JsonNode> getApplication(String id) {
        return client.get("/api/applications/" + id);
    }

    public Mono<JsonNode> updateApplication(String id, Map<String, Object> body) {
        return client.put("/api/applications/" + id, body);
    }

    public Mono<JsonNode> deleteApplication(String id) {
        return client.delete("/api/applications/" + id);
    }

    // ── Integrations ───────────────────────────────────────────────────────────

    public Mono<JsonNode> listIntegrations(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations");
    }

    public Mono<JsonNode> createHttpIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/http", body);
    }

    public Mono<JsonNode> getHttpIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/http");
    }

    public Mono<JsonNode> updateHttpIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/http", body);
    }

    public Mono<JsonNode> deleteHttpIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/http");
    }

    public Mono<JsonNode> getInfluxDbIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/influxdb");
    }

    public Mono<JsonNode> createInfluxDbIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/influxdb", body);
    }

    public Mono<JsonNode> updateInfluxDbIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/influxdb", body);
    }

    public Mono<JsonNode> deleteInfluxDbIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/influxdb");
    }

    public Mono<JsonNode> getThingsBoardIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/thingsboard");
    }

    public Mono<JsonNode> createThingsBoardIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/thingsboard", body);
    }

    public Mono<JsonNode> updateThingsBoardIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/thingsboard", body);
    }

    public Mono<JsonNode> deleteThingsBoardIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/thingsboard");
    }

    public Mono<JsonNode> getMyDevicesIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/mydevices");
    }

    public Mono<JsonNode> createMyDevicesIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/mydevices", body);
    }

    public Mono<JsonNode> updateMyDevicesIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/mydevices", body);
    }

    public Mono<JsonNode> deleteMyDevicesIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/mydevices");
    }

    public Mono<JsonNode> getLoraCloudIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/loracloud");
    }

    public Mono<JsonNode> createLoraCloudIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/loracloud", body);
    }

    public Mono<JsonNode> updateLoraCloudIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/loracloud", body);
    }

    public Mono<JsonNode> deleteLoraCloudIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/loracloud");
    }

    public Mono<JsonNode> getGcpPubSubIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/gcp-pub-sub");
    }

    public Mono<JsonNode> createGcpPubSubIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/gcp-pub-sub", body);
    }

    public Mono<JsonNode> updateGcpPubSubIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/gcp-pub-sub", body);
    }

    public Mono<JsonNode> deleteGcpPubSubIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/gcp-pub-sub");
    }

    public Mono<JsonNode> getAwsSnsIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/aws-sns");
    }

    public Mono<JsonNode> createAwsSnsIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/aws-sns", body);
    }

    public Mono<JsonNode> updateAwsSnsIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/aws-sns", body);
    }

    public Mono<JsonNode> deleteAwsSnsIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/aws-sns");
    }

    public Mono<JsonNode> getAzureServiceBusIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/azure-service-bus");
    }

    public Mono<JsonNode> createAzureServiceBusIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/azure-service-bus", body);
    }

    public Mono<JsonNode> updateAzureServiceBusIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/azure-service-bus", body);
    }

    public Mono<JsonNode> deleteAzureServiceBusIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/azure-service-bus");
    }

    public Mono<JsonNode> getIftttIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/ifttt");
    }

    public Mono<JsonNode> createIftttIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/ifttt", body);
    }

    public Mono<JsonNode> updateIftttIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/ifttt", body);
    }

    public Mono<JsonNode> deleteIftttIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/ifttt");
    }

    public Mono<JsonNode> getPilotThingsIntegration(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/integrations/pilot-things");
    }

    public Mono<JsonNode> createPilotThingsIntegration(String applicationId, Map<String, Object> body) {
        return client.post("/api/applications/" + applicationId + "/integrations/pilot-things", body);
    }

    public Mono<JsonNode> updatePilotThingsIntegration(String applicationId, Map<String, Object> body) {
        return client.put("/api/applications/" + applicationId + "/integrations/pilot-things", body);
    }

    public Mono<JsonNode> deletePilotThingsIntegration(String applicationId) {
        return client.delete("/api/applications/" + applicationId + "/integrations/pilot-things");
    }

    public Mono<JsonNode> generateMqttCertificate(String applicationId) {
        return client.postEmpty("/api/applications/" + applicationId + "/integrations/mqtt/certificate");
    }

    // ── Metadata ───────────────────────────────────────────────────────────────

    public Mono<JsonNode> listDeviceProfiles(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/device-profiles");
    }

    public Mono<JsonNode> listDeviceTags(String applicationId) {
        return client.get("/api/applications/" + applicationId + "/device-tags");
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }
}
