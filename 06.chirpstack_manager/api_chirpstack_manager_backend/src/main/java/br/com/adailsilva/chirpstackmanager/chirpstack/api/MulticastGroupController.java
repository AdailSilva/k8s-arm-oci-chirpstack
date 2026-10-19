package br.com.adailsilva.chirpstackmanager.chirpstack.api;

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

import br.com.adailsilva.chirpstackmanager.chirpstack.ChirpStackClient;
import br.com.adailsilva.chirpstackmanager.chirpstack.Query;
import br.com.adailsilva.chirpstackmanager.security.Ids;
import br.com.adailsilva.chirpstackmanager.security.Perfis;
import jakarta.validation.constraints.Pattern;
import tools.jackson.databind.JsonNode;

/**
 * MulticastGroupService do ChirpStack: grupos, membros (dispositivos e gateways) e fila.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/multicast-groups")
@PreAuthorize(Perfis.LEITURA)
public class MulticastGroupController {

    private final ChirpStackClient cs;

    public MulticastGroupController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String applicationId,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String tenantId,
                           @RequestParam(required = false) @Pattern(regexp = Ids.EUI64) String devEui) {
        // 4.19+: lista por aplicação OU por tenant; devEui filtra os grupos de que o dispositivo participa.
        return cs.get("/api/multicast-groups", Query.of().page(limit, offset, cs.maxPageSize())
                .add("search", search).add("applicationId", applicationId).add("tenantId", tenantId)
                .add("devEui", devEui));
    }

    @PostMapping
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/multicast-groups", body);
    }

    @GetMapping("/{id}")
    @PreAuthorize(Perfis.SEGREDOS)
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        // Inclui McAppSKey e McNwkSKey.
        return cs.get("/api/multicast-groups/{id}", null, id);
    }

    @PutMapping("/{id}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.put("/api/multicast-groups/{id}", body, id);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/multicast-groups/{id}", id);
    }

    @PostMapping("/{id}/devices")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode adicionarDispositivo(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.post("/api/multicast-groups/{id}/devices", body, id);
    }

    @DeleteMapping("/{id}/devices/{devEui}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode removerDispositivo(@PathVariable @Pattern(regexp = Ids.UUID) String id,
                                       @PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.delete("/api/multicast-groups/{id}/devices/{devEui}", id, devEui);
    }

    @PostMapping("/{id}/gateways")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode adicionarGateway(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.post("/api/multicast-groups/{id}/gateways", body, id);
    }

    @DeleteMapping("/{id}/gateways/{gatewayId}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode removerGateway(@PathVariable @Pattern(regexp = Ids.UUID) String id,
                                   @PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId) {
        return cs.delete("/api/multicast-groups/{id}/gateways/{gatewayId}", id, gatewayId);
    }

    @GetMapping("/{id}/queue")
    public JsonNode listarFila(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/multicast-groups/{id}/queue", null, id);
    }

    @PostMapping("/{id}/queue")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode enfileirar(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.post("/api/multicast-groups/{id}/queue", body, id);
    }

    @DeleteMapping("/{id}/queue")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode limparFila(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/multicast-groups/{id}/queue", id);
    }
}
