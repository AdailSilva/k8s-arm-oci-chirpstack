package br.com.adailsilva.chirpstackmanager.auth;

import org.springframework.http.ResponseCookie;

/**
 * Envolve a falha de renovação para que o handler devolva o erro e também apague o cookie.
 */
public class CookieClearingException extends RuntimeException {

    private final transient ResponseCookie cookie;

    public CookieClearingException(RuntimeException cause, ResponseCookie cookie) {
        super(cause.getMessage(), cause);
        this.cookie = cookie;
    }

    public ResponseCookie getCookie() {
        return cookie;
    }

    public RuntimeException getOriginal() {
        return (RuntimeException) getCause();
    }
}
