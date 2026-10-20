package br.com.adailsilva.chirpstackmanager.api.service;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import br.com.adailsilva.chirpstackmanager.api.repository.AuditoriaRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.MotivoEncerramento;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Sessao;
import br.com.adailsilva.chirpstackmanager.api.repository.SessaoRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Usuario;
import br.com.adailsilva.chirpstackmanager.api.repository.UsuarioRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.VisitanteDtos.Contagem;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.VisitanteDtos.Dia;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.VisitanteDtos.Falha;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.VisitanteDtos.Resumo;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.VisitanteDtos.SessaoResponse;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.VisitanteDtos.VisitanteUsuario;
import br.com.adailsilva.chirpstackmanager.api.exception.BusinessException;
import jakarta.persistence.criteria.Predicate;

/**
 * Visitantes: quantos acessaram, quem, de onde, quem está on-line agora e as tentativas recusadas.
 */
@Service
public class VisitanteService {

    static final List<String> ACOES_FALHA = List.of("LOGIN_FALHA", "LOGIN_BLOQUEADO_IP");

    private final SessaoRepository sessoes;
    private final UsuarioRepository usuarios;
    private final AuditoriaRepository auditoria;
    private final SessaoService sessaoService;
    private final ZoneId zona;

    public VisitanteService(SessaoRepository sessoes, UsuarioRepository usuarios, AuditoriaRepository auditoria,
                            SessaoService sessaoService, @Value("${app.fuso-horario:America/Fortaleza}") String fuso) {
        this.sessoes = sessoes;
        this.usuarios = usuarios;
        this.auditoria = auditoria;
        this.sessaoService = sessaoService;
        this.zona = ZoneId.of(fuso);
    }

    @Transactional(readOnly = true)
    public Resumo resumo(int diasPedidos) {
        int dias = Math.min(Math.max(diasPedidos, 7), 90);
        Instant agora = Instant.now();
        LocalDate hoje = LocalDate.now(zona);
        Instant inicioHoje = hoje.atStartOfDay(zona).toInstant();
        Instant inicio7 = hoje.minusDays(6).atStartOfDay(zona).toInstant();
        Instant inicioPeriodo = hoje.minusDays(dias - 1L).atStartOfDay(zona).toInstant();

        // dias >= 7, então o período sempre cobre a semana usada nos indicadores.
        List<Sessao> periodo = sessoes.findByIniciadaEmGreaterThanEqual(inicioPeriodo);
        List<Sessao> abertas = sessoes.findByEncerradaEmIsNull();
        List<Sessao> online = abertas.stream()
                .filter(s -> s.getUltimoSinal().isAfter(agora.minus(SessaoService.JANELA_ONLINE))).toList();

        Map<LocalDate, List<Sessao>> porDia = new HashMap<>();
        long[] porHora = new long[24];
        Map<String, Long> dispositivos = new HashMap<>();
        Map<String, Long> encerramentos = new LinkedHashMap<>();
        long somaDuracao = 0;
        long encerradasComDuracao = 0;
        Set<String> visitantesPeriodo = new HashSet<>();
        long acessosPeriodo = 0;
        for (Sessao s : periodo) {
            acessosPeriodo++;
            visitantesPeriodo.add(s.getUsuarioEmail());
            ZonedDateTime z = s.getIniciadaEm().atZone(zona);
            porDia.computeIfAbsent(z.toLocalDate(), d -> new ArrayList<>()).add(s);
            porHora[z.getHour()]++;
            dispositivos.merge(rotuloDispositivo(s.getDispositivo()), 1L, Long::sum);
            if (s.getMotivoEncerramento() != null) {
                encerramentos.merge(SessaoResponse.descricao(s.getMotivoEncerramento().name()), 1L, Long::sum);
                somaDuracao += Duration.between(s.getIniciadaEm(), s.getEncerradaEm()).toSeconds();
                encerradasComDuracao++;
            }
        }
        List<Dia> serie = new ArrayList<>();
        for (int i = dias - 1; i >= 0; i--) {
            LocalDate d = hoje.minusDays(i);
            List<Sessao> doDia = porDia.getOrDefault(d, List.of());
            serie.add(new Dia(d, doDia.size(), doDia.stream().map(Sessao::getUsuarioEmail).distinct().count()));
        }
        long acessosHoje = periodo.stream().filter(s -> !s.getIniciadaEm().isBefore(inicioHoje)).count();
        long visitantesHoje = periodo.stream().filter(s -> !s.getIniciadaEm().isBefore(inicioHoje))
                .map(Sessao::getUsuarioEmail).distinct().count();
        long visitantes7 = periodo.stream().filter(s -> !s.getIniciadaEm().isBefore(inicio7))
                .map(Sessao::getUsuarioEmail).distinct().count();
        long bloqueados = usuarios.findAll().stream().filter(u -> u.isBloqueado() || !u.isAtivo()).count();

        return new Resumo(dias, online.size(), online.stream().map(Sessao::getUsuarioId).distinct().count(),
                abertas.size(), acessosHoje, visitantesHoje, visitantes7, acessosPeriodo, visitantesPeriodo.size(),
                auditoria.countByAcaoInAndCriadoEmGreaterThanEqual(ACOES_FALHA, inicioHoje), bloqueados,
                encerradasComDuracao == 0 ? 0 : Math.round(somaDuracao / 60.0 / encerradasComDuracao * 10) / 10.0,
                serie, top(dispositivos, 8), top(encerramentos, 12), porHora);
    }

