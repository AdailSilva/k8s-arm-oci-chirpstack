package br.com.adailsilva.chirpstackmanager.api.exception;

import org.springframework.http.HttpStatus;

/**
 * Erro de regra de negócio com mensagem pronta para o usuário.
 */
public class BusinessException extends RuntimeException {

    private final HttpStatus status;

    public BusinessException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
