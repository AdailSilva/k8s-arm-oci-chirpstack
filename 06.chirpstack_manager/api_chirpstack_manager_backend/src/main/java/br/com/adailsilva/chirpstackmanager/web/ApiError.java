package br.com.adailsilva.chirpstackmanager.web;

import java.time.Instant;
import java.util.List;

/**
 * Corpo padrão de erro devolvido ao frontend.
 *
 * @param status   código HTTP
 * @param erro     identificador curto do erro
 * @param mensagem mensagem amigável em português
 * @param detalhe  detalhe técnico (por exemplo, a mensagem original do ChirpStack)
 * @param campos   erros de validação por campo
 */
public record ApiError(Instant timestamp, int status, String erro, String mensagem, String detalhe, List<Campo> campos) {

    public record Campo(String campo, String mensagem) {
    }

    public static ApiError of(int status, String erro, String mensagem, String detalhe) {
        return new ApiError(Instant.now(), status, erro, mensagem, detalhe, null);
    }
}
