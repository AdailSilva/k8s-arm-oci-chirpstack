package br.com.adailsilva.chirpstackmanager.api.repository;

import java.time.LocalDateTime;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.BackupAgendamento;

public interface BackupAgendamentoRepository extends JpaRepository<BackupAgendamento, Short> {

    /**
     * Reivindica o horário: só uma réplica consegue avançar {@code ultimoDisparo} para {@code horario}.
     * Devolve 1 para quem ganhou e 0 para as demais.
     */
    @Modifying
    @Query("""
            update BackupAgendamento a set a.ultimoDisparo = :horario
             where a.id = 1 and (a.ultimoDisparo is null or a.ultimoDisparo < :horario)
            """)
    int reivindicar(@Param("horario") LocalDateTime horario);
}
