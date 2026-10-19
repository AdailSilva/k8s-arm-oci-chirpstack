package br.com.adailsilva.chirpstackmanager.backup.drive;

import java.net.URI;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.auditoria.AuditoriaService;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveService.ConfigRequest;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveService.ConfigResponse;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveService.ResultadoEnvio;
import br.com.adailsilva.chirpstackmanager.security.Perfis;
import br.com.adailsilva.chirpstackmanager.web.ClientInfo;
import jakarta.servlet.http.HttpServletRequest;

/**
 * Backup → Google Drive. O callback é a única rota sem JWT (o navegador volta do Google sem o
 * cabeçalho Authorization); a proteção é o {@code state} de uso único conferido no banco.
 */
@RestController
@RequestMapping("/api/v1/backup/google-drive")
public class GoogleDriveController {

    private final GoogleDriveService service;
    private final AuditoriaService auditoria;

    public GoogleDriveController(GoogleDriveService service, AuditoriaService auditoria) {
        this.service = service;
        this.auditoria = auditoria;
    }

    @GetMapping
    @PreAuthorize(Perfis.ADMIN)
    public ConfigResponse consultar() {
        return service.consultar();
    }

    @PutMapping
    @PreAuthorize(Perfis.ADMIN)
    public ConfigResponse salvar(@RequestBody ConfigRequest req, @AuthenticationPrincipal Jwt jwt,
                                 HttpServletRequest http) {
        ConfigResponse r = service.salvar(req, jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "CONFIGURAR_DRIVE", "/backup/google-drive", "PUT", 200, true,
                "Pasta: " + r.pastaNome() + (req.clientSecret() != null && !req.clientSecret().isBlank()
                        ? " (Client Secret alterado)" : ""), ClientInfo.ip(http));
        return r;
    }

    /** Devolve a URL do consentimento do Google; o navegador é levado até ela. */
    @PostMapping("/autorizar")
    @PreAuthorize(Perfis.ADMIN)
    public Map<String, String> autorizar(@AuthenticationPrincipal Jwt jwt) {
        return Map.of("url", service.iniciarAutorizacao(jwt.getSubject()));
    }

    @GetMapping("/callback")
    public ResponseEntity<Void> callback(@RequestParam(required = false) String code,
                                         @RequestParam(required = false) String state,
                                         @RequestParam(required = false) String error) {
        String destino = service.concluirAutorizacao(code, state, error);
        return ResponseEntity.status(HttpStatus.FOUND)
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .location(URI.create(destino))
                .build();
    }

    @DeleteMapping("/conexao")
    @PreAuthorize(Perfis.ADMIN)
    public ConfigResponse desconectar(@AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        ConfigResponse r = service.desconectar(jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "DESCONECTAR_DRIVE", "/backup/google-drive/conexao", "DELETE", 200, true,
                null, ClientInfo.ip(http));
        return r;
    }

    @PostMapping("/testar")
    @PreAuthorize(Perfis.ADMIN)
    public ResultadoEnvio testar() {
        return service.testar();
    }
}
