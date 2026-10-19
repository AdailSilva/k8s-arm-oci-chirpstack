package br.com.adailsilva.chirpstackmanager.sessao;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Confere, depois da validação do JWT, se a sessão do token ({@code sid}) continua aberta.
 * <p>
 * Sessão encerrada → 401 com {@code X-Sessao-Status: ENCERRADA}: o frontend não tenta renovar e
 * leva o usuário ao login mostrando o motivo. Token sem {@code sid} (emitido antes desta versão)
 * → 401 comum: o frontend renova e recebe um token já ligado a uma sessão.
 * <p>
 * Não é um {@code @Component} de propósito: é registrado só na cadeia do Spring Security
 * (ver {@code SecurityConfig}), para não rodar duas vezes como filtro do servlet.
 */
public class SessaoAtivaFilter extends OncePerRequestFilter {

    private final SessaoService sessoes;

    public SessaoAtivaFilter(SessaoService sessoes) {
        this.sessoes = sessoes;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri.startsWith("/api/v1/auth/logout") || uri.startsWith("/api/v1/auth/refresh")
                || uri.startsWith("/api/v1/auth/login") || !uri.startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            String sid = jwt.getToken().getClaimAsString("sid");
            if (sid == null || sid.isBlank()) {
                SecurityContextHolder.clearContext();
                escrever(response, null, "NAO_AUTENTICADO", "Sessão expirada ou inválida. Entre novamente.");
                return;
            }
            Optional<MotivoEncerramento> motivo = sessoes.verificar(sid);
            if (motivo.isPresent()) {
                SecurityContextHolder.clearContext();
                escrever(response, motivo.get(), SessaoEncerradaException.CODIGO, motivo.get().mensagem());
                return;
            }
        }
        chain.doFilter(request, response);
    }

    private static void escrever(HttpServletResponse res, MotivoEncerramento motivo, String erro, String mensagem)
            throws IOException {
        res.setStatus(HttpStatus.UNAUTHORIZED.value());
        if (motivo != null) {
            res.setHeader(SessaoEncerradaException.HEADER, SessaoEncerradaException.ENCERRADA);
            res.setHeader(SessaoEncerradaException.HEADER_MOTIVO, motivo.name());
        }
        res.setHeader("Cache-Control", "no-store");
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding(StandardCharsets.UTF_8.name());
        res.getWriter().write("{\"status\":401,\"erro\":\"" + erro + "\",\"mensagem\":\"" + mensagem.replace("\"", "'")
                + "\"" + (motivo != null ? ",\"detalhe\":null,\"motivo\":\"" + motivo.name() + "\"" : "") + "}");
    }
}
