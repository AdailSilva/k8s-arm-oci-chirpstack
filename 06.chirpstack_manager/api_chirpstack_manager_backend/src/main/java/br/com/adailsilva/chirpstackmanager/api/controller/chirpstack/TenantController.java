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
 * TenantService do ChirpStack: tenants, usuários de cada tenant e verificação de prefixos de DevAddr.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/tenants")
@PreAuthorize(Perfis.LEITURA)
public class TenantController {

    private final ChirpStackClient cs;

    public TenantController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String userId) {
        return cs.get("/api/tenants", Query.of().page(limit, offset, cs.maxPageSize())
                .add("search", search).add("userId", userId));
    }

    /**
     * Tenants cujos prefixos de DevAddr se sobrepõem ao prefixo informado (4.19+). Usado antes de
     * atribuir um prefixo a um tenant, para evitar que dois tenants disputem o mesmo espaço de DevAddr.
     */
    @GetMapping("/by-devaddr-prefix-overlap")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode sobreposicaoDevAddr(@RequestParam @Pattern(regexp = Ids.DEVADDR_PREFIX) String devAddrPrefix) {
        return cs.get("/api/tenants/by-devaddr-prefix-overlap", Query.of().add("devAddrPrefix", devAddrPrefix));
    }

    @PostMapping
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/tenants", body);
    }

    @GetMapping("/{id}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/tenants/{id}", null, id);
    }

    @PutMapping("/{id}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.put("/api/tenants/{id}", body, id);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/tenants/{id}", id);
    }

    // ---------------------------------------------------------------- usuários do tenant

    @GetMapping("/{tenantId}/users")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode listarUsuarios(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                                   @RequestParam(required = false) Long limit,
                                   @RequestParam(required = false) Long offset) {
        return cs.get("/api/tenants/{tenantId}/users", Query.of().page(limit, offset, cs.maxPageSize()), tenantId);
    }

    @PostMapping("/{tenantId}/users")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode adicionarUsuario(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                                     @RequestBody JsonNode body) {
        return cs.post("/api/tenants/{tenantId}/users", body, tenantId);
    }

    @GetMapping("/{tenantId}/users/{userId}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode buscarUsuario(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                                  @PathVariable @Pattern(regexp = Ids.UUID) String userId) {
        return cs.get("/api/tenants/{tenantId}/users/{userId}", null, tenantId, userId);
    }

    @PutMapping("/{tenantId}/users/{userId}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode atualizarUsuario(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                                     @PathVariable @Pattern(regexp = Ids.UUID) String userId,
                                     @RequestBody JsonNode body) {
        return cs.put("/api/tenants/{tenantId}/users/{userId}", body, tenantId, userId);
    }

    @DeleteMapping("/{tenantId}/users/{userId}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode removerUsuario(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                                   @PathVariable @Pattern(regexp = Ids.UUID) String userId) {
        return cs.delete("/api/tenants/{tenantId}/users/{userId}", tenantId, userId);
    }
}
