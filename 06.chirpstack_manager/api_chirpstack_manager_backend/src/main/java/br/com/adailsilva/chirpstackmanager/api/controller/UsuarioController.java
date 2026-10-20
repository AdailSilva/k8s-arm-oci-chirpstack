package br.com.adailsilva.chirpstackmanager.api.controller;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.api.security.Perfis;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.UsuarioDtos.UsuarioCreateRequest;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.UsuarioDtos.UsuarioResponse;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.UsuarioDtos.UsuarioUpdateRequest;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.response.Pagina;
import jakarta.validation.Valid;
import br.com.adailsilva.chirpstackmanager.api.service.UsuarioService;

/**
 * CRUD dos usuários do painel (somente ADMIN).
 */
@RestController
@RequestMapping("/api/v1/usuarios")
@PreAuthorize(Perfis.ADMIN)
public class UsuarioController {

    private final UsuarioService service;

    public UsuarioController(UsuarioService service) {
        this.service = service;
    }

    @GetMapping
    public Pagina<UsuarioResponse> listar(@RequestParam(required = false) String busca,
                                          @RequestParam(defaultValue = "0") int pagina,
                                          @RequestParam(defaultValue = "20") int tamanho) {
        return Pagina.of(service.listar(busca, pagina, tamanho), UsuarioResponse::of);
    }

    @GetMapping("/{id}")
    public UsuarioResponse buscar(@PathVariable Long id) {
        return UsuarioResponse.of(service.buscar(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UsuarioResponse criar(@Valid @RequestBody UsuarioCreateRequest req) {
        return UsuarioResponse.of(service.criar(req));
    }

    @PutMapping("/{id}")
    public UsuarioResponse atualizar(@PathVariable Long id, @Valid @RequestBody UsuarioUpdateRequest req,
                                     @AuthenticationPrincipal Jwt jwt) {
        return UsuarioResponse.of(service.atualizar(id, req, jwt.getSubject()));
    }

    @PostMapping("/{id}/desbloquear")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void desbloquear(@PathVariable Long id) {
        service.desbloquear(id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        service.excluir(id, jwt.getSubject());
    }
}
