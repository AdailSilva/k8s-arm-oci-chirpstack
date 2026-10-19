package br.com.adailsilva.chirpstackmanager.visitante;

import java.time.Instant;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.auditoria.AuditoriaService;
import br.com.adailsilva.chirpstackmanager.security.Ids;
import br.com.adailsilva.chirpstackmanager.security.Perfis;
import br.com.adailsilva.chirpstackmanager.usuario.Usuario;
import br.com.adailsilva.chirpstackmanager.usuario.UsuarioDtos.UsuarioResponse;
import br.com.adailsilva.chirpstackmanager.usuario.UsuarioService;
import br.com.adailsilva.chirpstackmanager.visitante.VisitanteDtos.BloqueioRequest;
import br.com.adailsilva.chirpstackmanager.visitante.VisitanteDtos.Falha;
import br.com.adailsilva.chirpstackmanager.visitante.VisitanteDtos.Quantidade;
import br.com.adailsilva.chirpstackmanager.visitante.VisitanteDtos.Resumo;
import br.com.adailsilva.chirpstackmanager.visitante.VisitanteDtos.SessaoResponse;
import br.com.adailsilva.chirpstackmanager.visitante.VisitanteDtos.VisitanteUsuario;
import br.com.adailsilva.chirpstackmanager.web.ClientInfo;
import br.com.adailsilva.chirpstackmanager.web.Pagina;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;

/**
 * Controle e monitoramento de visitantes (somente ADMIN).
 */
@RestController
@RequestMapping("/api/v1/visitantes")
@PreAuthorize(Perfis.ADMIN)
@Validated
public class VisitanteController {

    private final VisitanteService service;
    private final UsuarioService usuarios;
    private final AuditoriaService auditoria;

    public VisitanteController(VisitanteService service, UsuarioService usuarios, AuditoriaService auditoria) {
        this.service = service;
        this.usuarios = usuarios;
        this.auditoria = auditoria;
    }

    @GetMapping("/resumo")
    public Resumo resumo(@RequestParam(defaultValue = "14") int dias) {
        return service.resumo(dias);
    }

    /** Sessões abertas agora (monitor em tempo real; a tela consulta a cada 10 s). */
    @GetMapping("/sessoes")
    public List<SessaoResponse> sessoesAbertas(@AuthenticationPrincipal Jwt jwt) {
        return service.sessoesAbertas(jwt.getClaimAsString("sid"));
    }

    @GetMapping("/usuarios")
    public List<VisitanteUsuario> porUsuario() {
        return service.porUsuario();
    }

    @GetMapping("/acessos")
    public Pagina<SessaoResponse> historico(@AuthenticationPrincipal Jwt jwt,
                                            @RequestParam(required = false) Long usuarioId,
                                            @RequestParam(required = false) String busca,
                                            @RequestParam(required = false) String situacao,
                                            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant de,
                                            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant ate,
                                            @RequestParam(defaultValue = "0") int pagina,
                                            @RequestParam(defaultValue = "20") int tamanho) {
        return Pagina.of(service.historico(usuarioId, busca, situacao, de, ate, pagina, tamanho,
                jwt.getClaimAsString("sid")), s -> s);
    }

    @GetMapping("/falhas")
    public List<Falha> falhas() {
        return service.falhasRecentes();
    }

    @PostMapping("/sessoes/{id}/encerrar")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void encerrarSessao(@PathVariable @Pattern(regexp = Ids.UUID) String id, @AuthenticationPrincipal Jwt jwt,
                               HttpServletRequest http) {
        service.encerrarSessao(id, jwt.getSubject(), jwt.getClaimAsString("sid"));
        auditoria.registrar(jwt.getSubject(), "ENCERRAR_SESSAO", "/visitantes/sessoes/" + id, "POST", 204, true,
                null, ClientInfo.ip(http));
    }

    @PostMapping("/usuarios/{id}/encerrar-sessoes")
    public Quantidade encerrarDoUsuario(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt,
                                        HttpServletRequest http) {
        int n = service.encerrarDoUsuario(id, jwt.getSubject(), jwt.getClaimAsString("sid"));
        auditoria.registrar(jwt.getSubject(), "ENCERRAR_SESSAO", "/visitantes/usuarios/" + id, "POST", 200, true,
                n + " sessão(ões)", ClientInfo.ip(http));
        return new Quantidade(n);
    }

    /** Desconecta todos os usuários, exceto a sessão de quem executa. */
    @PostMapping("/encerrar-todas")
    public Quantidade encerrarTodas(@AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        int n = service.encerrarTodas(jwt.getSubject(), jwt.getClaimAsString("sid"));
        auditoria.registrar(jwt.getSubject(), "ENCERRAR_SESSAO", "/visitantes/encerrar-todas", "POST", 200, true,
                n + " sessão(ões)", ClientInfo.ip(http));
        return new Quantidade(n);
    }

    @PostMapping("/usuarios/{id}/bloqueio")
    public UsuarioResponse bloquear(@PathVariable Long id, @Valid @RequestBody BloqueioRequest req,
                                    @AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        Usuario u = req.permanente()
                ? usuarios.desativar(id, req.motivo(), jwt.getSubject())
                : usuarios.bloquear(id, req.ate(), req.motivo(), jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), req.permanente() ? "DESATIVAR_USUARIO" : "BLOQUEAR_ACESSO",
                "/visitantes/usuarios/" + id, "POST", 200, true,
                u.getEmail() + (req.motivo() != null && !req.motivo().isBlank() ? " — " + req.motivo() : ""),
                ClientInfo.ip(http));
        return UsuarioResponse.of(u);
    }

    @DeleteMapping("/usuarios/{id}/bloqueio")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void desbloquear(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        usuarios.desbloquear(id);
        auditoria.registrar(jwt.getSubject(), "DESBLOQUEAR_ACESSO", "/visitantes/usuarios/" + id, "DELETE", 204,
                true, null, ClientInfo.ip(http));
    }
}
