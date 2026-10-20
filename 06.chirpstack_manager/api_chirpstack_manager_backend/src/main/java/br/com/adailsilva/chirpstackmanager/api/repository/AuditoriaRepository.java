package br.com.adailsilva.chirpstackmanager.api.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Auditoria;

public interface AuditoriaRepository extends JpaRepository<Auditoria, Long> {

    @Query("""
            select a from Auditoria a
            where (lower(coalesce(a.usuario, '')) like lower(concat('%', :busca, '%'))
                   or lower(a.recurso) like lower(concat('%', :busca, '%'))
                   or lower(a.acao) like lower(concat('%', :busca, '%')))
              and (:acao = '' or a.acao = :acao)
            """)
    Page<Auditoria> buscar(@Param("busca") String busca, @Param("acao") String acao, Pageable pageable);

    long countByAcaoInAndCriadoEmGreaterThanEqual(java.util.Collection<String> acoes, java.time.Instant desde);

    java.util.List<Auditoria> findTop50ByAcaoInOrderByCriadoEmDesc(java.util.Collection<String> acoes);
}
