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
 * GatewayService do ChirpStack: gateways, métricas e certificado de cliente.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/gateways")
@PreAuthorize(Perfis.LEITURA)
public class GatewayController {

    private static final String ORDEM = "^(NAME|GATEWAY_ID|LAST_SEEN_AT)$";
    private static final String AGREGACAO = "^(HOUR|DAY|MONTH|MINUTE)$";
    private static final String DATA = "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+(Z|[+-][0-9]{2}:[0-9]{2})$";

    private final ChirpStackClient cs;

    public GatewayController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String tenantId,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String multicastGroupId,
                           @RequestParam(required = false) @Pattern(regexp = ORDEM) String orderBy,
                           @RequestParam(required = false) Boolean orderByDesc) {
        return cs.get("/api/gateways", Query.of().page(limit, offset, cs.maxPageSize())
                .add("search", search).add("tenantId", tenantId).add("multicastGroupId", multicastGroupId)
                .add("orderBy", orderBy).add("orderByDesc", orderByDesc));
    }

    @PostMapping
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/gateways", body);
    }

    @GetMapping("/{gatewayId}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId) {
        return cs.get("/api/gateways/{gatewayId}", null, gatewayId);
    }

    @PutMapping("/{gatewayId}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId, @RequestBody JsonNode body) {
        return cs.put("/api/gateways/{gatewayId}", body, gatewayId);
    }

    @DeleteMapping("/{gatewayId}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId) {
        return cs.delete("/api/gateways/{gatewayId}", gatewayId);
    }

    @GetMapping("/{gatewayId}/metrics")
    public JsonNode metricas(@PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId,
                             @RequestParam @Pattern(regexp = DATA) String start,
                             @RequestParam @Pattern(regexp = DATA) String end,
                             @RequestParam(defaultValue = "HOUR") @Pattern(regexp = AGREGACAO) String aggregation) {
        return cs.get("/api/gateways/{gatewayId}/metrics",
                Query.of().add("start", start).add("end", end).add("aggregation", aggregation), gatewayId);
    }

    @GetMapping("/{gatewayId}/duty-cycle-metrics")
    public JsonNode metricasDutyCycle(@PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId,
                                      @RequestParam @Pattern(regexp = DATA) String start,
                                      @RequestParam @Pattern(regexp = DATA) String end) {
        return cs.get("/api/gateways/{gatewayId}/duty-cycle-metrics",
                Query.of().add("start", start).add("end", end), gatewayId);
    }

    /** Gera certificado de cliente para o gateway (contém chave privada). */
    @PostMapping("/{gatewayId}/generate-certificate")
    @PreAuthorize(Perfis.SEGREDOS)
    public JsonNode gerarCertificado(@PathVariable @Pattern(regexp = Ids.EUI64) String gatewayId) {
        return cs.post("/api/gateways/{gatewayId}/generate-certificate", null, gatewayId);
    }
}
