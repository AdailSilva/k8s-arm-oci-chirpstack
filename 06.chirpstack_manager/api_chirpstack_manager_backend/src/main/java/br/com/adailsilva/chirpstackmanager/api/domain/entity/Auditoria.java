package br.com.adailsilva.chirpstackmanager.api.domain.entity;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Registro de auditoria (tabela {@code tb_auditoria}).
 */
@Entity
@Table(name = "tb_auditoria")
public class Auditoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 160)
    private String usuario;

    @Column(nullable = false, length = 40)
    private String acao;

    @Column(nullable = false, length = 255)
    private String recurso;

    @Column(length = 10)
    private String metodo;

    @Column(name = "status_http")
    private Integer statusHttp;

    @Column(nullable = false)
    private boolean sucesso;

    @Column(length = 500)
    private String detalhe;

    @Column(length = 64)
    private String ip;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    protected Auditoria() {
    }

    public Auditoria(String usuario, String acao, String recurso, String metodo, Integer statusHttp,
                     boolean sucesso, String detalhe, String ip) {
        this.usuario = cortar(usuario, 160);
        this.acao = cortar(acao, 40);
        this.recurso = cortar(recurso, 255);
        this.metodo = cortar(metodo, 10);
        this.statusHttp = statusHttp;
        this.sucesso = sucesso;
        this.detalhe = cortar(detalhe, 500);
        this.ip = cortar(ip, 64);
        this.criadoEm = Instant.now();
    }

    private static String cortar(String v, int max) {
        return v != null && v.length() > max ? v.substring(0, max) : v;
    }

    public Long getId() { return id; }
    public String getUsuario() { return usuario; }
    public String getAcao() { return acao; }
    public String getRecurso() { return recurso; }
    public String getMetodo() { return metodo; }
    public Integer getStatusHttp() { return statusHttp; }
    public boolean isSucesso() { return sucesso; }
    public String getDetalhe() { return detalhe; }
    public String getIp() { return ip; }
    public Instant getCriadoEm() { return criadoEm; }
}
