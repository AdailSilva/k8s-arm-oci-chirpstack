package br.com.adailsilva.chirpstackmanager.api.exception;

import br.com.adailsilva.chirpstackmanager.api.domain.enums.MotivoEncerramento;

/**
 * A sessão do token terminou de vez: renovar não adianta. Vira 401 com o cabeçalho
 * {@value #HEADER}: {@value #ENCERRADA}, que faz o frontend ir direto ao login exibindo o motivo.
 */
public class SessaoEncerradaException extends RuntimeException {

    public static final String HEADER = "X-Sessao-Status";
    public static final String HEADER_MOTIVO = "X-Sessao-Motivo";
    public static final String ENCERRADA = "ENCERRADA";
    public static final String CODIGO = "SESSAO_ENCERRADA";

    private final MotivoEncerramento motivo;

    public SessaoEncerradaException(MotivoEncerramento motivo) {
        super(motivo.mensagem());
        this.motivo = motivo;
    }

    public MotivoEncerramento getMotivo() {
        return motivo;
    }
}
