package br.com.adailsilva.chirpstackmanager.api.service.backup;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Relógio do backup automático: confere a grade a cada minuto (segundo 5, para não coincidir com a
 * virada exata do minuto em que outras tarefas rodam).
 */
@Component
public class BackupAgendamentoJob {

    private static final Logger log = LoggerFactory.getLogger(BackupAgendamentoJob.class);

    private final BackupAgendamentoService service;
    /** A mesma falha a cada minuto vira uma linha de log por hora. */
    private volatile long ultimoErroLogado;

    public BackupAgendamentoJob(BackupAgendamentoService service) {
        this.service = service;
    }

    @Scheduled(cron = "5 * * * * *")
    public void verificar() {
        try {
            service.verificarAgenda();
        } catch (RuntimeException e) {
            long agora = System.currentTimeMillis();
            if (agora - ultimoErroLogado > 3_600_000L) {
                ultimoErroLogado = agora;
                log.error("Falha ao verificar a agenda do backup automático (repete em silêncio por 1 h).", e);
            }
        }
    }
}
