package br.com.adailsilva.chirpstackmanager.api.domain.dto;

import java.time.Duration;

import br.com.adailsilva.chirpstackmanager.api.domain.dto.SessaoDtos.SessaoInfo;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.UsuarioDtos.UsuarioResponse;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AuthDtos {

    private AuthDtos() {
    }

    public record LoginRequest(
            @NotBlank(message = "Informe o e-mail.") @Size(max = 160) String email,
            @NotBlank(message = "Informe a senha.") @Size(max = 72) String senha) {
    }

    /**
     * Resposta de login/refresh. O refresh token vai somente no cookie HttpOnly.
     */
    public record TokenResponse(String accessToken, String tokenType, long expiresIn, UsuarioResponse usuario,
                                SessaoInfo sessao) {
    }

    /**
     * Resultado interno do login: resposta + refresh token em texto puro (para o cookie).
     * {@code cookieMaxAge} nulo = cookie de sessão do navegador (some ao fechar o navegador).
     */
    public record Emissao(TokenResponse resposta, String refreshToken, Duration cookieMaxAge) {
    }

    /** Logout informado pelo navegador; {@code motivo} aceita apenas LOGOUT ou INATIVIDADE. */
    public record LogoutRequest(String motivo) {
    }
}
