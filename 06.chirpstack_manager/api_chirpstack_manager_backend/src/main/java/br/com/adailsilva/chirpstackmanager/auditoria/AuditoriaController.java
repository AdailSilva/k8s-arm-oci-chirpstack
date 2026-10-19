package br.com.adailsilva.chirpstackmanager.auditoria;

import java.time.Instant;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.security.Perfis;
import br.com.adailsilva.chirpstackmanager.web.Pagina;

/**
 * Consulta da auditoria (somente ADMIN).
 */
@RestController
@RequestMapping("/api/v1/auditoria")
@PreAuthorize(Perfis.ADMIN)
public class AuditoriaController {

    private final AuditoriaService service;

    public AuditoriaController(AuditoriaService service) {
        this.service = service;
    }

    public record AuditoriaResponse(Long id, String usuario, String acao, String recurso, String metodo,
                                    Integer statusHttp, boolean sucesso, String detalhe, String ip, Instant criadoEm) {
        static AuditoriaResponse of(Auditoria a) {
            return new AuditoriaResponse(a.getId(), a.getUsuario(), a.getAcao(), a.getRecurso(), a.getMetodo(),
                    a.getStatusHttp(), a.isSucesso(), a.getDetalhe(), a.getIp(), a.getCriadoEm());
        }
    }

    @GetMapping
    public Pagina<AuditoriaResponse> listar(@RequestParam(required = false) String busca,
                                            @RequestParam(required = false) String acao,
                                            @RequestParam(defaultValue = "0") int pagina,
                                            @RequestParam(defaultValue = "50") int tamanho) {
        return Pagina.of(service.listar(busca, acao, pagina, tamanho), AuditoriaResponse::of);
    }
}
