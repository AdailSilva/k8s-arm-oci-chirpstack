package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.DeviceProfileService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/device-profiles")
@RequiredArgsConstructor
@Tag(name = "Device Profiles", description = "Gerenciamento de perfis de dispositivos")
public class DeviceProfileController {

    private final DeviceProfileService service;

    @GetMapping
    @Operation(summary = "Listar device profiles")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String tenantId) {
        return ResponseEntity.ok(service.listDeviceProfiles(limit, offset, search, tenantId).block());
    }

    @PostMapping
    @Operation(summary = "Criar device profile")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createDeviceProfile(body).block());
    }

    @GetMapping("/adr-algorithms")
    @Operation(summary = "Listar algoritmos ADR disponíveis")
    public ResponseEntity<JsonNode> adrAlgorithms() {
        return ResponseEntity.ok(service.listAdrAlgorithms().block());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter device profile")
    public ResponseEntity<JsonNode> get(@PathVariable String id) {
        return ResponseEntity.ok(service.getDeviceProfile(id).block());
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar device profile")
    public ResponseEntity<JsonNode> update(@PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateDeviceProfile(id, body).block());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar device profile")
    public ResponseEntity<JsonNode> delete(@PathVariable String id) {
        return ResponseEntity.ok(service.deleteDeviceProfile(id).block());
    }
}
