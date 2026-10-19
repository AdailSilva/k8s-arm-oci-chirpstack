package br.com.adailsilva.chirpstackmanager.auth;

import java.time.Duration;

import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.adailsilva.chirpstackmanager.auth.AuthDtos.LoginRequest;
import br.com.adailsilva.chirpstackmanager.auth.AuthDtos.LogoutRequest;
import br.com.adailsilva.chirpstackmanager.auth.AuthDtos.Emissao;
import br.com.adailsilva.chirpstackmanager.auth.AuthDtos.TokenResponse;
import br.com.adailsilva.chirpstackmanager.config.SecurityProperties;
import br.com.adailsilva.chirpstackmanager.usuario.UsuarioDtos.PerfilUpdateRequest;
import br.com.adailsilva.chirpstackmanager.usuario.UsuarioDtos.TrocaSenhaRequest;
import br.com.adailsilva.chirpstackmanager.usuario.UsuarioDtos.UsuarioResponse;
import br.com.adailsilva.chirpstackmanager.usuario.UsuarioService;
import br.com.adailsilva.chirpstackmanager.web.ClientInfo;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

/**
 * Autenticação. O access token volta no corpo (o frontend guarda só em memória) e o refresh token
 * vai num cookie {@code HttpOnly; SameSite=Strict} restrito a {@code /api/v1/auth}.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    public static final String COOKIE = "csm_refresh";
    private static final String COOKIE_PATH = "/api/v1/auth";

    private final AuthService auth;
    private final UsuarioService usuarios;
    private final SecurityProperties props;

    public AuthController(AuthService auth, UsuarioService usuarios, SecurityProperties props) {
        this.auth = auth;
        this.usuarios = usuarios;
        this.props = props;
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        Emissao s = auth.login(req.email(), req.senha(), ClientInfo.ip(http), http.getHeader(HttpHeaders.USER_AGENT));
        return comCookie(s);
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@CookieValue(name = COOKIE, required = false) String refresh,
                                                 HttpServletRequest http) {
        try {
            Emissao s = auth.renovar(refresh, ClientInfo.ip(http), http.getHeader(HttpHeaders.USER_AGENT));
            return comCookie(s);
        } catch (RuntimeException e) {
            // Sessão inválida: apaga o cookie antes de responder 401.
            throw new CookieClearingException(e, cookie("", Duration.ZERO));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@CookieValue(name = COOKIE, required = false) String refresh,
                                       @AuthenticationPrincipal Jwt jwt,
                                       @RequestBody(required = false) LogoutRequest req, HttpServletRequest http) {
        boolean inatividade = req != null && "INATIVIDADE".equalsIgnoreCase(req.motivo());
        auth.logout(refresh, jwt != null ? jwt.getSubject() : null, jwt != null ? jwt.getClaimAsString("sid") : null,
                inatividade, ClientInfo.ip(http));
        return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, cookie("", Duration.ZERO).toString())
                .build();
    }

    @GetMapping("/me")
    public UsuarioResponse me(@AuthenticationPrincipal Jwt jwt) {
        return UsuarioResponse.of(usuarios.porEmail(jwt.getSubject()));
    }

    @PutMapping("/me")
    public UsuarioResponse atualizarMe(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody PerfilUpdateRequest req) {
        return UsuarioResponse.of(usuarios.atualizarNome(jwt.getSubject(), req.nome()));
    }

    @PostMapping("/me/senha")
    public ResponseEntity<Void> trocarSenha(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody TrocaSenhaRequest req) {
        usuarios.trocarSenha(jwt.getSubject(), req.senhaAtual(), req.novaSenha());
        return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, cookie("", Duration.ZERO).toString())
                .build();
    }

    private ResponseEntity<TokenResponse> comCookie(Emissao s) {
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie(s.refreshToken(), s.cookieMaxAge()).toString())
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .body(s.resposta());
    }

    /** {@code maxAge} nulo = cookie de sessão do navegador (a política "manter conectado" está desligada). */
    private ResponseCookie cookie(String valor, Duration maxAge) {
        ResponseCookie.ResponseCookieBuilder b = ResponseCookie.from(COOKIE, valor)
                .httpOnly(true)
                .secure(props.cookieSecure())
                .sameSite("Strict")
                .path(COOKIE_PATH);
        if (maxAge != null) {
            b.maxAge(maxAge);
        }
        return b.build();
    }
}