    /** Sessões abertas (on-line primeiro). */
    @Transactional(readOnly = true)
    public List<SessaoResponse> sessoesAbertas(String sessaoAtual) {
        return sessoes.findByEncerradaEmIsNullOrderByUltimoSinalDesc().stream()
                .map(s -> SessaoResponse.of(s, sessaoAtual))
                .sorted(Comparator.comparing(SessaoResponse::online).reversed()
                        .thenComparing(SessaoResponse::ultimoSinal, Comparator.reverseOrder()))
                .toList();
    }

    /** Todos os usuários do painel com a frequência de acesso de cada um. */
    @Transactional(readOnly = true)
    public List<VisitanteUsuario> porUsuario() {
        LocalDate hoje = LocalDate.now(zona);
        Instant inicioHoje = hoje.atStartOfDay(zona).toInstant();
        Instant inicio7 = hoje.minusDays(6).atStartOfDay(zona).toInstant();
        Instant agora = Instant.now();

        Map<Long, Object[]> estat = new HashMap<>();
        for (Object[] linha : sessoes.estatisticasPorUsuario(inicioHoje, inicio7)) {
            estat.put((Long) linha[0], linha);
        }
        Map<Long, List<Sessao>> abertas = sessoes.findByEncerradaEmIsNull().stream()
                .filter(s -> s.getUsuarioId() != null)
                .collect(Collectors.groupingBy(Sessao::getUsuarioId));

        List<VisitanteUsuario> lista = new ArrayList<>();
        for (Usuario u : usuarios.findAll(Sort.by("nome"))) {
            Object[] e = estat.get(u.getId());
            List<Sessao> doUsuario = abertas.getOrDefault(u.getId(), List.of());
            boolean online = doUsuario.stream()
                    .anyMatch(s -> s.getUltimoSinal().isAfter(agora.minus(SessaoService.JANELA_ONLINE)));
            Sessao ultima = e == null ? null : sessoes.findFirstByUsuarioIdOrderByIniciadaEmDesc(u.getId()).orElse(null);
            boolean bloqueado = u.isBloqueado();
            lista.add(new VisitanteUsuario(u.getId(), u.getNome(), u.getEmail(), u.getPerfil(), u.isAtivo(), bloqueado,
                    bloqueado ? u.getBloqueadoAte() : null,
                    bloqueado || !u.isAtivo() ? u.getMotivoBloqueio() : null, online, doUsuario.size(),
                    e == null ? 0 : numero(e[1]), e == null ? 0 : numero(e[2]), e == null ? 0 : numero(e[3]),
                    e == null ? null : (Instant) e[4], ultima != null ? ultima.getIp() : null,
                    ultima != null ? ultima.getDispositivo() : null));
        }
        return lista;
    }

