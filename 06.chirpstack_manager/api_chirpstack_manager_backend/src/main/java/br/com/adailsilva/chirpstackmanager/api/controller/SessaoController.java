package br.com.adailsilva.chirpstackmanager.api.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.api.service.AuditoriaService;
import br.com.adailsilva.chirpstackmanager.api.security.Perfis;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.SessaoDtos.AtividadeRequest;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.SessaoDtos.PoliticaRequest;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.SessaoDtos.PoliticaResponse;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.SessaoDtos.SessaoInfo;
import br.com.adailsilva.chirpstackmanager.api.exception.BusinessException;
import br.com.adailsilva.chirpstackmanager.api.web.ClientInfo;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.PoliticaSessao;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.MotivoEncerramento;
import br.com.adailsilva.chirpstackmanager.api.exception.SessaoEncerradaException;
import br.com.adailsilva.chirpstackmanager.api.service.SessaoService;

/**
 * Sessão do próprio usuário (sinal de atividade) e política de logoff (ADMIN).
 */
@RestController
@RequestMapping("/api/v1/sessao")
@Validated
public class SessaoController {

    private final SessaoService service;
    private final AuditoriaService auditoria;

    public SessaoController(SessaoService service, AuditoriaService auditoria) {
        this.service = service;
        this.auditoria = auditoria;
    }

    /** Situação da sessão atual (tempo de inatividade, aviso e fim absoluto). */
    @GetMapping
    public SessaoInfo atual(@AuthenticationPrincipal Jwt jwt) {
        return service.buscar(jwt.getClaimAsString("sid")).map(service::info)
                .orElseThrow(() -> new SessaoEncerradaException(MotivoEncerramento.INVALIDA));
    }

    /**
     * Sinal periódico do navegador (a cada minuto). Mantém o usuário "on-line" no monitor e,
     * com {@code ativo=true}, renova o prazo de inatividade.
     */
    @PostMapping("/atividade")
    public SessaoInfo atividade(@AuthenticationPrincipal Jwt jwt, @RequestBody AtividadeRequest req) {
        return service.registrarAtividade(jwt.getClaimAsString("sid"), req != null && req.ativo());
    }

    @GetMapping("/politica")
    @PreAuthorize(Perfis.ADMIN)
    public PoliticaResponse politica() {
        return PoliticaResponse.of(service.politica());
    }

    @PutMapping("/politica")
    @PreAuthorize(Perfis.ADMIN)
    public PoliticaResponse salvarPolitica(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody PoliticaRequest req,
                                           HttpServletRequest http) {
        if (req.inatividadeMinutos() > 0 && req.avisoSegundos() >= req.inatividadeMinutos() * 60) {
            throw new BusinessException(org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY,
                    "O aviso precisa vir antes do fim do tempo de inatividade.");
        }
        PoliticaSessao p = service.salvarPolitica(req, jwt.getSubject(), jwt.getClaimAsString("sid"));
        auditoria.registrar(jwt.getSubject(), "POLITICA_SESSAO", "/sessao/politica", "PUT", 200, true,
                "Inatividade " + p.getInatividadeMinutos() + " min, máximo " + p.getDuracaoMaximaHoras()
                        + " h, simultâneas " + p.getMaxSessoesPorUsuario() + ", manter conectado "
                        + (p.isManterConectado() ? "sim" : "não"),
                ClientInfo.ip(http));
        return PoliticaResponse.of(p);
    }
}
