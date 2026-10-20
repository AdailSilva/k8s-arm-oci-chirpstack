package br.com.adailsilva.chirpstackmanager.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.PoliticaSessao;

public interface PoliticaSessaoRepository extends JpaRepository<PoliticaSessao, Short> {
}
