package br.com.adailsilva.chirpstackmanager.api.domain.entity;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

/**
 * Destino Google Drive dos backups (linha única, {@code tb_backup_google_drive}).
 */
@Entity
@Table(name = "tb_backup_google_drive")
public class GoogleDriveConfig {

    public static final short ID = 1;

    @Id
    private Short id = ID;

    @Column(name = "client_id", length = 255)
    private String clientId;

    @Column(name = "client_secret_cifrado", length = 1024)
    private String clientSecretCifrado;

    @Column(name = "conta_email", length = 255)
    private String contaEmail;

    @Column(name = "conta_nome", length = 255)
    private String contaNome;

    @Column(name = "refresh_token_cifrado", length = 2048)
    private String refreshTokenCifrado;

    @Column(name = "conectado_em")
    private Instant conectadoEm;

    @Column(name = "conectado_por", length = 160)
    private String conectadoPor;

    @Column(name = "erro_conexao", length = 1000)
    private String erroConexao;

    @Column(name = "pasta_nome", nullable = false, length = 200)
    private String pastaNome = "ChirpStack Manager/Backups";

    @Column(name = "pasta_id", length = 200)
    private String pastaId;

    @Column(name = "enviar_manuais", nullable = false)
    private boolean enviarManuais;

    @Column(name = "retencao_dias", nullable = false)
    private int retencaoDias = 30;

    @Column(name = "manter_minimo", nullable = false)
    private int manterMinimo = 5;

    @Column(name = "oauth_state", length = 100)
    private String oauthState;

    @Column(name = "oauth_state_expira")
    private Instant oauthStateExpira;

    @Column(name = "oauth_state_usuario", length = 160)
    private String oauthStateUsuario;

    @Column(name = "ultimo_envio_em")
    private Instant ultimoEnvioEm;

    @Column(name = "ultimo_envio_status", length = 20)
    private String ultimoEnvioStatus;

    @Column(name = "ultimo_envio_mensagem", length = 1000)
    private String ultimoEnvioMensagem;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    @Column(name = "atualizado_por", length = 160)
    private String atualizadoPor;

    @PrePersist
    @PreUpdate
    void carimbar() {
        atualizadoEm = Instant.now();
    }

    public boolean isConectado() {
        return refreshTokenCifrado != null && !refreshTokenCifrado.isBlank();
    }

    public void limparConexao() {
        refreshTokenCifrado = null;
        contaEmail = null;
        contaNome = null;
        conectadoEm = null;
        conectadoPor = null;
        pastaId = null;
    }

    /** Cópia desligada do JPA: a conexão com o Google não volta no tempo quando o banco é restaurado. */
    public GoogleDriveConfig copia() {
        GoogleDriveConfig c = new GoogleDriveConfig();
        c.clientId = clientId; c.clientSecretCifrado = clientSecretCifrado; c.contaEmail = contaEmail;
        c.contaNome = contaNome; c.refreshTokenCifrado = refreshTokenCifrado; c.conectadoEm = conectadoEm;
        c.conectadoPor = conectadoPor; c.erroConexao = erroConexao; c.pastaNome = pastaNome; c.pastaId = pastaId;
        c.enviarManuais = enviarManuais; c.retencaoDias = retencaoDias; c.manterMinimo = manterMinimo;
        c.ultimoEnvioEm = ultimoEnvioEm; c.ultimoEnvioStatus = ultimoEnvioStatus;
        c.ultimoEnvioMensagem = ultimoEnvioMensagem; c.atualizadoPor = atualizadoPor;
        return c;
    }

    public Short getId() { return id; }
    public String getClientId() { return clientId; }
    public void setClientId(String v) { this.clientId = v; }
    public String getClientSecretCifrado() { return clientSecretCifrado; }
    public void setClientSecretCifrado(String v) { this.clientSecretCifrado = v; }
    public String getContaEmail() { return contaEmail; }
    public void setContaEmail(String v) { this.contaEmail = v; }
    public String getContaNome() { return contaNome; }
    public void setContaNome(String v) { this.contaNome = v; }
    public String getRefreshTokenCifrado() { return refreshTokenCifrado; }
    public void setRefreshTokenCifrado(String v) { this.refreshTokenCifrado = v; }
    public Instant getConectadoEm() { return conectadoEm; }
    public void setConectadoEm(Instant v) { this.conectadoEm = v; }
    public String getConectadoPor() { return conectadoPor; }
    public void setConectadoPor(String v) { this.conectadoPor = v; }
    public String getErroConexao() { return erroConexao; }
    public void setErroConexao(String v) { this.erroConexao = v != null && v.length() > 1000 ? v.substring(0, 1000) : v; }
    public String getPastaNome() { return pastaNome; }
    public void setPastaNome(String v) { this.pastaNome = v; }
    public String getPastaId() { return pastaId; }
    public void setPastaId(String v) { this.pastaId = v; }
    public boolean isEnviarManuais() { return enviarManuais; }
    public void setEnviarManuais(boolean v) { this.enviarManuais = v; }
    public int getRetencaoDias() { return retencaoDias; }
    public void setRetencaoDias(int v) { this.retencaoDias = v; }
    public int getManterMinimo() { return manterMinimo; }
    public void setManterMinimo(int v) { this.manterMinimo = v; }
    public String getOauthState() { return oauthState; }
    public void setOauthState(String v) { this.oauthState = v; }
    public Instant getOauthStateExpira() { return oauthStateExpira; }
    public void setOauthStateExpira(Instant v) { this.oauthStateExpira = v; }
    public String getOauthStateUsuario() { return oauthStateUsuario; }
    public void setOauthStateUsuario(String v) { this.oauthStateUsuario = v; }
    public Instant getUltimoEnvioEm() { return ultimoEnvioEm; }
    public void setUltimoEnvioEm(Instant v) { this.ultimoEnvioEm = v; }
    public String getUltimoEnvioStatus() { return ultimoEnvioStatus; }
    public void setUltimoEnvioStatus(String v) { this.ultimoEnvioStatus = v; }
    public String getUltimoEnvioMensagem() { return ultimoEnvioMensagem; }
    public void setUltimoEnvioMensagem(String v) {
        this.ultimoEnvioMensagem = v != null && v.length() > 1000 ? v.substring(0, 1000) : v;
    }
    public Instant getAtualizadoEm() { return atualizadoEm; }
    public String getAtualizadoPor() { return atualizadoPor; }
    public void setAtualizadoPor(String v) { this.atualizadoPor = v; }
}
