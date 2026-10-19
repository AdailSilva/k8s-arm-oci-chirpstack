package br.com.adailsilva.chirpstackmanager.backup.drive;

/**
 * Falha ao falar com o Google, já com a mensagem que diz o que fazer.
 * {@code autorizacaoInvalida} = o refresh token gravado não vale mais (conectar de novo).
 */
public class GoogleDriveException extends RuntimeException {

    private final int status;
    private final boolean autorizacaoInvalida;

    public GoogleDriveException(String mensagem, int status, boolean autorizacaoInvalida) {
        super(mensagem);
        this.status = status;
        this.autorizacaoInvalida = autorizacaoInvalida;
    }

    public int getStatus() {
        return status;
    }

    public boolean isAutorizacaoInvalida() {
        return autorizacaoInvalida;
    }
}
