package br.com.adailsilva.chirpstackmanager.api.repository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.BackupJob;

public interface BackupJobRepository extends JpaRepository<BackupJob, String> {

    boolean existsByStatusIn(Collection<BackupJob.Status> status);

    List<BackupJob> findByStatusIn(Collection<BackupJob.Status> status);

    List<BackupJob> findAllByOrderByCriadoEmDesc(Pageable pageable);

    List<BackupJob> findByOrigemInOrderByCriadoEmDesc(Collection<BackupJob.Origem> origens, Pageable pageable);

    @Modifying
    @Query("delete from BackupJob j where j.criadoEm < :limite and j.status not in :ativos")
    int apagarAntesDe(@Param("limite") Instant limite, @Param("ativos") Collection<BackupJob.Status> ativos);
}
