package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.GatewayService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/gateways")
@RequiredArgsConstructor
@Tag(name = "Gateways", description = "Gerenciamento de gateways LoRaWAN")
public class GatewayController {

    private final GatewayService service;

    // ── Gateways ───────────────────────────────────────────────────────────────

    @GetMapping
    @Operation(summary = "Listar gateways")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String tenantId,
            @RequestParam(required = false) String multicastGroupId) {
        return ResponseEntity.ok(
                service.listGateways(limit, offset, search, tenantId, multicastGroupId).block());
    }

    @PostMapping
    @Operation(summary = "Criar gateway")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createGateway(body).block());
    }

    @GetMapping("/{gatewayId}")
    @Operation(summary = "Obter gateway")
    public ResponseEntity<JsonNode> get(@PathVariable String gatewayId) {
        return ResponseEntity.ok(service.getGateway(gatewayId).block());
    }

    @PutMapping("/{gatewayId}")
    @Operation(summary = "Atualizar gateway")
    public ResponseEntity<JsonNode> update(@PathVariable String gatewayId,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateGateway(gatewayId, body).block());
    }

    @DeleteMapping("/{gatewayId}")
    @Operation(summary = "Deletar gateway")
    public ResponseEntity<JsonNode> delete(@PathVariable String gatewayId) {
        return ResponseEntity.ok(service.deleteGateway(gatewayId).block());
    }

    // ── Metrics ────────────────────────────────────────────────────────────────

    @GetMapping("/{gatewayId}/metrics")
    @Operation(summary = "Obter métricas do gateway")
    public ResponseEntity<JsonNode> metrics(
            @PathVariable String gatewayId,
            @RequestParam(required = false) String start,
            @RequestParam(required = false) String end,
            @RequestParam(required = false) String aggregation) {
        return ResponseEntity.ok(service.getMetrics(gatewayId, start, end, aggregation).block());
    }

    @GetMapping("/{gatewayId}/duty-cycle-metrics")
    @Operation(summary = "Obter métricas de duty cycle")
    public ResponseEntity<JsonNode> dutyCycleMetrics(
            @PathVariable String gatewayId,
            @RequestParam(required = false) String start,
            @RequestParam(required = false) String end) {
        return ResponseEntity.ok(service.getDutyCycleMetrics(gatewayId, start, end).block());
    }

    // ── Certificate ────────────────────────────────────────────────────────────

    @PostMapping("/{gatewayId}/generate-certificate")
    @Operation(summary = "Gerar certificado TLS do gateway")
    public ResponseEntity<JsonNode> generateCertificate(@PathVariable String gatewayId) {
        return ResponseEntity.ok(service.generateCertificate(gatewayId).block());
    }

    // ── Relay Gateways ─────────────────────────────────────────────────────────

    @GetMapping("/relay-gateways")
    @Operation(summary = "Listar relay gateways")
    public ResponseEntity<JsonNode> listRelayGateways(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String tenantId) {
        return ResponseEntity.ok(service.listRelayGateways(limit, offset, tenantId).block());
    }

    @GetMapping("/relay-gateways/{tenantId}/{relayId}")
    @Operation(summary = "Obter relay gateway")
    public ResponseEntity<JsonNode> getRelayGateway(@PathVariable String tenantId,
                                                    @PathVariable String relayId) {
        return ResponseEntity.ok(service.getRelayGateway(tenantId, relayId).block());
    }

    @PutMapping("/relay-gateways/{tenantId}/{relayId}")
    @Operation(summary = "Atualizar relay gateway")
    public ResponseEntity<JsonNode> updateRelayGateway(@PathVariable String tenantId,
                                                       @PathVariable String relayId,
                                                       @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateRelayGateway(tenantId, relayId, body).block());
    }

    @DeleteMapping("/relay-gateways/{tenantId}/{relayId}")
    @Operation(summary = "Deletar relay gateway")
    public ResponseEntity<JsonNode> deleteRelayGateway(@PathVariable String tenantId,
                                                       @PathVariable String relayId) {
        return ResponseEntity.ok(service.deleteRelayGateway(tenantId, relayId).block());
    }
}
