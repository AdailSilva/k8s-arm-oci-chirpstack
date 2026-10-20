package br.com.adailsilva.chirpstackmanager.api.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Usuario;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.Perfil;

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
