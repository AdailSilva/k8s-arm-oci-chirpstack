package br.com.adailsilva.chirpstackmanager.usuario;

import java.time.Instant;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * DTOs do módulo de usuários do painel.
 */
public final class UsuarioDtos {

    /** Senha: 8 a 72 caracteres, com pelo menos uma letra e um número. */
    public static final String SENHA_REGEX = "^(?=.*[A-Za-z])(?=.*\\d).{8,72}$";
    public static final String SENHA_MSG = "A senha deve ter de 8 a 72 caracteres, com letras e números.";

    private UsuarioDtos() {
    }

    public record UsuarioResponse(Long id, String nome, String email, Perfil perfil, boolean ativo,
                                  boolean bloqueado, Instant bloqueadoAte, String motivoBloqueio,
                                  Instant ultimoLogin, Instant criadoEm, Instant atualizadoEm) {
        public static UsuarioResponse of(Usuario u) {
            boolean bloqueado = u.isBloqueado();
            return new UsuarioResponse(u.getId(), u.getNome(), u.getEmail(), u.getPerfil(), u.isAtivo(),
                    bloqueado, bloqueado ? u.getBloqueadoAte() : null, bloqueado ? u.getMotivoBloqueio() : null,
                    u.getUltimoLogin(), u.getCriadoEm(), u.getAtualizadoEm());
        }
    }

    public record UsuarioCreateRequest(
            @NotBlank(message = "Informe o nome.") @Size(max = 120) String nome,
            @NotBlank(message = "Informe o e-mail.") @Email(message = "E-mail inválido.") @Size(max = 160) String email,
            @NotBlank(message = "Informe a senha.") @Pattern(regexp = SENHA_REGEX, message = SENHA_MSG) String senha,
            @NotNull(message = "Informe o perfil.") Perfil perfil,
            Boolean ativo) {
    }

    public record UsuarioUpdateRequest(
            @NotBlank(message = "Informe o nome.") @Size(max = 120) String nome,
            @NotBlank(message = "Informe o e-mail.") @Email(message = "E-mail inválido.") @Size(max = 160) String email,
            @NotNull(message = "Informe o perfil.") Perfil perfil,
            @NotNull Boolean ativo,
            /** Opcional: quando informada, redefine a senha. */
            @Pattern(regexp = SENHA_REGEX, message = SENHA_MSG) String novaSenha) {
    }

    public record PerfilUpdateRequest(@NotBlank(message = "Informe o nome.") @Size(max = 120) String nome) {
    }

    public record TrocaSenhaRequest(
            @NotBlank(message = "Informe a senha atual.") String senhaAtual,
            @NotBlank(message = "Informe a nova senha.") @Pattern(regexp = SENHA_REGEX, message = SENHA_MSG) String novaSenha) {
    }
}
