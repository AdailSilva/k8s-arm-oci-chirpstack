package br.com.adailsilva.chirpstackmanager.sessao;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import br.com.adailsilva.chirpstackmanager.auth.RefreshTokenRepository;
import br.com.adailsilva.chirpstackmanager.sessao.SessaoDtos.PoliticaRequest;
import br.com.adailsilva.chirpstackmanager.sessao.SessaoDtos.SessaoInfo;
import br.com.adailsilva.chirpstackmanager.usuario.Usuario;

/**
 * Ciclo de vida das sessões e regras de logoff.
 *
 * <ul>
 *   <li><b>Encerramento imediato</b>: toda requisição autenticada passa por {@link #verificar(String)};
 *       sessão encerrada (pelo ADMIN, por troca de senha, bloqueio, restauração…) é recusada na hora,
 *       sem esperar o access token vencer. O resultado fica 5 s em cache para não consultar o banco a
 *       cada chamada; com várias réplicas, esse é o maior atraso possível.</li>
 *   <li><b>Inatividade</b>: o navegador informa a última interação a cada minuto
 *       ({@link #registrarAtividade}); passado o limite da política (com tolerância de 90 s para o
 *       atraso do sinal), a sessão cai com o motivo {@link MotivoEncerramento#INATIVIDADE}.</li>
 *   <li><b>Duração máxima</b>: limite absoluto desde o login, mesmo com uso contínuo.</li>
 *   <li><b>Sessões simultâneas</b>: acima do limite, a mais antiga do usuário é encerrada.</li>
 * </ul>
 */
@Service
public class SessaoService {

    private static final Logger log = LoggerFactory.getLogger(SessaoService.class);

    /** Folga para o atraso do sinal de atividade (enviado a cada 60 s pelo navegador). */
    static final Duration TOLERANCIA = Duration.ofSeconds(90);
    /** Sem sinal há mais que isso, a aba é considerada fechada (off-line). */
    public static final Duration JANELA_ONLINE = Duration.ofSeconds(150);

    private static final long CACHE_ATIVA_MS = 5_000;
    private static final long CACHE_ENCERRADA_MS = 60_000;
    private static final long CACHE_POLITICA_MS = 10_000;

    private record Situacao(MotivoEncerramento motivo, long validoAte) {
    }

    private final SessaoRepository repository;
    private final PoliticaSessaoRepository politicas;
    private final RefreshTokenRepository refreshTokens;
    private final TransactionTemplate tx;
    private final int retencaoDias;

    private final Map<String, Situacao> cache = new ConcurrentHashMap<>();
    private volatile PoliticaSessao politicaCache;
    private volatile long politicaValidaAte;

    public SessaoService(SessaoRepository repository, PoliticaSessaoRepository politicas,
                         RefreshTokenRepository refreshTokens, TransactionTemplate tx,
                         @Value("${app.sessao.retencao-historico-dias:365}") int retencaoDias) {
        this.repository = repository;
        this.politicas = politicas;
        this.refreshTokens = refreshTokens;
        this.tx = tx;
        this.retencaoDias = retencaoDias;
    }

    // ── Política ─────────────────────────────────────────────────────────────

    public PoliticaSessao politica() {
        long agora = System.currentTimeMillis();
        PoliticaSessao p = politicaCache;
        if (p == null || agora > politicaValidaAte) {
            p = politicas.findById(PoliticaSessao.ID).orElseGet(PoliticaSessao::new);
            politicaCache = p;
            politicaValidaAte = agora + CACHE_POLITICA_MS;
        }
        return p;
    }

    public PoliticaSessao salvarPolitica(PoliticaRequest req, String por, String sessaoAtual) {
        PoliticaSessao salva = tx.execute(st -> {
            PoliticaSessao p = politicas.findById(PoliticaSessao.ID).orElseGet(PoliticaSessao::new);
            p.setInatividadeMinutos(req.inatividadeMinutos());
            p.setAvisoSegundos(req.avisoSegundos());
            p.setDuracaoMaximaHoras(req.duracaoMaximaHoras());
            p.setMaxSessoesPorUsuario(req.maxSessoesPorUsuario());
            p.setManterConectado(req.manterConectado());
            p.setAtualizadoPor(por);
            return politicas.save(p);
        });
        politicaCache = null;
        if (Boolean.TRUE.equals(req.encerrarSessoesAbertas())) {
            int n = encerrarTodas(MotivoEncerramento.ENCERRADA_ADMIN, por, sessaoAtual);
            log.info("Política de sessão alterada por {}; {} sessão(ões) encerrada(s).", por, n);
        }
        return salva;
    }

