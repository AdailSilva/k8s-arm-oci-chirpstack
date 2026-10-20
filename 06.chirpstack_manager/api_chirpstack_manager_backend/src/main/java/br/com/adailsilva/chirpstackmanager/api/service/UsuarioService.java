package br.com.adailsilva.chirpstackmanager.api.service;

import java.time.Instant;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import br.com.adailsilva.chirpstackmanager.api.repository.RefreshTokenRepository;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.MotivoEncerramento;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.UsuarioDtos.UsuarioCreateRequest;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.UsuarioDtos.UsuarioUpdateRequest;
import br.com.adailsilva.chirpstackmanager.api.exception.BusinessException;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Usuario;
import br.com.adailsilva.chirpstackmanager.api.domain.enums.Perfil;
import br.com.adailsilva.chirpstackmanager.api.repository.UsuarioRepository;

/**
 * Regras dos usuários do painel.
 */
@Service
public class UsuarioService {

    private final UsuarioRepository repository;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder encoder;
    private final SessaoService sessoes;

    public UsuarioService(UsuarioRepository repository, RefreshTokenRepository refreshTokens, PasswordEncoder encoder,
                          SessaoService sessoes) {
        this.repository = repository;
        this.refreshTokens = refreshTokens;
        this.encoder = encoder;
        this.sessoes = sessoes;
    }

    @Transactional(readOnly = true)
    public Page<Usuario> listar(String busca, int pagina, int tamanho) {
        int size = Math.min(Math.max(tamanho, 1), 200);
        return repository.buscar(busca == null ? "" : busca.trim(),
                PageRequest.of(Math.max(pagina, 0), size, Sort.by("nome")));
    }

