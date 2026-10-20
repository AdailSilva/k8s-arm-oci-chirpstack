package br.com.adailsilva.chirpstackmanager.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.BackupAgendamentoHorario;

public interface BackupAgendamentoHorarioRepository
        extends JpaRepository<BackupAgendamentoHorario, BackupAgendamentoHorario.Chave> {
}