    // ── Início, verificação e atividade ──────────────────────────────────────

    /** Abre a sessão de um login. Aplica o limite de sessões simultâneas. */
    public Sessao iniciar(Usuario u, String ip, String userAgent) {
        PoliticaSessao p = politica();
        return tx.execute(st -> {
            if (p.getMaxSessoesPorUsuario() > 0) {
                List<Sessao> abertas = repository.findByUsuarioIdAndEncerradaEmIsNullOrderByIniciadaEmAsc(u.getId());
                int excedente = abertas.size() - (p.getMaxSessoesPorUsuario() - 1);
                for (int i = 0; i < excedente; i++) {
                    encerrarInterno(abertas.get(i), MotivoEncerramento.LIMITE_SESSOES, "sistema");
                }
            }
            Sessao s = new Sessao(u.getId(), u.getNome(), u.getEmail(), ip, userAgent,
                    Instant.now().plus(p.duracaoMaxima()));
            return repository.save(s);
        });
    }

    /**
     * Situação da sessão para o filtro de requisições: vazio = aberta; senão, o motivo do fim.
     * Fecha na hora a sessão que passou da duração máxima ou da inatividade.
     */
    public Optional<MotivoEncerramento> verificar(String sessaoId) {
        long agora = System.currentTimeMillis();
        Situacao c = cache.get(sessaoId);
        if (c != null && c.validoAte() > agora) {
            return Optional.ofNullable(c.motivo());
        }
        MotivoEncerramento motivo = tx.execute(st -> avaliar(sessaoId));
        cache.put(sessaoId, new Situacao(motivo, agora + (motivo == null ? CACHE_ATIVA_MS : CACHE_ENCERRADA_MS)));
        return Optional.ofNullable(motivo);
    }

    /** Para o refresh: devolve a sessão aberta ou lança {@link SessaoEncerradaException}. */
    public Sessao validarParaRenovar(String sessaoId) {
        Object r = tx.execute(st -> {
            MotivoEncerramento motivo = avaliar(sessaoId);
            if (motivo != null) {
                return motivo;
            }
            Sessao s = repository.findById(sessaoId).orElseThrow();
            s.setUltimoSinal(Instant.now());
            return s;
        });
        return sessaoOuErro(sessaoId, r);
    }

    /** Sinal do navegador: a aba está aberta e, se {@code ativo}, houve interação do usuário. */
    public SessaoInfo registrarAtividade(String sessaoId, boolean ativo) {
        PoliticaSessao p = politica();
        Object r = tx.execute(st -> {
            MotivoEncerramento motivo = avaliar(sessaoId);
            if (motivo != null) {
                return motivo;
            }
            Sessao s = repository.findById(sessaoId).orElseThrow();
            Instant agora = Instant.now();
            s.setUltimoSinal(agora);
            if (ativo) {
                s.setUltimaAtividade(agora);
            }
            return s;
        });
        return SessaoInfo.of(sessaoOuErro(sessaoId, r), p);
    }

    /**
     * O encerramento por tempo precisa ser gravado ANTES da exceção: lançada dentro da transação,
     * ela desfaria justamente o registro do motivo.
     */
    private Sessao sessaoOuErro(String sessaoId, Object resultado) {
        if (resultado instanceof MotivoEncerramento motivo) {
            cache.put(sessaoId, new Situacao(motivo, System.currentTimeMillis() + CACHE_ENCERRADA_MS));
            throw new SessaoEncerradaException(motivo);
        }
        return (Sessao) resultado;
    }

    public Optional<Sessao> buscar(String sessaoId) {
        return sessaoId == null ? Optional.empty() : repository.findById(sessaoId);
    }

    public SessaoInfo info(Sessao s) {
        return SessaoInfo.of(s, politica());
    }

    /** Executa dentro de uma transação. Devolve o motivo do fim, ou {@code null} se a sessão continua aberta. */
    private MotivoEncerramento avaliar(String sessaoId) {
        Sessao s = repository.findById(sessaoId).orElse(null);
        if (s == null) {
            return MotivoEncerramento.INVALIDA;
        }
        if (!s.isAberta()) {
            return Objects.requireNonNullElse(s.getMotivoEncerramento(), MotivoEncerramento.INVALIDA);
        }
        MotivoEncerramento motivo = motivoPorTempo(s, Instant.now());
        if (motivo != null) {
            encerrarInterno(s, motivo, "sistema");
        }
        return motivo;
    }

