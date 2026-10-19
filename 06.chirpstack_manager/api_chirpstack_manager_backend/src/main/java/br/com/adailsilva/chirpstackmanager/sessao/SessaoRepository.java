package br.com.adailsilva.chirpstackmanager.sessao;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SessaoRepository extends JpaRepository<Sessao, String>, JpaSpecificationExecutor<Sessao> {

    List<Sessao> findByEncerradaEmIsNull();

    List<Sessao> findByEncerradaEmIsNullOrderByUltimoSinalDesc();

    List<Sessao> findByUsuarioIdAndEncerradaEmIsNullOrderByIniciadaEmAsc(Long usuarioId);

    List<Sessao> findByIniciadaEmGreaterThanEqual(Instant desde);

    Optional<Sessao> findFirstByUsuarioIdOrderByIniciadaEmDesc(Long usuarioId);

    /** Por usuário: total de acessos, acessos desde {@code hoje}, desde {@code semana} e o último acesso. */
    @Query("""
            select s.usuarioId,
                   count(s),
                   sum(case when s.iniciadaEm >= :hoje then 1 else 0 end),
                   sum(case when s.iniciadaEm >= :semana then 1 else 0 end),
                   max(s.iniciadaEm)
              from Sessao s
             where s.usuarioId is not null
             group by s.usuarioId
            """)
    List<Object[]> estatisticasPorUsuario(@Param("hoje") Instant hoje, @Param("semana") Instant semana);

    @Modifying
    @Query("delete from Sessao s where s.encerradaEm is not null and s.encerradaEm < :limite")
    int apagarEncerradasAntesDe(@Param("limite") Instant limite);
}
