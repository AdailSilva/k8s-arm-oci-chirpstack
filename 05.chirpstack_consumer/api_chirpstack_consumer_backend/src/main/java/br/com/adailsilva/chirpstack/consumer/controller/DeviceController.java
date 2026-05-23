package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.DeviceService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@Tag(name = "Devices", description = "Gerenciamento de dispositivos LoRaWAN")
public class DeviceController {

    private final DeviceService service;

    // ── Devices ────────────────────────────────────────────────────────────────

    @GetMapping
    @Operation(summary = "Listar dispositivos")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String applicationId,
            @RequestParam(required = false) String deviceProfileId,
            @RequestParam(required = false) String multicastGroupId) {
        return ResponseEntity.ok(
                service.listDevices(limit, offset, search, applicationId, deviceProfileId, multicastGroupId).block());
    }

    @PostMapping
    @Operation(summary = "Criar dispositivo")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createDevice(body).block());
    }

    @GetMapping("/{devEui}")
    @Operation(summary = "Obter dispositivo")
    public ResponseEntity<JsonNode> get(@PathVariable String devEui) {
        return ResponseEntity.ok(service.getDevice(devEui).block());
    }

    @PutMapping("/{devEui}")
    @Operation(summary = "Atualizar dispositivo")
    public ResponseEntity<JsonNode> update(@PathVariable String devEui,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateDevice(devEui, body).block());
    }

    @DeleteMapping("/{devEui}")
    @Operation(summary = "Deletar dispositivo")
    public ResponseEntity<JsonNode> delete(@PathVariable String devEui) {
        return ResponseEntity.ok(service.deleteDevice(devEui).block());
    }

    // ── Activation ─────────────────────────────────────────────────────────────

    @PostMapping("/{devEui}/activate")
    @Operation(summary = "Ativar dispositivo (ABP)")
    public ResponseEntity<JsonNode> activate(@PathVariable String devEui,
                                             @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.activateDevice(devEui, body).block());
    }

    @GetMapping("/{devEui}/activation")
    @Operation(summary = "Obter ativação do dispositivo")
    public ResponseEntity<JsonNode> getActivation(@PathVariable String devEui) {
        return ResponseEntity.ok(service.getDeviceActivation(devEui).block());
    }

    @DeleteMapping("/{devEui}/activation")
    @Operation(summary = "Desativar dispositivo")
    public ResponseEntity<JsonNode> deactivate(@PathVariable String devEui) {
        return ResponseEntity.ok(service.deactivateDevice(devEui).block());
    }

    @PostMapping("/{devEui}/get-random-dev-addr")
    @Operation(summary = "Gerar DevAddr aleatório")
    public ResponseEntity<JsonNode> randomDevAddr(@PathVariable String devEui) {
        return ResponseEntity.ok(service.getRandomDevAddr(devEui).block());
    }

    // ── Keys ───────────────────────────────────────────────────────────────────

    @PostMapping("/{devEui}/keys")
    @Operation(summary = "Criar chaves do dispositivo (OTAA)")
    public ResponseEntity<JsonNode> createKeys(@PathVariable String devEui,
                                               @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createDeviceKeys(devEui, body).block());
    }

    @GetMapping("/{devEui}/keys")
    @Operation(summary = "Obter chaves do dispositivo")
    public ResponseEntity<JsonNode> getKeys(@PathVariable String devEui) {
        return ResponseEntity.ok(service.getDeviceKeys(devEui).block());
    }

    @PutMapping("/{devEui}/keys")
    @Operation(summary = "Atualizar chaves do dispositivo")
    public ResponseEntity<JsonNode> updateKeys(@PathVariable String devEui,
                                               @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateDeviceKeys(devEui, body).block());
    }

    @DeleteMapping("/{devEui}/keys")
    @Operation(summary = "Deletar chaves do dispositivo")
    public ResponseEntity<JsonNode> deleteKeys(@PathVariable String devEui) {
        return ResponseEntity.ok(service.deleteDeviceKeys(devEui).block());
    }

    // ── Queue ──────────────────────────────────────────────────────────────────

    @PostMapping("/{devEui}/queue")
    @Operation(summary = "Enfileirar downlink")
    public ResponseEntity<JsonNode> enqueue(@PathVariable String devEui,
                                            @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.enqueueDownlink(devEui, body).block());
    }

    @GetMapping("/{devEui}/queue")
    @Operation(summary = "Listar fila de downlink")
    public ResponseEntity<JsonNode> listQueue(@PathVariable String devEui) {
        return ResponseEntity.ok(service.listQueue(devEui).block());
    }

    @DeleteMapping("/{devEui}/queue")
    @Operation(summary = "Limpar fila de downlink")
    public ResponseEntity<JsonNode> flushQueue(@PathVariable String devEui) {
        return ResponseEntity.ok(service.flushQueue(devEui).block());
    }

    @PostMapping("/{devEui}/get-next-f-cnt-down")
    @Operation(summary = "Obter próximo FCntDown")
    public ResponseEntity<JsonNode> nextFCntDown(@PathVariable String devEui) {
        return ResponseEntity.ok(service.getNextFCntDown(devEui).block());
    }

    // ── Nonces & Metrics ───────────────────────────────────────────────────────

    @DeleteMapping("/{devEui}/dev-nonces")
    @Operation(summary = "Limpar dev nonces")
    public ResponseEntity<JsonNode> flushNonces(@PathVariable String devEui) {
        return ResponseEntity.ok(service.flushDevNonces(devEui).block());
    }

    @GetMapping("/{devEui}/link-metrics")
    @Operation(summary = "Obter métricas de link")
    public ResponseEntity<JsonNode> linkMetrics(
            @PathVariable String devEui,
            @RequestParam(required = false) String start,
            @RequestParam(required = false) String end,
            @RequestParam(required = false) String aggregation) {
        return ResponseEntity.ok(service.getLinkMetrics(devEui, start, end, aggregation).block());
    }

    @GetMapping("/{devEui}/metrics")
    @Operation(summary = "Obter métricas de aplicação")
    public ResponseEntity<JsonNode> metrics(
            @PathVariable String devEui,
            @RequestParam(required = false) String start,
            @RequestParam(required = false) String end,
            @RequestParam(required = false) String aggregation) {
        return ResponseEntity.ok(service.getMetrics(devEui, start, end, aggregation).block());
    }
}