    private MotivoEncerramento motivoPorTempo(Sessao s, Instant agora) {
        if (s.getExpiraEm().isBefore(agora)) {
            return MotivoEncerramento.EXPIRADA;
        }
        Duration inatividade = politica().inatividade();
        if (inatividade != null && s.getUltimaAtividade().plus(inatividade).plus(TOLERANCIA).isBefore(agora)) {
            return MotivoEncerramento.INATIVIDADE;
        }
        return null;
    }

    // ── Encerramento ─────────────────────────────────────────────────────────

    /** Encerra uma sessão. Devolve {@code false} se ela já estava encerrada. */
    public boolean encerrar(String sessaoId, MotivoEncerramento motivo, String por) {
        Boolean ok = tx.execute(st -> repository.findById(sessaoId)
                .filter(Sessao::isAberta)
                .map(s -> {
                    encerrarInterno(s, motivo, por);
                    return true;
                })
                .orElse(false));
        return Boolean.TRUE.equals(ok);
    }

    /** Encerra as sessões abertas do usuário, exceto {@code excetoSessao}. Devolve quantas. */
    public int encerrarDoUsuario(Long usuarioId, MotivoEncerramento motivo, String por, String excetoSessao) {
        Integer n = tx.execute(st -> {
            int total = 0;
            for (Sessao s : repository.findByUsuarioIdAndEncerradaEmIsNullOrderByIniciadaEmAsc(usuarioId)) {
                if (!s.getId().equals(excetoSessao)) {
                    encerrarInterno(s, motivo, por);
                    total++;
                }
            }
            // Tokens antigos, emitidos antes das sessões existirem, também caem.
            if (excetoSessao == null) {
                refreshTokens.revogarTodos(usuarioId);
            }
            return total;
        });
        return n == null ? 0 : n;
    }

    /** Encerra todas as sessões abertas, exceto {@code excetoSessao}. Devolve quantas. */
    public int encerrarTodas(MotivoEncerramento motivo, String por, String excetoSessao) {
        Integer n = tx.execute(st -> {
            int total = 0;
            for (Sessao s : repository.findByEncerradaEmIsNull()) {
                if (!s.getId().equals(excetoSessao)) {
                    encerrarInterno(s, motivo, por);
                    total++;
                }
            }
            return total;
        });
        return n == null ? 0 : n;
    }

    /** Depois de restaurar o banco, nenhuma sessão anterior vale: o cache inteiro é descartado. */
    public void descartarCache() {
        cache.clear();
        politicaCache = null;
    }

    private void encerrarInterno(Sessao s, MotivoEncerramento motivo, String por) {
        s.encerrar(motivo, por);
        refreshTokens.revogarDaSessao(s.getId());
        cache.put(s.getId(), new Situacao(motivo, System.currentTimeMillis() + CACHE_ENCERRADA_MS));
    }

    // ── Manutenção ───────────────────────────────────────────────────────────

    /** A cada minuto: fecha sessões vencidas ou ociosas, para o monitor mostrar a situação real. */
    @Scheduled(fixedDelay = 60_000, initialDelay = 30_000)
    public void varrer() {
        try {
            tx.executeWithoutResult(st -> {
                Instant agora = Instant.now();
                for (Sessao s : repository.findByEncerradaEmIsNull()) {
                    MotivoEncerramento motivo = motivoPorTempo(s, agora);
                    if (motivo != null) {
                        encerrarInterno(s, motivo, "sistema");
                    }
                }
            });
            long agora = System.currentTimeMillis();
            cache.entrySet().removeIf(e -> e.getValue().validoAte() < agora);
        } catch (RuntimeException e) {
            log.warn("Falha ao varrer sessões: {}", e.getMessage());
        }
    }

    /** Diariamente: apaga o histórico de sessões encerradas há mais tempo que a retenção. */
    @Scheduled(cron = "0 40 3 * * *")
    public void limparHistorico() {
        if (retencaoDias <= 0) {
            return;
        }
        Integer n = tx.execute(st -> repository.apagarEncerradasAntesDe(Instant.now().minus(retencaoDias, ChronoUnit.DAYS)));
        if (n != null && n > 0) {
            log.info("Histórico de sessões: {} registro(s) com mais de {} dias removido(s).", n, retencaoDias);
        }
    }
}
