package br.com.adailsilva.chirpstackmanager.api.controller.chirpstack;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.api.service.chirpstack.ChirpStackClient;
import br.com.adailsilva.chirpstackmanager.api.service.chirpstack.Query;
import br.com.adailsilva.chirpstackmanager.api.security.Ids;
import br.com.adailsilva.chirpstackmanager.api.security.Perfis;
import jakarta.validation.constraints.Pattern;
import tools.jackson.databind.JsonNode;

/**
 * UserService do ChirpStack (usuários do próprio ChirpStack, não do painel). Somente ADMIN.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/users")
@PreAuthorize(Perfis.ADMIN)
public class UserController {

    private final ChirpStackClient cs;

    public UserController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset) {
        return cs.get("/api/users", Query.of().page(limit, offset, cs.maxPageSize()));
    }

    @PostMapping
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/users", body);
    }

    @GetMapping("/{id}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/users/{id}", null, id);
    }

    @PutMapping("/{id}")
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.put("/api/users/{id}", body, id);
    }

    @DeleteMapping("/{id}")
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/users/{id}", id);
    }

    @PostMapping("/{id}/password")
    public JsonNode alterarSenha(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.post("/api/users/{id}/password", body, id);
    }
}
