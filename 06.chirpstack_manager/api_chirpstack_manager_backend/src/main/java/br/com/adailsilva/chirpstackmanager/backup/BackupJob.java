package br.com.adailsilva.chirpstackmanager.backup;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Execução de backup ou restauração ({@code tb_backup_job}).
 */
@Entity
@Table(name = "tb_backup_job")
public class BackupJob {

    public enum Tipo { BACKUP, RESTORE }

    public enum Origem { MANUAL, AGENDADO, EXECUTAR_AGORA }

    public enum Status { PENDENTE, EXECUTANDO, SUCESSO, PARCIAL, ERRO, IGNORADO }

    @Id
    @Column(length = 36)
    private String id;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, length = 10)
    private Tipo tipo;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, length = 20)
    private Origem origem;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, length = 20)
    private Status status;

    @Column(nullable = false)
    private int progresso;

    @Column(length = 500)
    private String mensagem;

    @Column(length = 2000)
    private String erro;

    @Column(length = 30)
    private String formatos;

    @Column(length = 2000)
    private String arquivos;

    @Column(name = "tamanho_bytes")
    private Long tamanhoBytes;

    @Column(name = "enviar_drive", nullable = false)
    private boolean enviarDrive;

    @Column(name = "drive_status", length = 20)
    private String driveStatus;

    @Column(name = "drive_mensagem", length = 1000)
    private String driveMensagem;

    @Column(nullable = false)
    private int removidos;

    @Column(name = "solicitado_por", length = 160)
    private String solicitadoPor;

    @Column(length = 120)
    private String instancia;

    @Column(name = "agendado_para")
    private Instant agendadoPara;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(name = "iniciado_em")
    private Instant iniciadoEm;

    @Column(name = "finalizado_em")
    private Instant finalizadoEm;

    protected BackupJob() {
    }

    public BackupJob(Tipo tipo, Origem origem, String solicitadoPor, String instancia) {
        this.id = UUID.randomUUID().toString();
        this.tipo = tipo;
        this.origem = origem;
        this.status = Status.PENDENTE;
        this.solicitadoPor = solicitadoPor;
        this.instancia = instancia;
        this.criadoEm = Instant.now();
        this.mensagem = "Aguardando início";
    }

    /** Cópia desligada do contexto JPA (para regravar o job depois de uma restauração). */
    public BackupJob copia() {
        BackupJob c = new BackupJob();
        c.id = id; c.tipo = tipo; c.origem = origem; c.status = status; c.progresso = progresso;
        c.mensagem = mensagem; c.erro = erro; c.formatos = formatos; c.arquivos = arquivos;
        c.tamanhoBytes = tamanhoBytes; c.enviarDrive = enviarDrive; c.driveStatus = driveStatus;
        c.driveMensagem = driveMensagem; c.removidos = removidos; c.solicitadoPor = solicitadoPor;
        c.instancia = instancia; c.agendadoPara = agendadoPara; c.criadoEm = criadoEm;
        c.iniciadoEm = iniciadoEm; c.finalizadoEm = finalizadoEm;
        return c;
    }

    public boolean isEmAndamento() {
        return status == Status.PENDENTE || status == Status.EXECUTANDO;
    }

    public List<String> listaArquivos() {
        return arquivos == null || arquivos.isBlank() ? List.of() : Arrays.asList(arquivos.split("\n"));
    }

    public String getId() { return id; }
    public Tipo getTipo() { return tipo; }
    public Origem getOrigem() { return origem; }
    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }
    public int getProgresso() { return progresso; }
    public void setProgresso(int progresso) { this.progresso = Math.max(0, Math.min(100, progresso)); }
    public String getMensagem() { return mensagem; }
    public void setMensagem(String m) { this.mensagem = corta(m, 500); }
    public String getErro() { return erro; }
    public void setErro(String e) { this.erro = corta(e, 2000); }
    public String getFormatos() { return formatos; }
    public void setFormatos(String formatos) { this.formatos = formatos; }
    public String getArquivos() { return arquivos; }
    public void setArquivos(List<String> lista) { this.arquivos = corta(String.join("\n", lista), 2000); }
    public Long getTamanhoBytes() { return tamanhoBytes; }
    public void setTamanhoBytes(Long tamanhoBytes) { this.tamanhoBytes = tamanhoBytes; }
    public boolean isEnviarDrive() { return enviarDrive; }
    public void setEnviarDrive(boolean enviarDrive) { this.enviarDrive = enviarDrive; }
    public String getDriveStatus() { return driveStatus; }
    public void setDriveStatus(String driveStatus) { this.driveStatus = driveStatus; }
    public String getDriveMensagem() { return driveMensagem; }
    public void setDriveMensagem(String m) { this.driveMensagem = corta(m, 1000); }
    public int getRemovidos() { return removidos; }
    public void setRemovidos(int removidos) { this.removidos = removidos; }
    public String getSolicitadoPor() { return solicitadoPor; }
    public String getInstancia() { return instancia; }
    public Instant getAgendadoPara() { return agendadoPara; }
    public void setAgendadoPara(Instant agendadoPara) { this.agendadoPara = agendadoPara; }
    public Instant getCriadoEm() { return criadoEm; }
    public Instant getIniciadoEm() { return iniciadoEm; }
    public void setIniciadoEm(Instant iniciadoEm) { this.iniciadoEm = iniciadoEm; }
    public Instant getFinalizadoEm() { return finalizadoEm; }
    public void setFinalizadoEm(Instant finalizadoEm) { this.finalizadoEm = finalizadoEm; }

    private static String corta(String s, int max) {
        return s != null && s.length() > max ? s.substring(0, max) : s;
    }
}
