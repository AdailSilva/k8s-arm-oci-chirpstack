package br.com.adailsilva.chirpstackmanager.api.domain.entity;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.MotivoEncerramento;
import br.com.adailsilva.chirpstackmanager.api.web.Dispositivo;

/**
 * Sessão de um login (tabela {@code tb_sessao}). Serve de registro de visitantes e de sessão viva:
 * o access token carrega o id no claim {@code sid}.
 */
@Entity
@Table(name = "tb_sessao")
public class Sessao {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "usuario_id")
    private Long usuarioId;

    @Column(name = "usuario_nome", nullable = false, length = 120)
    private String usuarioNome;

    @Column(name = "usuario_email", nullable = false, length = 160)
    private String usuarioEmail;

    @Column(length = 64)
    private String ip;

    @Column(name = "user_agent", length = 255)
    private String userAgent;

    @Column(length = 120)
    private String dispositivo;

    @Column(name = "iniciada_em", nullable = false)
    private Instant iniciadaEm;

    @Column(name = "ultima_atividade", nullable = false)
    private Instant ultimaAtividade;

    @Column(name = "ultimo_sinal", nullable = false)
    private Instant ultimoSinal;

    @Column(name = "expira_em", nullable = false)
    private Instant expiraEm;

    @Column(name = "encerrada_em")
    private Instant encerradaEm;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "motivo_encerramento", length = 30)
    private MotivoEncerramento motivoEncerramento;

    @Column(name = "encerrada_por", length = 160)
    private String encerradaPor;

    protected Sessao() {
    }

    public Sessao(Long usuarioId, String nome, String email, String ip, String userAgent, Instant expiraEm) {
        Instant agora = Instant.now();
        this.id = UUID.randomUUID().toString();
        this.usuarioId = usuarioId;
        this.usuarioNome = nome;
        this.usuarioEmail = email;
        this.ip = ip;
        this.userAgent = userAgent != null && userAgent.length() > 255 ? userAgent.substring(0, 255) : userAgent;
        this.dispositivo = Dispositivo.descrever(userAgent);
        this.iniciadaEm = agora;
        this.ultimaAtividade = agora;
        this.ultimoSinal = agora;
        this.expiraEm = expiraEm;
    }

    public boolean isAberta() {
        return encerradaEm == null;
    }

    public void encerrar(MotivoEncerramento motivo, String por) {
        if (encerradaEm == null) {
            encerradaEm = Instant.now();
            motivoEncerramento = motivo;
            encerradaPor = por;
        }
    }

    public String getId() { return id; }
    public Long getUsuarioId() { return usuarioId; }
    public String getUsuarioNome() { return usuarioNome; }
    public String getUsuarioEmail() { return usuarioEmail; }
    public String getIp() { return ip; }
    public String getUserAgent() { return userAgent; }
    public String getDispositivo() { return dispositivo; }
    public Instant getIniciadaEm() { return iniciadaEm; }
    public Instant getUltimaAtividade() { return ultimaAtividade; }
    public void setUltimaAtividade(Instant ultimaAtividade) { this.ultimaAtividade = ultimaAtividade; }
    public Instant getUltimoSinal() { return ultimoSinal; }
    public void setUltimoSinal(Instant ultimoSinal) { this.ultimoSinal = ultimoSinal; }
    public Instant getExpiraEm() { return expiraEm; }
    public Instant getEncerradaEm() { return encerradaEm; }
    public MotivoEncerramento getMotivoEncerramento() { return motivoEncerramento; }
    public String getEncerradaPor() { return encerradaPor; }
}
