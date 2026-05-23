package br.com.adailsilva.chirpstack.consumer.controller;

import br.com.adailsilva.chirpstack.consumer.service.UserService;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "Users", description = "Gerenciamento de usuários")
public class UserController {

    private final UserService service;

    @GetMapping
    @Operation(summary = "Listar usuários")
    public ResponseEntity<JsonNode> list(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        return ResponseEntity.ok(service.listUsers(limit, offset).block());
    }

    @PostMapping
    @Operation(summary = "Criar usuário")
    public ResponseEntity<JsonNode> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.createUser(body).block());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter usuário")
    public ResponseEntity<JsonNode> get(@PathVariable String id) {
        return ResponseEntity.ok(service.getUser(id).block());
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar usuário")
    public ResponseEntity<JsonNode> update(@PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updateUser(id, body).block());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deletar usuário")
    public ResponseEntity<JsonNode> delete(@PathVariable String id) {
        return ResponseEntity.ok(service.deleteUser(id).block());
    }

    @PutMapping("/{userId}/password")
    @Operation(summary = "Atualizar senha do usuário")
    public ResponseEntity<JsonNode> updatePassword(@PathVariable String userId,
                                                   @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(service.updatePassword(userId, body).block());
    }
}
