package br.com.adailsilva.chirpstackmanager.backup;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

/**
 * Configuração do backup automático (linha única, {@code tb_backup_agendamento}).
 */
@Entity
@Table(name = "tb_backup_agendamento")
public class BackupAgendamento {

    public static final short ID = 1;

    @Id
    private Short id = ID;

    @Column(nullable = false)
    private boolean ativo;

    @Column(nullable = false, length = 30)
    private String formatos = "backup";

    @Column(name = "destino_servidor", nullable = false)
    private boolean destinoServidor = true;

    @Column(name = "destino_drive", nullable = false)
    private boolean destinoDrive;

    @Column(name = "retencao_dias", nullable = false)
    private int retencaoDias = 30;

    @Column(name = "manter_minimo", nullable = false)
    private int manterMinimo = 3;

    /** Horário local já disparado (trava de execução única entre réplicas). */
    @Column(name = "ultimo_disparo")
    private LocalDateTime ultimoDisparo;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    @Column(name = "atualizado_por", length = 160)
    private String atualizadoPor;

    @PrePersist
    @PreUpdate
    void carimbar() {
        atualizadoEm = Instant.now();
    }

    public List<String> listaFormatos() {
        return Arrays.stream(formatos.split(",")).map(String::trim).filter(f -> !f.isEmpty()).toList();
    }

    public Short getId() { return id; }
    public boolean isAtivo() { return ativo; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
    public String getFormatos() { return formatos; }
    public void setFormatos(String formatos) { this.formatos = formatos; }
    public boolean isDestinoServidor() { return destinoServidor; }
    public void setDestinoServidor(boolean v) { this.destinoServidor = v; }
    public boolean isDestinoDrive() { return destinoDrive; }
    public void setDestinoDrive(boolean v) { this.destinoDrive = v; }
    public int getRetencaoDias() { return retencaoDias; }
    public void setRetencaoDias(int v) { this.retencaoDias = v; }
    public int getManterMinimo() { return manterMinimo; }
    public void setManterMinimo(int v) { this.manterMinimo = v; }
    public LocalDateTime getUltimoDisparo() { return ultimoDisparo; }
    public Instant getAtualizadoEm() { return atualizadoEm; }
    public String getAtualizadoPor() { return atualizadoPor; }
    public void setAtualizadoPor(String v) { this.atualizadoPor = v; }
}
