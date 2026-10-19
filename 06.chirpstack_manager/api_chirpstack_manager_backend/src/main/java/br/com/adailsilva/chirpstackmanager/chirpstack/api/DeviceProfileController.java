package br.com.adailsilva.chirpstackmanager.chirpstack.api;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
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
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import tools.jackson.databind.JsonNode;

/**
 * DeviceProfileService do ChirpStack.
 * <p>
 * Desde a 4.19 existem perfis <b>globais</b> (sem tenant, vindos do catálogo de dispositivos) e o
 * catálogo em si: fabricantes ({@code vendors}) e modelos ({@code devices}). Perfis globais e o
 * catálogo valem para todos os tenants, então só o ADMIN altera ou exclui.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/device-profiles")
@PreAuthorize(Perfis.LEITURA)
public class DeviceProfileController {

    private final ChirpStackClient cs;

    public DeviceProfileController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam(required = false) Long limit, @RequestParam(required = false) Long offset,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String tenantId,
                           @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String deviceId,
                           @RequestParam(required = false) Boolean globalOnly,
                           @RequestParam(required = false) Boolean tenantOnly) {
        // deviceId só é aceito pelo ChirpStack junto com globalOnly=true.
        Boolean global = deviceId != null ? Boolean.TRUE : globalOnly;
        return cs.get("/api/device-profiles", Query.of().page(limit, offset, cs.maxPageSize())
                .add("search", search).add("tenantId", Boolean.TRUE.equals(global) ? null : tenantId)
                .add("deviceId", deviceId).add("globalOnly", global).add("tenantOnly", tenantOnly));
    }

    // ── Catálogo de dispositivos (4.19+) ─────────────────────────────────────

    @GetMapping("/vendors")
    public JsonNode listarFabricantes(@RequestParam(required = false) Long limit,
                                      @RequestParam(required = false) Long offset) {
        return cs.get("/api/device-profiles/vendors", Query.of().page(limit, offset, cs.maxPageSize()));
    }

    @GetMapping("/vendors/{id}")
    public JsonNode buscarFabricante(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/device-profiles/vendors/{id}", null, id);
    }

    @DeleteMapping("/vendors/{id}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode excluirFabricante(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/device-profiles/vendors/{id}", id);
    }

    @GetMapping("/devices")
    public JsonNode listarModelos(@RequestParam(required = false) Long limit,
                                  @RequestParam(required = false) Long offset,
                                  @RequestParam(required = false) @Pattern(regexp = Ids.UUID) String vendorId) {
        return cs.get("/api/device-profiles/devices", Query.of().page(limit, offset, cs.maxPageSize())
                .add("vendorId", vendorId));
    }

    @GetMapping("/devices/{id}")
    public JsonNode buscarModelo(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/device-profiles/devices/{id}", null, id);
    }

    @DeleteMapping("/devices/{id}")
    @PreAuthorize(Perfis.ADMIN)
    public JsonNode excluirModelo(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.delete("/api/device-profiles/devices/{id}", id);
    }

    /** Perfil pelo ProfileID do TR0005 (LoRa Alliance Vendor ID + Vendor Profile ID). */
    @GetMapping("/por-perfil-fabricante/{vendorId}/{vendorProfileId}")
    public JsonNode buscarPorPerfilDoFabricante(@PathVariable @Min(0) long vendorId,
                                                @PathVariable @Min(0) long vendorProfileId) {
        return cs.get("/api/device-profiles/{vendorId}/{vendorProfileId}", null, vendorId, vendorProfileId);
    }

    @GetMapping("/adr-algorithms")
    public JsonNode algoritmosAdr() {
        return cs.get("/api/device-profiles/adr-algorithms", null);
    }

    @PostMapping
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode criar(@RequestBody JsonNode body) {
        return cs.post("/api/device-profiles", body);
    }

    @GetMapping("/{id}")
    public JsonNode buscar(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return cs.get("/api/device-profiles/{id}", null, id);
    }

    @PutMapping("/{id}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode atualizar(@PathVariable @Pattern(regexp = Ids.UUID) String id, @RequestBody JsonNode body,
                              Authentication auth) {
        exigirAdminSeGlobal(id, auth);
        return cs.put("/api/device-profiles/{id}", body, id);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode excluir(@PathVariable @Pattern(regexp = Ids.UUID) String id, Authentication auth) {
        exigirAdminSeGlobal(id, auth);
        return cs.delete("/api/device-profiles/{id}", id);
    }

    /** Perfil global (sem tenant) vale para todos os tenants: só o ADMIN altera ou exclui. */
    private void exigirAdminSeGlobal(String id, Authentication auth) {
        boolean admin = auth != null && auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
        if (admin) {
            return;
        }
        JsonNode atual = cs.get("/api/device-profiles/{id}", null, id);
        String tenant = atual.path("deviceProfile").path("tenantId").asString("");
        if (tenant.isBlank()) {
            throw new AccessDeniedException("Perfil global: somente o administrador pode alterar.");
        }
    }
}
