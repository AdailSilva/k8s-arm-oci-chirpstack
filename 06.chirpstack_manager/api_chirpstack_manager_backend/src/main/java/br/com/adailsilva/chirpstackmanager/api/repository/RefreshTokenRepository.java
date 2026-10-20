package br.com.adailsilva.chirpstackmanager.api.repository;

import java.time.Instant;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.RefreshToken;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Transactional
    @Modifying
    @Query("update RefreshToken r set r.revogado = true where r.usuarioId = :usuarioId and r.revogado = false")
    int revogarTodos(@Param("usuarioId") Long usuarioId);

    @Transactional
    @Modifying
    @Query("update RefreshToken r set r.revogado = true where r.sessaoId = :sessaoId and r.revogado = false")
    int revogarDaSessao(@Param("sessaoId") String sessaoId);

    @Transactional
    @Modifying
    @Query("delete from RefreshToken r where r.expiraEm < :limite")
    int apagarExpirados(@Param("limite") Instant limite);
}
