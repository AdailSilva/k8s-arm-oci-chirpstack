package br.com.adailsilva.chirpstackmanager.sessao;

import java.time.Duration;
import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

/**
 * Política de sessão (linha única, {@code tb_politica_sessao}).
 */
@Entity
@Table(name = "tb_politica_sessao")
public class PoliticaSessao {

    public static final short ID = 1;

    @Id
    private Short id = ID;

    @Column(name = "inatividade_minutos", nullable = false)
    private int inatividadeMinutos = 30;

    @Column(name = "aviso_segundos", nullable = false)
    private int avisoSegundos = 120;

    @Column(name = "duracao_maxima_horas", nullable = false)
    private int duracaoMaximaHoras = 12;

    @Column(name = "max_sessoes_por_usuario", nullable = false)
    private int maxSessoesPorUsuario;

    @Column(name = "manter_conectado", nullable = false)
    private boolean manterConectado = true;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    @Column(name = "atualizado_por", length = 160)
    private String atualizadoPor;

    @PrePersist
    @PreUpdate
    void carimbar() {
        atualizadoEm = Instant.now();
    }

    /** Inatividade tolerada; {@code null} quando o controle está desligado. */
    public Duration inatividade() {
        return inatividadeMinutos <= 0 ? null : Duration.ofMinutes(inatividadeMinutos);
    }

    public Duration duracaoMaxima() {
        return Duration.ofHours(Math.max(duracaoMaximaHoras, 1));
    }

    public Short getId() { return id; }
    public int getInatividadeMinutos() { return inatividadeMinutos; }
    public void setInatividadeMinutos(int v) { this.inatividadeMinutos = v; }
    public int getAvisoSegundos() { return avisoSegundos; }
    public void setAvisoSegundos(int v) { this.avisoSegundos = v; }
    public int getDuracaoMaximaHoras() { return duracaoMaximaHoras; }
    public void setDuracaoMaximaHoras(int v) { this.duracaoMaximaHoras = v; }
    public int getMaxSessoesPorUsuario() { return maxSessoesPorUsuario; }
    public void setMaxSessoesPorUsuario(int v) { this.maxSessoesPorUsuario = v; }
    public boolean isManterConectado() { return manterConectado; }
    public void setManterConectado(boolean v) { this.manterConectado = v; }
    public Instant getAtualizadoEm() { return atualizadoEm; }
    public String getAtualizadoPor() { return atualizadoPor; }
    public void setAtualizadoPor(String v) { this.atualizadoPor = v; }
}
