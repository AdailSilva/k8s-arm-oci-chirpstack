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
 * DeviceProfileTemplateService do ChirpStack (modelos globais de device-profile). Escrita só para ADMIN.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/device-profile-templates")
@PreAuthorize(Perfis.LEITURA)
public class DeviceProfileTemplateController {

    private final ChirpStackClient cs;

    public DeviceProfileTemplateController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset) {
        return cs.get("/api/device-profile-templates", Query.of().page(limit, offset, cs.maxPageSize()));
    }

    @PostMapping
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/device-profile-templates", body);
    }

    @GetMapping("/{id}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.TEMPLATE_ID) String id) {
        return cs.get("/api/device-profile-templates/{id}", null, id);
    }

    @PutMapping("/{id}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.TEMPLATE_ID) String id, @RequestBody JsonNode body) {
        return cs.put("/api/device-profile-templates/{id}", body, id);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.TEMPLATE_ID) String id) {
        return cs.delete("/api/device-profile-templates/{id}", id);
    }
}
