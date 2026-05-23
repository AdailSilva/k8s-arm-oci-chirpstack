package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.ApplicationService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/applications")
@RequiredArgsConstructor
@Tag(name = "Applications", description = "Gerenciamento de aplicações e integrações")
public class ApplicationController {

    private final ApplicationService service;

    // ── Applications ───────────────────────────────────────────────────────────

    @GetMapping
    @Operation(summary = "Listar aplicações")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String tenantId) {
        return ResponseEntity.ok(service.listApplications(limit, offset, search, tenantId).block());
    }

    @PostMapping
    @Operation(summary = "Criar aplicação")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createApplication(body).block());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter aplicação")
    public ResponseEntity<JsonNode> get(@PathVariable String id) {
        return ResponseEntity.ok(service.getApplication(id).block());
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar aplicação")
    public ResponseEntity<JsonNode> update(@PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateApplication(id, body).block());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar aplicação")
    public ResponseEntity<JsonNode> delete(@PathVariable String id) {
        return ResponseEntity.ok(service.deleteApplication(id).block());
    }

    // ── Integrations ───────────────────────────────────────────────────────────

    @GetMapping("/{applicationId}/integrations")
    @Operation(summary = "Listar integrações")
    public ResponseEntity<JsonNode> listIntegrations(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.listIntegrations(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/http")
    @Operation(summary = "Criar integração HTTP")
    public ResponseEntity<JsonNode> createHttp(@PathVariable String applicationId,
                                               @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createHttpIntegration(applicationId, body).block());
    }

    @GetMapping("/{applicationId}/integrations/http")
    @Operation(summary = "Obter integração HTTP")
    public ResponseEntity<JsonNode> getHttp(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getHttpIntegration(applicationId).block());
    }

    @PutMapping("/{applicationId}/integrations/http")
    @Operation(summary = "Atualizar integração HTTP")
    public ResponseEntity<JsonNode> updateHttp(@PathVariable String applicationId,
                                               @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateHttpIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/http")
    @Operation(summary = "Deletar integração HTTP")
    public ResponseEntity<JsonNode> deleteHttp(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteHttpIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/influxdb")
    @Operation(summary = "Obter integração InfluxDB")
    public ResponseEntity<JsonNode> getInfluxDb(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getInfluxDbIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/influxdb")
    @Operation(summary = "Criar integração InfluxDB")
    public ResponseEntity<JsonNode> createInfluxDb(@PathVariable String applicationId,
                                                   @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createInfluxDbIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/influxdb")
    @Operation(summary = "Atualizar integração InfluxDB")
    public ResponseEntity<JsonNode> updateInfluxDb(@PathVariable String applicationId,
                                                   @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateInfluxDbIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/influxdb")
    @Operation(summary = "Deletar integração InfluxDB")
    public ResponseEntity<JsonNode> deleteInfluxDb(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteInfluxDbIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/thingsboard")
    @Operation(summary = "Obter integração ThingsBoard")
    public ResponseEntity<JsonNode> getThingsBoard(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getThingsBoardIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/thingsboard")
    @Operation(summary = "Criar integração ThingsBoard")
    public ResponseEntity<JsonNode> createThingsBoard(@PathVariable String applicationId,
                                                      @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createThingsBoardIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/thingsboard")
    @Operation(summary = "Atualizar integração ThingsBoard")
    public ResponseEntity<JsonNode> updateThingsBoard(@PathVariable String applicationId,
                                                      @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateThingsBoardIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/thingsboard")
    @Operation(summary = "Deletar integração ThingsBoard")
    public ResponseEntity<JsonNode> deleteThingsBoard(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteThingsBoardIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/mydevices")
    @Operation(summary = "Obter integração myDevices")
    public ResponseEntity<JsonNode> getMyDevices(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getMyDevicesIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/mydevices")
    @Operation(summary = "Criar integração myDevices")
    public ResponseEntity<JsonNode> createMyDevices(@PathVariable String applicationId,
                                                    @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createMyDevicesIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/mydevices")
    @Operation(summary = "Atualizar integração myDevices")
    public ResponseEntity<JsonNode> updateMyDevices(@PathVariable String applicationId,
                                                    @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateMyDevicesIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/mydevices")
    @Operation(summary = "Deletar integração myDevices")
    public ResponseEntity<JsonNode> deleteMyDevices(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteMyDevicesIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/loracloud")
    @Operation(summary = "Obter integração LoRaCloud")
    public ResponseEntity<JsonNode> getLoraCloud(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getLoraCloudIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/loracloud")
    @Operation(summary = "Criar integração LoRaCloud")
    public ResponseEntity<JsonNode> createLoraCloud(@PathVariable String applicationId,
                                                    @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createLoraCloudIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/loracloud")
    @Operation(summary = "Atualizar integração LoRaCloud")
    public ResponseEntity<JsonNode> updateLoraCloud(@PathVariable String applicationId,
                                                    @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateLoraCloudIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/loracloud")
    @Operation(summary = "Deletar integração LoRaCloud")
    public ResponseEntity<JsonNode> deleteLoraCloud(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteLoraCloudIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/gcp-pub-sub")
    @Operation(summary = "Obter integração GCP Pub/Sub")
    public ResponseEntity<JsonNode> getGcpPubSub(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getGcpPubSubIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/gcp-pub-sub")
    @Operation(summary = "Criar integração GCP Pub/Sub")
    public ResponseEntity<JsonNode> createGcpPubSub(@PathVariable String applicationId,
                                                    @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createGcpPubSubIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/gcp-pub-sub")
    @Operation(summary = "Atualizar integração GCP Pub/Sub")
    public ResponseEntity<JsonNode> updateGcpPubSub(@PathVariable String applicationId,
                                                    @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateGcpPubSubIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/gcp-pub-sub")
    @Operation(summary = "Deletar integração GCP Pub/Sub")
    public ResponseEntity<JsonNode> deleteGcpPubSub(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteGcpPubSubIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/aws-sns")
    @Operation(summary = "Obter integração AWS SNS")
    public ResponseEntity<JsonNode> getAwsSns(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getAwsSnsIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/aws-sns")
    @Operation(summary = "Criar integração AWS SNS")
    public ResponseEntity<JsonNode> createAwsSns(@PathVariable String applicationId,
                                                 @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createAwsSnsIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/aws-sns")
    @Operation(summary = "Atualizar integração AWS SNS")
    public ResponseEntity<JsonNode> updateAwsSns(@PathVariable String applicationId,
                                                 @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateAwsSnsIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/aws-sns")
    @Operation(summary = "Deletar integração AWS SNS")
    public ResponseEntity<JsonNode> deleteAwsSns(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteAwsSnsIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/azure-service-bus")
    @Operation(summary = "Obter integração Azure Service Bus")
    public ResponseEntity<JsonNode> getAzure(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getAzureServiceBusIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/azure-service-bus")
    @Operation(summary = "Criar integração Azure Service Bus")
    public ResponseEntity<JsonNode> createAzure(@PathVariable String applicationId,
                                                @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createAzureServiceBusIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/azure-service-bus")
    @Operation(summary = "Atualizar integração Azure Service Bus")
    public ResponseEntity<JsonNode> updateAzure(@PathVariable String applicationId,
                                                @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateAzureServiceBusIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/azure-service-bus")
    @Operation(summary = "Deletar integração Azure Service Bus")
    public ResponseEntity<JsonNode> deleteAzure(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteAzureServiceBusIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/ifttt")
    @Operation(summary = "Obter integração IFTTT")
    public ResponseEntity<JsonNode> getIfttt(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getIftttIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/ifttt")
    @Operation(summary = "Criar integração IFTTT")
    public ResponseEntity<JsonNode> createIfttt(@PathVariable String applicationId,
                                                @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createIftttIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/ifttt")
    @Operation(summary = "Atualizar integração IFTTT")
    public ResponseEntity<JsonNode> updateIfttt(@PathVariable String applicationId,
                                                @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateIftttIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/ifttt")
    @Operation(summary = "Deletar integração IFTTT")
    public ResponseEntity<JsonNode> deleteIfttt(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deleteIftttIntegration(applicationId).block());
    }

    @GetMapping("/{applicationId}/integrations/pilot-things")
    @Operation(summary = "Obter integração Pilot Things")
    public ResponseEntity<JsonNode> getPilotThings(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.getPilotThingsIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/pilot-things")
    @Operation(summary = "Criar integração Pilot Things")
    public ResponseEntity<JsonNode> createPilotThings(@PathVariable String applicationId,
                                                      @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createPilotThingsIntegration(applicationId, body).block());
    }

    @PutMapping("/{applicationId}/integrations/pilot-things")
    @Operation(summary = "Atualizar integração Pilot Things")
    public ResponseEntity<JsonNode> updatePilotThings(@PathVariable String applicationId,
                                                      @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updatePilotThingsIntegration(applicationId, body).block());
    }

    @DeleteMapping("/{applicationId}/integrations/pilot-things")
    @Operation(summary = "Deletar integração Pilot Things")
    public ResponseEntity<JsonNode> deletePilotThings(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.deletePilotThingsIntegration(applicationId).block());
    }

    @PostMapping("/{applicationId}/integrations/mqtt/certificate")
    @Operation(summary = "Gerar certificado MQTT")
    public ResponseEntity<JsonNode> mqttCertificate(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.generateMqttCertificate(applicationId).block());
    }

    // ── Metadata ───────────────────────────────────────────────────────────────

    @GetMapping("/{applicationId}/device-profiles")
    @Operation(summary = "Listar device profiles da aplicação")
    public ResponseEntity<JsonNode> listDeviceProfiles(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.listDeviceProfiles(applicationId).block());
    }

    @GetMapping("/{applicationId}/device-tags")
    @Operation(summary = "Listar device tags da aplicação")
    public ResponseEntity<JsonNode> listDeviceTags(@PathVariable String applicationId) {
        return ResponseEntity.ok(service.listDeviceTags(applicationId).block());
    }
}
