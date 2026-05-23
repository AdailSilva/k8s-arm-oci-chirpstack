package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.TenantService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/tenants")
@RequiredArgsConstructor
@Tag(name = "Tenants", description = "Gerenciamento de tenants e seus usuários")
public class TenantController {

    private final TenantService service;

    // ── Tenants ────────────────────────────────────────────────────────────────

    @GetMapping
    @Operation(summary = "Listar tenants")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String userId) {
        return ResponseEntity.ok(service.listTenants(limit, offset, search, userId).block());
    }

    @PostMapping
    @Operation(summary = "Criar tenant")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createTenant(body).block());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter tenant")
    public ResponseEntity<JsonNode> get(@PathVariable String id) {
        return ResponseEntity.ok(service.getTenant(id).block());
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar tenant")
    public ResponseEntity<JsonNode> update(@PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateTenant(id, body).block());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar tenant")
    public ResponseEntity<JsonNode> delete(@PathVariable String id) {
        return ResponseEntity.ok(service.deleteTenant(id).block());
    }

    // ── Tenant Users ───────────────────────────────────────────────────────────

    @GetMapping("/{tenantId}/users")
    @Operation(summary = "Listar usuários do tenant")
    public ResponseEntity<JsonNode> listUsers(
            @PathVariable String tenantId,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        return ResponseEntity.ok(service.listTenantUsers(tenantId, limit, offset).block());
    }

    @PostMapping("/{tenantId}/users")
    @Operation(summary = "Adicionar usuário ao tenant")
    public ResponseEntity<JsonNode> addUser(@PathVariable String tenantId,
                                            @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.addTenantUser(tenantId, body).block());
    }

    @GetMapping("/{tenantId}/users/{userId}")
    @Operation(summary = "Obter usuário do tenant")
    public ResponseEntity<JsonNode> getUser(@PathVariable String tenantId,
                                            @PathVariable String userId) {
        return ResponseEntity.ok(service.getTenantUser(tenantId, userId).block());
    }

    @PutMapping("/{tenantId}/users/{userId}")
    @Operation(summary = "Atualizar usuário do tenant")
    public ResponseEntity<JsonNode> updateUser(@PathVariable String tenantId,
                                               @PathVariable String userId,
                                               @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateTenantUser(tenantId, userId, body).block());
    }

    @DeleteMapping("/{tenantId}/users/{userId}")
    @Operation(summary = "Remover usuário do tenant")
    public ResponseEntity<JsonNode> deleteUser(@PathVariable String tenantId,
                                               @PathVariable String userId) {
        return ResponseEntity.ok(service.deleteTenantUser(tenantId, userId).block());
    }
}
