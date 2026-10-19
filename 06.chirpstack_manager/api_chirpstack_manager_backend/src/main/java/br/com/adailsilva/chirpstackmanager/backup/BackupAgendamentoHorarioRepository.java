package br.com.adailsilva.chirpstackmanager.backup;

import org.springframework.data.jpa.repository.JpaRepository;

public interface BackupAgendamentoHorarioRepository
        extends JpaRepository<BackupAgendamentoHorario, BackupAgendamentoHorario.Chave> {
}
