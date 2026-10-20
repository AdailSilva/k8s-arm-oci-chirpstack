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
 * ApplicationService do ChirpStack: aplicações, integrações e certificado MQTT.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/applications")
@PreAuthorize(Perfis.LEITURA)
public class ApplicationController {

    /** Tipos de integração com CRUD na REST API (o caminho do ChirpStack usa o mesmo nome). */
    private static final String INTEGRACOES =
            "^(http|influxdb|thingsboard|mydevices|gcp-pub-sub|aws-sns|azure-service-bus|pilot-things|ifttt|blynk)$";

    private final ChirpStackClient cs;

    public ApplicationController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String tenantId) {
        return cs.get("/api/applications", Query.of().page(limit, offset, cs.maxPageSize())
                .add("search", search).add("tenantId", tenantId));
    }

    @PostMapping
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/applications", body);
    }

    @GetMapping("/{id}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/applications/{id}", null, id);
    }

    @PutMapping("/{id}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body) {
        return cs.put("/api/applications/{id}", body, id);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/applications/{id}", id);
    }

    @GetMapping("/{id}/device-profiles")
    public JsonNode perfisUsados(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/applications/{id}/device-profiles", null, id);
    }

    @GetMapping("/{id}/device-tags")
    public JsonNode tagsUsadas(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/applications/{id}/device-tags", null, id);
    }

    // ---------------------------------------------------------------- integrações

    @GetMapping("/{id}/integrations")
    public JsonNode listarIntegracoes(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/applications/{id}/integrations", null, id);
    }

    /** A configuração da integração pode conter tokens e senhas. */
    @GetMapping("/{id}/integrations/{tipo}")
    @PreAuthorize(Perfis.SEGREDOS)
    public JsonNode buscarIntegracao(@PathVariable @Pattern(regexp = Ids.UUID) String id,
                                     @PathVariable @Pattern(regexp = INTEGRACOES) String tipo) {
        return cs.get("/api/applications/{id}/integrations/{tipo}", null, id, tipo);
    }

    @PostMapping("/{id}/integrations/{tipo}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criarIntegracao(@PathVariable @Pattern(regexp = Ids.UUID) String id,
                                    @PathVariable @Pattern(regexp = INTEGRACOES) String tipo,
                                    @RequestBody JsonNode body) {
        return cs.post("/api/applications/{id}/integrations/{tipo}", body, id, tipo);
    }

    @PutMapping("/{id}/integrations/{tipo}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizarIntegracao(@PathVariable @Pattern(regexp = Ids.UUID) String id,
                                        @PathVariable @Pattern(regexp = INTEGRACOES) String tipo,
                                        @RequestBody JsonNode body) {
        return cs.put("/api/applications/{id}/integrations/{tipo}", body, id, tipo);
    }

    @DeleteMapping("/{id}/integrations/{tipo}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluirIntegracao(@PathVariable @Pattern(regexp = Ids.UUID) String id,
                                      @PathVariable @Pattern(regexp = INTEGRACOES) String tipo) {
        return cs.delete("/api/applications/{id}/integrations/{tipo}", id, tipo);
    }

    /** Gera certificado de cliente para a integração MQTT da aplicação (contém chave privada). */
    @PostMapping("/{id}/integrations/mqtt/certificate")
    @PreAuthorize(Perfis.SEGREDOS)
    public JsonNode gerarCertificadoMqtt(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.post("/api/applications/{id}/integrations/mqtt/certificate", null, id);
    }
}
