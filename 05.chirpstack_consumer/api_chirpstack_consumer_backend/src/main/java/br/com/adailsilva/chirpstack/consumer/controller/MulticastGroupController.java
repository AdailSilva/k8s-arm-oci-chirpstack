package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.MulticastGroupService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/multicast-groups")
@RequiredArgsConstructor
@Tag(name = "Multicast Groups", description = "Gerenciamento de grupos multicast LoRaWAN")
public class MulticastGroupController {

    private final MulticastGroupService service;

    // ── Groups ─────────────────────────────────────────────────────────────────

    @GetMapping
    @Operation(summary = "Listar grupos multicast")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String applicationId) {
        return ResponseEntity.ok(service.listGroups(limit, offset, search, applicationId).block());
    }

    @PostMapping
    @Operation(summary = "Criar grupo multicast")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createGroup(body).block());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter grupo multicast")
    public ResponseEntity<JsonNode> get(@PathVariable String id) {
        return ResponseEntity.ok(service.getGroup(id).block());
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar grupo multicast")
    public ResponseEntity<JsonNode> update(@PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateGroup(id, body).block());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar grupo multicast")
    public ResponseEntity<JsonNode> delete(@PathVariable String id) {
        return ResponseEntity.ok(service.deleteGroup(id).block());
    }

    // ── Devices ────────────────────────────────────────────────────────────────

    @PostMapping("/{groupId}/devices")
    @Operation(summary = "Adicionar dispositivo ao grupo multicast")
    public ResponseEntity<JsonNode> addDevice(@PathVariable String groupId,
                                              @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.addDevice(groupId, body).block());
    }

    @DeleteMapping("/{groupId}/devices/{devEui}")
    @Operation(summary = "Remover dispositivo do grupo multicast")
    public ResponseEntity<JsonNode> removeDevice(@PathVariable String groupId,
                                                 @PathVariable String devEui) {
        return ResponseEntity.ok(service.removeDevice(groupId, devEui).block());
    }

    // ── Gateways ───────────────────────────────────────────────────────────────

    @PostMapping("/{groupId}/gateways")
    @Operation(summary = "Adicionar gateway ao grupo multicast")
    public ResponseEntity<JsonNode> addGateway(@PathVariable String groupId,
                                               @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.addGateway(groupId, body).block());
    }

    @DeleteMapping("/{groupId}/gateways/{gatewayId}")
    @Operation(summary = "Remover gateway do grupo multicast")
    public ResponseEntity<JsonNode> removeGateway(@PathVariable String groupId,
                                                  @PathVariable String gatewayId) {
        return ResponseEntity.ok(service.removeGateway(groupId, gatewayId).block());
    }

    // ── Queue ──────────────────────────────────────────────────────────────────

    @PostMapping("/{groupId}/queue")
    @Operation(summary = "Enfileirar downlink multicast")
    public ResponseEntity<JsonNode> enqueue(@PathVariable String groupId,
                                            @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.enqueue(groupId, body).block());
    }

    @GetMapping("/{groupId}/queue")
    @Operation(summary = "Listar fila multicast")
    public ResponseEntity<JsonNode> listQueue(@PathVariable String groupId) {
        return ResponseEntity.ok(service.listQueue(groupId).block());
    }

    @DeleteMapping("/{groupId}/queue")
    @Operation(summary = "Limpar fila multicast")
    public ResponseEntity<JsonNode> flushQueue(@PathVariable String groupId) {
        return ResponseEntity.ok(service.flushQueue(groupId).block());
    }
}
