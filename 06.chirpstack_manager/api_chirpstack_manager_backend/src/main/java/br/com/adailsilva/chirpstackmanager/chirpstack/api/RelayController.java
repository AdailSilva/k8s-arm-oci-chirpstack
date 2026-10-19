package br.com.adailsilva.chirpstackmanager.chirpstack.api;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.chirpstack.ChirpStackClient;
import br.com.adailsilva.chirpstackmanager.chirpstack.Query;
import br.com.adailsilva.chirpstackmanager.security.Ids;
import br.com.adailsilva.chirpstackmanager.security.Perfis;
import br.com.adailsilva.chirpstackmanager.web.BusinessException;
import jakarta.validation.constraints.Pattern;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.JsonNodeFactory;
import tools.jackson.databind.node.ObjectNode;

/**
 * RelayService do ChirpStack (LoRaWAN TS011 - Relay), exposto pela REST API a partir da 4.19.
 * <p>
 * Um relay é um dispositivo da aplicação cujo perfil tem o modo relay ligado; os dispositivos
 * finais atribuídos a ele passam a ter o tráfego encaminhado por esse relay.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/relays")
@PreAuthorize(Perfis.LEITURA)
public class RelayController {

    private final ChirpStackClient cs;

    public RelayController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode listar(@RequestParam @Pattern(regexp = Ids.UUID) String applicationId,
                           @RequestParam(required = false) Long limit,
                           @RequestParam(required = false) Long offset) {
        return cs.get("/api/relays", Query.of().page(limit, offset, cs.maxPageSize())
                .add("applicationId", applicationId));
    }

    @GetMapping("/{relayDevEui}/devices")
    public JsonNode listarDispositivos(@PathVariable @Pattern(regexp = Ids.EUI64) String relayDevEui,
                                       @RequestParam(required = false) Long limit,
                                       @RequestParam(required = false) Long offset) {
        return cs.get("/api/relays/{relayDevEui}/devices", Query.of().page(limit, offset, cs.maxPageSize()),
                relayDevEui);
    }

    /** Corpo: {@code {"deviceDevEui": "0102030405060708"}}. */
    @PostMapping("/{relayDevEui}/devices")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode adicionarDispositivo(@PathVariable @Pattern(regexp = Ids.EUI64) String relayDevEui,
                                         @RequestBody JsonNode body) {
        String devEui = body.path("deviceDevEui").asString("");
        if (!devEui.matches(Ids.EUI64)) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "deviceDevEui inválido: informe 16 dígitos hexadecimais");
        }
        ObjectNode corpo = JsonNodeFactory.instance.objectNode();
        corpo.put("relayDevEui", relayDevEui);
        corpo.put("deviceDevEui", devEui);
        return cs.post("/api/relays/{relayDevEui}/devices", corpo, relayDevEui);
    }

    @DeleteMapping("/{relayDevEui}/devices/{deviceDevEui}")
    @PreAuthorize(Perfis.ESCRITA)
    public JsonNode removerDispositivo(@PathVariable @Pattern(regexp = Ids.EUI64) String relayDevEui,
                                       @PathVariable @Pattern(regexp = Ids.EUI64) String deviceDevEui) {
        return cs.delete("/api/relays/{relayDevEui}/devices/{deviceDevEui}", relayDevEui, deviceDevEui);
    }
}
