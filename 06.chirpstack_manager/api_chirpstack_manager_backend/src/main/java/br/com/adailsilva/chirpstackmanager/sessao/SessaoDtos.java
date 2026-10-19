package br.com.adailsilva.chirpstackmanager.sessao;

import java.time.Instant;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public final class SessaoDtos {

    private SessaoDtos() {
    }

    /**
     * O que o navegador precisa para controlar o logoff: id da sessão, inatividade tolerada
     * ({@code 0} = sem limite), antecedência do aviso e o fim absoluto da sessão.
     * {@code agora} é o relógio do servidor, para compensar relógio errado no computador do usuário.
     */
    public record SessaoInfo(String id, int inatividadeSegundos, int avisoSegundos, Instant expiraEm,
                             Instant ultimaAtividade, boolean manterConectado, Instant agora) {
        public static SessaoInfo of(Sessao s, PoliticaSessao p) {
            return new SessaoInfo(s.getId(), Math.max(p.getInatividadeMinutos(), 0) * 60, p.getAvisoSegundos(),
                    s.getExpiraEm(), s.getUltimaAtividade(), p.isManterConectado(), Instant.now());
        }
    }

    /** Sinal periódico do navegador. {@code ativo} = houve interação desde o último sinal. */
    public record AtividadeRequest(boolean ativo) {
    }

    public record PoliticaResponse(int inatividadeMinutos, int avisoSegundos, int duracaoMaximaHoras,
                                   int maxSessoesPorUsuario, boolean manterConectado, Instant atualizadoEm,
                                   String atualizadoPor) {
        public static PoliticaResponse of(PoliticaSessao p) {
            return new PoliticaResponse(p.getInatividadeMinutos(), p.getAvisoSegundos(), p.getDuracaoMaximaHoras(),
                    p.getMaxSessoesPorUsuario(), p.isManterConectado(), p.getAtualizadoEm(), p.getAtualizadoPor());
        }
    }

    public record PoliticaRequest(
            @NotNull @Min(value = 0, message = "Inatividade: de 0 (desligado) a 1440 minutos.")
            @Max(value = 1440, message = "Inatividade: de 0 (desligado) a 1440 minutos.") Integer inatividadeMinutos,
            @NotNull @Min(value = 15, message = "Aviso: de 15 a 900 segundos.")
            @Max(value = 900, message = "Aviso: de 15 a 900 segundos.") Integer avisoSegundos,
            @NotNull @Min(value = 1, message = "Duração máxima: de 1 a 720 horas.")
            @Max(value = 720, message = "Duração máxima: de 1 a 720 horas.") Integer duracaoMaximaHoras,
            @NotNull @Min(value = 0, message = "Sessões simultâneas: de 0 (ilimitado) a 20.")
            @Max(value = 20, message = "Sessões simultâneas: de 0 (ilimitado) a 20.") Integer maxSessoesPorUsuario,
            @NotNull Boolean manterConectado,
            /** Aplica a nova política às sessões abertas encerrando todas (exceto a do próprio ADMIN). */
            Boolean encerrarSessoesAbertas) {
    }
}
