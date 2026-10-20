package br.com.adailsilva.chirpstackmanager.api.domain.dto;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import br.com.adailsilva.chirpstackmanager.api.domain.entity.Auditoria;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Sessao;
import br.com.adailsilva.chirpstackmanager.api.service.SessaoService;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.Perfil;
import jakarta.validation.constraints.Size;

public final class VisitanteDtos {

    private VisitanteDtos() {
    }

    /** Uma sessão (acesso) para as tabelas de monitoramento e histórico. */
    public record SessaoResponse(String id, Long usuarioId, String usuarioNome, String usuarioEmail, String ip,
                                 String dispositivo, String userAgent, Instant iniciadaEm, Instant ultimaAtividade,
                                 Instant ultimoSinal, Instant expiraEm, Instant encerradaEm, String motivoEncerramento,
                                 String motivoDescricao, String encerradaPor, boolean aberta, boolean online,
                                 boolean atual, long duracaoSegundos, long ociosoSegundos) {

        public static SessaoResponse of(Sessao s, String sessaoAtual) {
            Instant agora = Instant.now();
            boolean aberta = s.isAberta();
            Instant fim = aberta ? agora : s.getEncerradaEm();
            return new SessaoResponse(s.getId(), s.getUsuarioId(), s.getUsuarioNome(), s.getUsuarioEmail(), s.getIp(),
                    s.getDispositivo(), s.getUserAgent(), s.getIniciadaEm(), s.getUltimaAtividade(), s.getUltimoSinal(),
                    s.getExpiraEm(), s.getEncerradaEm(),
                    s.getMotivoEncerramento() != null ? s.getMotivoEncerramento().name() : null,
                    s.getMotivoEncerramento() != null ? descricao(s.getMotivoEncerramento().name()) : null,
                    s.getEncerradaPor(), aberta,
                    aberta && s.getUltimoSinal().isAfter(agora.minus(SessaoService.JANELA_ONLINE)),
                    s.getId().equals(sessaoAtual),
                    Math.max(0, Duration.between(s.getIniciadaEm(), fim).toSeconds()),
                    aberta ? Math.max(0, Duration.between(s.getUltimaAtividade(), agora).toSeconds()) : 0);
        }

        public static String descricao(String motivo) {
            return switch (motivo) {
                case "LOGOUT" -> "Saiu";
                case "INATIVIDADE" -> "Inatividade";
                case "EXPIRADA" -> "Tempo máximo";
                case "ENCERRADA_ADMIN" -> "Encerrada pelo administrador";
                case "LIMITE_SESSOES" -> "Limite de sessões";
                case "SENHA_ALTERADA" -> "Senha alterada";
                case "USUARIO_DESATIVADO" -> "Usuário desativado";
                case "USUARIO_BLOQUEADO" -> "Acesso bloqueado";
                case "USUARIO_EXCLUIDO" -> "Usuário excluído";
                case "REUSO_TOKEN" -> "Segurança (token reutilizado)";
                case "RESTAURACAO_BACKUP" -> "Restauração de backup";
                default -> "Inválida";
            };
        }
    }

    /** Visitantes agrupados por usuário: frequência, último acesso e situação. */
    public record VisitanteUsuario(Long usuarioId, String nome, String email, Perfil perfil, boolean ativo,
                                   boolean bloqueado, Instant bloqueadoAte, String motivoBloqueio, boolean online,
                                   int sessoesAbertas, long totalAcessos, long acessosHoje, long acessos7Dias,
                                   Instant ultimoAcesso, String ultimoIp, String ultimoDispositivo) {
    }

    public record Dia(LocalDate dia, long acessos, long visitantes) {
    }

    public record Contagem(String nome, long total) {
    }

    public record Resumo(int dias, long onlineAgora, long usuariosOnline, long sessoesAbertas, long acessosHoje,
                         long visitantesHoje, long visitantes7Dias, long acessosPeriodo, long visitantesPeriodo,
                         long falhasLoginHoje, long usuariosBloqueados, double duracaoMediaMinutos, List<Dia> serie,
                         List<Contagem> dispositivos, List<Contagem> encerramentos, long[] porHora) {
    }

    /** Tentativa de login recusada (auditoria). */
    public record Falha(Long id, String email, String acao, Integer statusHttp, String detalhe, String ip,
                        Instant criadoEm) {
        public static Falha of(Auditoria a) {
            return new Falha(a.getId(), a.getUsuario(), a.getAcao(), a.getStatusHttp(), a.getDetalhe(), a.getIp(),
                    a.getCriadoEm());
        }
    }

    /** Bloqueio de acesso: temporário até {@code ate} ou permanente (desativa o usuário). */
    public record BloqueioRequest(boolean permanente, Instant ate,
                                  @Size(max = 255, message = "Motivo: até 255 caracteres.") String motivo) {
    }

    public record Quantidade(int encerradas) {
    }
}
