package br.com.adailsilva.chirpstackmanager.api.controller.chirpstack;

import java.util.List;

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
 * DeviceService do ChirpStack: dispositivos, chaves OTAA, ativação ABP, fila de downlink e métricas.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/devices")
@PreAuthorize(Perfis.LEITURA)
public class DeviceController {

    private static final String ORDEM = "^(NAME|DEV_EUI|LAST_SEEN_AT|DEVICE_PROFILE_NAME)$";
    private static final String AGREGACAO = "^(HOUR|DAY|MONTH|MINUTE)$";
    private static final String DATA = "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+(Z|[+-][0-9]{2}:[0-9]{2})$";

    private final ChirpStackClient cs;

    public DeviceController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String applicationId,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String multicastGroupId,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String deviceProfileId,
                           @RequestParam(required = false) @Pattern(regexp = ORDEM) String orderBy,
                           @RequestParam(required = false) Boolean orderByDesc,
                           @RequestParam(name = "tag", required = false) List<@Pattern(regexp = Ids.TAG_FILTRO) String> tags) {
        return cs.get("/api/devices", comTags(Query.of().page(limit, offset, cs.maxPageSize())
                .add("search", search).add("applicationId", applicationId)
                .add("multicastGroupId", multicastGroupId).add("deviceProfileId", deviceProfileId)
                .add("orderBy", orderBy).add("orderByDesc", orderByDesc), tags));
    }

    /** Tags no formato do grpc-gateway para campos map: {@code tags[chave]=valor} (4.19+). */
    private static Query comTags(Query q, List<String> tags) {
        if (tags != null) {
            for (String t : tags) {
                int i = t.indexOf('=');
                q.add("tags[" + t.substring(0, i).trim() + "]", t.substring(i + 1).trim());
            }
        }
        return q;
    }

    @PostMapping
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/devices", body);
    }

    @GetMapping("/{devEui}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.get("/api/devices/{devEui}", null, devEui);
    }

    @PutMapping("/{devEui}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui, @RequestBody JsonNode body) {
        return cs.put("/api/devices/{devEui}", body, devEui);
    }

    @DeleteMapping("/{devEui}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.delete("/api/devices/{devEui}", devEui);
    }

    // ---------------------------------------------------------------- chaves (OTAA)

    @GetMapping("/{devEui}/keys")
    @PreAuthorize(Perfis.SEGREDOS)
    public JsonNode buscarChaves(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.get("/api/devices/{devEui}/keys", null, devEui);
    }

    @PostMapping("/{devEui}/keys")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criarChaves(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui, @RequestBody JsonNode body) {
        return cs.post("/api/devices/{devEui}/keys", body, devEui);
    }

    @PutMapping("/{devEui}/keys")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizarChaves(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui, @RequestBody JsonNode body) {
        return cs.put("/api/devices/{devEui}/keys", body, devEui);
    }

    @DeleteMapping("/{devEui}/keys")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluirChaves(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.delete("/api/devices/{devEui}/keys", devEui);
    }

    @DeleteMapping("/{devEui}/dev-nonces")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode limparDevNonces(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.delete("/api/devices/{devEui}/dev-nonces", devEui);
    }

    // ---------------------------------------------------------------- ativação (sessão)

    @GetMapping("/{devEui}/activation")
    @PreAuthorize(Perfis.SEGREDOS)
    public JsonNode buscarAtivacao(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.get("/api/devices/{devEui}/activation", null, devEui);
    }

    @PostMapping("/{devEui}/activate")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode ativar(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui, @RequestBody JsonNode body) {
        return cs.post("/api/devices/{devEui}/activate", body, devEui);
    }

    @DeleteMapping("/{devEui}/activation")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode desativar(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.delete("/api/devices/{devEui}/activation", devEui);
    }

    @PostMapping("/{devEui}/get-random-dev-addr")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode devAddrAleatorio(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.post("/api/devices/{devEui}/get-random-dev-addr", null, devEui);
    }

    @PostMapping("/{devEui}/get-next-f-cnt-down")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode proximoFCntDown(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.post("/api/devices/{devEui}/get-next-f-cnt-down", null, devEui);
    }

    // ---------------------------------------------------------------- fila de downlink

    @GetMapping("/{devEui}/queue")
    public JsonNode listarFila(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui,
                               @RequestParam(required = false) Boolean countOnly) {
        return cs.get("/api/devices/{devEui}/queue", Query.of().add("countOnly", countOnly), devEui);
    }

    @PostMapping("/{devEui}/queue")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode enfileirar(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui, @RequestBody JsonNode body) {
        return cs.post("/api/devices/{devEui}/queue", body, devEui);
    }

    @DeleteMapping("/{devEui}/queue")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode limparFila(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui) {
        return cs.delete("/api/devices/{devEui}/queue", devEui);
    }

    // ---------------------------------------------------------------- métricas

    @GetMapping("/{devEui}/metrics")
    public JsonNode metricas(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui,
                             @RequestParam @Pattern(regexp = DATA) String start,
                             @RequestParam @Pattern(regexp = DATA) String end,
                             @RequestParam(defaultValue = "HOUR") @Pattern(regexp = AGREGACAO) String aggregation) {
        return cs.get("/api/devices/{devEui}/metrics",
                Query.of().add("start", start).add("end", end).add("aggregation", aggregation), devEui);
    }

    @GetMapping("/{devEui}/link-metrics")
    public JsonNode metricasEnlace(@PathVariable @Pattern(regexp = Ids.EUI64) String devEui,
                                   @RequestParam @Pattern(regexp = DATA) String start,
                                   @RequestParam @Pattern(regexp = DATA) String end,
                                   @RequestParam(defaultValue = "HOUR") @Pattern(regexp = AGREGACAO) String aggregation) {
        return cs.get("/api/devices/{devEui}/link-metrics",
                Query.of().add("start", start).add("end", end).add("aggregation", aggregation), devEui);
    }
}