    /** Histórico de acessos com filtros. {@code situacao}: ABERTA, ENCERRADA ou vazio. */
    @Transactional(readOnly = true)
    public Page<SessaoResponse> historico(Long usuarioId, String busca, String situacao, Instant de, Instant ate,
                                          int pagina, int tamanho, String sessaoAtual) {
        Specification<Sessao> spec = (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (usuarioId != null) {
                p.add(cb.equal(root.get("usuarioId"), usuarioId));
            }
            if (busca != null && !busca.isBlank()) {
                String termo = "%" + busca.trim().toLowerCase() + "%";
                p.add(cb.or(cb.like(cb.lower(root.<String>get("usuarioNome")), termo),
                        cb.like(cb.lower(root.<String>get("usuarioEmail")), termo),
                        cb.like(cb.lower(cb.coalesce(root.<String>get("ip"), "")), termo),
                        cb.like(cb.lower(cb.coalesce(root.<String>get("dispositivo"), "")), termo)));
            }
            if ("ABERTA".equalsIgnoreCase(situacao)) {
                p.add(cb.isNull(root.get("encerradaEm")));
            } else if ("ENCERRADA".equalsIgnoreCase(situacao)) {
                p.add(cb.isNotNull(root.get("encerradaEm")));
            }
            if (de != null) {
                p.add(cb.greaterThanOrEqualTo(root.<Instant>get("iniciadaEm"), de));
            }
            if (ate != null) {
                p.add(cb.lessThan(root.<Instant>get("iniciadaEm"), ate));
            }
            return cb.and(p.toArray(Predicate[]::new));
        };
        PageRequest page = PageRequest.of(Math.max(pagina, 0), Math.min(Math.max(tamanho, 1), 200),
                Sort.by(Sort.Direction.DESC, "iniciadaEm"));
        return sessoes.findAll(spec, page).map(s -> SessaoResponse.of(s, sessaoAtual));
    }

    @Transactional(readOnly = true)
    public List<Falha> falhasRecentes() {
        return auditoria.findTop50ByAcaoInOrderByCriadoEmDesc(ACOES_FALHA).stream().map(Falha::of).toList();
    }

    // ── Ações (ADMIN) ────────────────────────────────────────────────────────

    public void encerrarSessao(String sessaoId, String por, String sessaoAtual) {
        if (sessaoId.equals(sessaoAtual)) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Esta é a sua sessão atual. Para encerrá-la, use Sair.");
        }
        if (!sessaoService.encerrar(sessaoId, MotivoEncerramento.ENCERRADA_ADMIN, por)) {
            throw new BusinessException(HttpStatus.NOT_FOUND, "Sessão não encontrada ou já encerrada.");
        }
    }

    public int encerrarDoUsuario(Long usuarioId, String por, String sessaoAtual) {
        usuarios.findById(usuarioId)
                .orElseThrow(() -> new BusinessException(HttpStatus.NOT_FOUND, "Usuário não encontrado."));
        return sessaoService.encerrarDoUsuario(usuarioId, MotivoEncerramento.ENCERRADA_ADMIN, por, sessaoAtual);
    }

    public int encerrarTodas(String por, String sessaoAtual) {
        return sessaoService.encerrarTodas(MotivoEncerramento.ENCERRADA_ADMIN, por, sessaoAtual);
    }

    private static long numero(Object o) {
        return o instanceof Number n ? n.longValue() : 0;
    }

    /** "Chrome · Windows (computador)" → "Chrome · Windows" para agrupar no gráfico. */
    private static String rotuloDispositivo(String d) {
        if (d == null) {
            return "Desconhecido";
        }
        int i = d.indexOf(" (");
        return i > 0 ? d.substring(0, i) : d;
    }

    private static List<Contagem> top(Map<String, Long> mapa, int limite) {
        return mapa.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(limite)
                .map(e -> new Contagem(e.getKey(), e.getValue()))
                .toList();
    }
}
