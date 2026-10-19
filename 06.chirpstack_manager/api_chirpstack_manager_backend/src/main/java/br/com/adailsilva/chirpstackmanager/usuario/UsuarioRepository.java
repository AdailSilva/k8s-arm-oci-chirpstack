package br.com.adailsilva.chirpstackmanager.usuario;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    long countByPerfilAndAtivoTrue(Perfil perfil);

    @Query("""
            select u from Usuario u
            where lower(u.nome) like lower(concat('%', :busca, '%'))
               or lower(u.email) like lower(concat('%', :busca, '%'))
            """)
    Page<Usuario> buscar(@Param("busca") String busca, Pageable pageable);
}