    @Transactional(readOnly = true)
    public Usuario buscar(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new BusinessException(HttpStatus.NOT_FOUND, "Usuário não encontrado."));
    }

    @Transactional
    public Usuario criar(UsuarioCreateRequest req) {
        String email = req.email().trim().toLowerCase();
        if (repository.existsByEmailIgnoreCase(email)) {
            throw new BusinessException(HttpStatus.CONFLICT, "Já existe um usuário com este e-mail.");
        }
        Usuario u = new Usuario();
        u.setNome(req.nome().trim());
        u.setEmail(email);
        u.setSenhaHash(encoder.encode(req.senha()));
        u.setPerfil(req.perfil());
        u.setAtivo(req.ativo() == null || req.ativo());
        return repository.save(u);
    }

    @Transactional
    public Usuario atualizar(Long id, UsuarioUpdateRequest req, String emailLogado) {
        Usuario u = buscar(id);
        String email = req.email().trim().toLowerCase();
        repository.findByEmailIgnoreCase(email)
                .filter(outro -> !outro.getId().equals(id))
                .ifPresent(outro -> {
                    throw new BusinessException(HttpStatus.CONFLICT, "Já existe um usuário com este e-mail.");
                });

        boolean proprio = u.getEmail().equalsIgnoreCase(emailLogado);
        if (proprio && (req.perfil() != Perfil.ADMIN || !req.ativo())) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Você não pode remover o seu próprio perfil de administrador nem desativar a si mesmo.");
        }
        garantirOutroAdmin(u, req.perfil(), req.ativo());

        u.setNome(req.nome().trim());
        u.setEmail(email);
        u.setPerfil(req.perfil());
        if (req.ativo() && !u.isAtivo()) {
            // Reativação: o motivo da desativação não vale mais.
            u.setMotivoBloqueio(null);
            u.setBloqueadoPor(null);
        }
        u.setAtivo(req.ativo());
        if (req.novaSenha() != null && !req.novaSenha().isBlank()) {
            u.setSenhaHash(encoder.encode(req.novaSenha()));
            refreshTokens.revogarTodos(u.getId());
            sessoes.encerrarDoUsuario(u.getId(), MotivoEncerramento.SENHA_ALTERADA, emailLogado, null);
        }
        if (!req.ativo()) {
            refreshTokens.revogarTodos(u.getId());
            sessoes.encerrarDoUsuario(u.getId(), MotivoEncerramento.USUARIO_DESATIVADO, emailLogado, null);
        }
        return u;
    }

    @Transactional
    public void desbloquear(Long id) {
        Usuario u = buscar(id);
        u.setTentativasFalhas(0);
        u.setBloqueadoAte(null);
        u.setMotivoBloqueio(null);
        u.setBloqueadoPor(null);
    }

    /**
     * Bloqueio manual (tela de Visitantes): impede o login até {@code ate} e encerra na hora as
     * sessões abertas do usuário.
     */
    @Transactional
    public Usuario bloquear(Long id, Instant ate, String motivo, String emailLogado) {
        Usuario u = buscar(id);
        if (u.getEmail().equalsIgnoreCase(emailLogado)) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Você não pode bloquear o seu próprio acesso.");
        }
        if (ate == null || !ate.isAfter(Instant.now())) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Informe uma data de liberação no futuro.");
        }
        u.setBloqueadoAte(ate);
        u.setMotivoBloqueio(motivo == null || motivo.isBlank() ? "Bloqueio administrativo" : motivo.trim());
        u.setBloqueadoPor(emailLogado);
        u.setTentativasFalhas(0);
        refreshTokens.revogarTodos(u.getId());
        sessoes.encerrarDoUsuario(u.getId(), MotivoEncerramento.USUARIO_BLOQUEADO, emailLogado, null);
        return u;
    }

    /** Bloqueio permanente = desativar o usuário (mantendo pelo menos um administrador ativo). */
    @Transactional
    public Usuario desativar(Long id, String motivo, String emailLogado) {
        Usuario u = buscar(id);
        if (u.getEmail().equalsIgnoreCase(emailLogado)) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Você não pode desativar a si mesmo.");
        }
        garantirOutroAdmin(u, u.getPerfil(), false);
        u.setAtivo(false);
        u.setMotivoBloqueio(motivo == null || motivo.isBlank() ? null : motivo.trim());
        u.setBloqueadoPor(emailLogado);
        refreshTokens.revogarTodos(u.getId());
        sessoes.encerrarDoUsuario(u.getId(), MotivoEncerramento.USUARIO_DESATIVADO, emailLogado, null);
        return u;
    }

    @Transactional
    public void excluir(Long id, String emailLogado) {
        Usuario u = buscar(id);
        if (u.getEmail().equalsIgnoreCase(emailLogado)) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Você não pode excluir o seu próprio usuário.");
        }
        garantirOutroAdmin(u, null, false);
        sessoes.encerrarDoUsuario(u.getId(), MotivoEncerramento.USUARIO_EXCLUIDO, emailLogado, null);
        repository.delete(u);
    }

    @Transactional
    public Usuario atualizarNome(String email, String nome) {
        Usuario u = porEmail(email);
        u.setNome(nome.trim());
        return u;
    }

    @Transactional
    public void trocarSenha(String email, String senhaAtual, String novaSenha) {
        Usuario u = porEmail(email);
        if (!encoder.matches(senhaAtual, u.getSenhaHash())) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "A senha atual não confere.");
        }
        u.setSenhaHash(encoder.encode(novaSenha));
        refreshTokens.revogarTodos(u.getId());
        sessoes.encerrarDoUsuario(u.getId(), MotivoEncerramento.SENHA_ALTERADA, email, null);
    }

    @Transactional(readOnly = true)
    public Usuario porEmail(String email) {
        return repository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new BusinessException(HttpStatus.NOT_FOUND, "Usuário não encontrado."));
    }

    /** Impede que o sistema fique sem nenhum administrador ativo. */
    private void garantirOutroAdmin(Usuario u, Perfil novoPerfil, boolean continuaAtivo) {
        boolean eraAdminAtivo = u.getPerfil() == Perfil.ADMIN && u.isAtivo();
        boolean continuaAdmin = novoPerfil == Perfil.ADMIN && continuaAtivo;
        if (eraAdminAtivo && !continuaAdmin && repository.countByPerfilAndAtivoTrue(Perfil.ADMIN) <= 1) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "É preciso manter pelo menos um administrador ativo.");
        }
    }
}
