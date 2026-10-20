package br.com.adailsilva.chirpstackmanager.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import br.com.adailsilva.chirpstackmanager.api.domain.entity.Auditoria;
import br.com.adailsilva.chirpstackmanager.api.repository.AuditoriaRepository;

/**
 * Gravação e consulta da auditoria. Cada registro usa transação própria, então fica gravado
 * mesmo quando a operação auditada falha.
 */
@Service
public class AuditoriaService {

    private static final Logger log = LoggerFactory.getLogger("AUDITORIA");

    private final AuditoriaRepository repository;

    public AuditoriaService(AuditoriaRepository repository) {
        this.repository = repository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrar(String usuario, String acao, String recurso, String metodo, Integer status,
                          boolean sucesso, String detalhe, String ip) {
        try {
            repository.save(new Auditoria(usuario, acao, recurso, metodo, status, sucesso, detalhe, ip));
            log.info("{} {} {} {} -> {} {}", usuario, acao, metodo, recurso, status, sucesso ? "OK" : "FALHA");
        } catch (RuntimeException e) {
            log.error("Falha ao gravar auditoria: {}", e.getMessage());
        }
    }

    @Transactional(readOnly = true)
    public Page<Auditoria> listar(String busca, String acao, int pagina, int tamanho) {
        return repository.buscar(busca == null ? "" : busca.trim(), acao == null ? "" : acao.trim(),
                PageRequest.of(Math.max(pagina, 0), Math.min(Math.max(tamanho, 1), 200),
                        Sort.by(Sort.Direction.DESC, "criadoEm")));
    }
}
