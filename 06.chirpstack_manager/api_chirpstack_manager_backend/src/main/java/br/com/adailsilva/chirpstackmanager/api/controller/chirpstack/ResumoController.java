package br.com.adailsilva.chirpstackmanager.api.controller.chirpstack;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.api.service.chirpstack.ChirpStackClient;
import br.com.adailsilva.chirpstackmanager.api.service.chirpstack.Query;
import br.com.adailsilva.chirpstackmanager.api.security.Ids;
import br.com.adailsilva.chirpstackmanager.api.security.Perfis;
import jakarta.validation.constraints.Pattern;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.JsonNodeFactory;
import tools.jackson.databind.node.ObjectNode;

/**
 * Indicadores do painel inicial de um tenant, calculados no backend a partir das listas do ChirpStack.
 */
@RestController
@RequestMapping("/api/v1/chirpstack/resumo")
@PreAuthorize(Perfis.LEITURA)
public class ResumoController {

    private static final int LIMITE = 1000;

    private final ChirpStackClient cs;

    public ResumoController(ChirpStackClient cs) {
        this.cs = cs;
    }

    @GetMapping
    public JsonNode resumo(@RequestParam @Pattern(regexp = Ids.UUID) String tenantId) {
        JsonNodeFactory f = JsonNodeFactory.instance;
        ObjectNode out = f.objectNode();
        Instant limite24h = Instant.now().minusSeconds(86_400);

        // Gateways por estado
        JsonNode gws = cs.get("/api/gateways", Query.of().page((long) LIMITE, 0L, LIMITE).add("tenantId", tenantId));
        long online = 0, offline = 0, nunca = 0;
        for (JsonNode g : gws.path("result")) {
            switch (texto(g.path("state"))) {
                case "ONLINE" -> online++;
                case "OFFLINE" -> offline++;
                default -> nunca++;
            }
        }
        ObjectNode gw = out.putObject("gateways");
        gw.put("total", numero(gws.path("totalCount")));
        gw.put("online", online);
        gw.put("offline", offline);
        gw.put("nuncaVisto", nunca);

        // Aplicações e dispositivos
        JsonNode apps = cs.get("/api/applications", Query.of().page((long) LIMITE, 0L, LIMITE).add("tenantId", tenantId));
        out.put("aplicacoes", numero(apps.path("totalCount")));
        ArrayNode porApp = out.putArray("dispositivosPorAplicacao");
        long totalDisp = 0, ativos = 0, nuncaVistos = 0;
        for (JsonNode app : apps.path("result")) {
            String appId = texto(app.path("id"));
            JsonNode devs = cs.get("/api/devices", Query.of().page((long) LIMITE, 0L, LIMITE).add("applicationId", appId));
            long total = numero(devs.path("totalCount"));
            long ativosApp = 0;
            for (JsonNode d : devs.path("result")) {
                Instant visto = data(d.path("lastSeenAt"));
                if (visto == null) {
                    nuncaVistos++;
                } else if (visto.isAfter(limite24h)) {
                    ativosApp++;
                }
            }
            totalDisp += total;
            ativos += ativosApp;
            ObjectNode item = porApp.addObject();
            item.put("id", appId);
            item.put("name", texto(app.path("name")));
            item.put("total", total);
            item.put("ativos24h", ativosApp);
        }
        ObjectNode disp = out.putObject("dispositivos");
        disp.put("total", totalDisp);
        disp.put("ativos24h", ativos);
        disp.put("nuncaVistos", nuncaVistos);

        JsonNode perfis = cs.get("/api/device-profiles", Query.of().page(1L, 0L, LIMITE).add("tenantId", tenantId));
        out.put("perfis", numero(perfis.path("totalCount")));
        return out;
    }

    private static String texto(JsonNode n) {
        return n == null || n.isMissingNode() || n.isNull() ? "" : n.asString();
    }

    /** O grpc-gateway pode serializar inteiros de 64 bits como texto. */
    private static long numero(JsonNode n) {
        if (n == null || n.isMissingNode() || n.isNull()) {
            return 0;
        }
        if (n.isNumber()) {
            return n.longValue();
        }
        try {
            return Long.parseLong(n.asString());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static Instant data(JsonNode n) {
        String s = texto(n);
        if (s.isEmpty()) {
            return null;
        }
        try {
            return OffsetDateTime.parse(s).toInstant();
        } catch (DateTimeParseException e) {
            return null;
        }
    }
}
