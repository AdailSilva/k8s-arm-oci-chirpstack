package br.com.adailsilva.chirpstackmanager.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.GoogleDriveConfig;

public interface GoogleDriveConfigRepository extends JpaRepository<GoogleDriveConfig, Short> {
}
