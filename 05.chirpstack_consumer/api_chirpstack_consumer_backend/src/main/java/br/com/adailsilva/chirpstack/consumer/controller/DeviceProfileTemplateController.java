package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.DeviceProfileTemplateService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/device-profile-templates")
@RequiredArgsConstructor
@Tag(name = "Device Profile Templates", description = "Gerenciamento de templates de perfil de dispositivos")
public class DeviceProfileTemplateController {

    private final DeviceProfileTemplateService service;

    @GetMapping
    @Operation(summary = "Listar templates de device profile")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        return ResponseEntity.ok(service.listTemplates(limit, offset).block());
    }

    @PostMapping
    @Operation(summary = "Criar template de device profile")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createTemplate(body).block());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter template de device profile")
    public ResponseEntity<JsonNode> get(@PathVariable String id) {
        return ResponseEntity.ok(service.getTemplate(id).block());
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar template de device profile")
    public ResponseEntity<JsonNode> update(@PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateTemplate(id, body).block());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar template de device profile")
    public ResponseEntity<JsonNode> delete(@PathVariable String id) {
        return ResponseEntity.ok(service.deleteTemplate(id).block());
    }
}
