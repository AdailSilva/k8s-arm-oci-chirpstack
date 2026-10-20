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
 * Relay gateways detectados pelo ChirpStack (GatewayService).
 */
@RestController
@RequestMapping("/api/v1/chirpstack/gateways/relay-gateways")
@PreAuthorize(Perfis.LEITURA)
public class RelayGatewayController {

    private final ChirpStackClient cs;

    public RelayGatewayController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String tenantId) {
        return cs.get("/api/gateways/relay-gateways", Query.of().page(limit, offset, cs.maxPageSize())
                .add("tenantId", tenantId));
    }

    @GetMapping("/{tenantId}/{relayId}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                           @PathVariable @Pattern(regexp = Ids.RELAY_ID) String relayId) {
        return cs.get("/api/gateways/relay-gateways/{tenantId}/{relayId}", null, tenantId, relayId);
    }

    @PutMapping("/{tenantId}/{relayId}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                              @PathVariable @Pattern(regexp = Ids.RELAY_ID) String relayId,
                              @RequestBody JsonNode body) {
        return cs.put("/api/gateways/relay-gateways/{tenantId}/{relayId}", body, tenantId, relayId);
    }

    @DeleteMapping("/{tenantId}/{relayId}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.UUID) String tenantId,
                            @PathVariable @Pattern(regexp = Ids.RELAY_ID) String relayId) {
        return cs.delete("/api/gateways/relay-gateways/{tenantId}/{relayId}", tenantId, relayId);
    }
}
