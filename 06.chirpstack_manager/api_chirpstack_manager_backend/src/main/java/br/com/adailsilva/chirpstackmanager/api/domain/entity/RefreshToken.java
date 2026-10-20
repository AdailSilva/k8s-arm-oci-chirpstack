package br.com.adailsilva.chirpstackmanager.api.domain.entity;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Refresh token (tabela {@code tb_refresh_token}). Só o hash SHA-256 é gravado.
 */
@Entity
@Table(name = "tb_refresh_token")
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    @Column(name = "token_hash", nullable = false, length = 64, unique = true)
    private String tokenHash;

    @Column(name = "expira_em", nullable = false)
    private Instant expiraEm;

    @Column(nullable = false)
    private boolean revogado;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(length = 64)
    private String ip;

    @Column(name = "user_agent", length = 255)
    private String userAgent;

    /** Sessão a que o token pertence (a rotação mantém o mesmo valor). */
    @Column(name = "sessao_id", length = 36)
    private String sessaoId;

    protected RefreshToken() {
    }

    public RefreshToken(Long usuarioId, String sessaoId, String tokenHash, Instant expiraEm, String ip, String userAgent) {
        this.usuarioId = usuarioId;
        this.sessaoId = sessaoId;
        this.tokenHash = tokenHash;
        this.expiraEm = expiraEm;
        this.criadoEm = Instant.now();
        this.ip = ip;
        this.userAgent = userAgent != null && userAgent.length() > 255 ? userAgent.substring(0, 255) : userAgent;
    }

    public boolean isValido() {
        return !revogado && expiraEm.isAfter(Instant.now());
    }

    public Long getId() { return id; }
    public Long getUsuarioId() { return usuarioId; }
    public String getSessaoId() { return sessaoId; }
    public String getTokenHash() { return tokenHash; }
    public Instant getExpiraEm() { return expiraEm; }
    public boolean isRevogado() { return revogado; }
    public void setRevogado(boolean revogado) { this.revogado = revogado; }
}
