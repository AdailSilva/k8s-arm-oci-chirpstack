package br.com.adailsilva.chirpstackmanager.auth;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Limita tentativas de login por IP (janela deslizante em memória).
 * Complementa o bloqueio por conta, protegendo contra tentativas em vários e-mails.
 */
@Component
public class LoginRateLimiter {

    private static final int MAX_TENTATIVAS = 20;
    private static final Duration JANELA = Duration.ofMinutes(5);

    private final Map<String, Deque<Instant>> tentativas = new ConcurrentHashMap<>();

    /** Registra a tentativa e devolve {@code false} se o IP passou do limite. */
    public boolean permitir(String ip) {
        Instant agora = Instant.now();
        Deque<Instant> fila = tentativas.computeIfAbsent(ip, k -> new ArrayDeque<>());
        synchronized (fila) {
            while (!fila.isEmpty() && fila.peekFirst().isBefore(agora.minus(JANELA))) {
                fila.pollFirst();
            }
            if (fila.size() >= MAX_TENTATIVAS) {
                return false;
            }
            fila.addLast(agora);
            return true;
        }
    }

    @Scheduled(fixedDelay = 600_000)
    void limpar() {
        Instant limite = Instant.now().minus(JANELA);
        tentativas.entrySet().removeIf(e -> {
            synchronized (e.getValue()) {
                return e.getValue().isEmpty() || e.getValue().peekLast().isBefore(limite);
            }
        });
    }
}
