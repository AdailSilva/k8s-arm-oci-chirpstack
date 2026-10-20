package br.com.adailsilva.chirpstackmanager.api.domain.entity;

import java.io.Serializable;
import java.time.LocalTime;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Um horário do backup automático ({@code tb_backup_agendamento_horario}). Dia ISO: 1 = segunda ... 7 = domingo.
 */
@Entity
@Table(name = "tb_backup_agendamento_horario")
public class BackupAgendamentoHorario {

    @Embeddable
    public static class Chave implements Serializable {

        @Column(name = "dia_semana", nullable = false)
        private Short diaSemana;

        @Column(nullable = false)
        private LocalTime hora;

        protected Chave() {
        }

        public Chave(int diaSemana, LocalTime hora) {
            this.diaSemana = (short) diaSemana;
            this.hora = hora;
        }

        public int getDiaSemana() { return diaSemana; }
        public LocalTime getHora() { return hora; }

        @Override
        public boolean equals(Object o) {
            return o instanceof Chave c && Objects.equals(diaSemana, c.diaSemana) && Objects.equals(hora, c.hora);
        }

        @Override
        public int hashCode() {
            return Objects.hash(diaSemana, hora);
        }
    }

    @EmbeddedId
    private Chave chave;

    protected BackupAgendamentoHorario() {
    }

    public BackupAgendamentoHorario(int diaSemana, LocalTime hora) {
        this.chave = new Chave(diaSemana, hora);
    }

    public int getDiaSemana() { return chave.getDiaSemana(); }
    public LocalTime getHora() { return chave.getHora(); }
}
