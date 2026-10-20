package br.com.adailsilva.chirpstackmanager.api.web;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import br.com.adailsilva.chirpstackmanager.api.service.AuditoriaService;

/**
 * Audita toda requisição de escrita (POST, PUT, DELETE) feita aos recursos do ChirpStack e aos
 * usuários do painel. Corpos não são gravados, pois podem conter chaves e senhas.
 */
@Component
public class AuditoriaInterceptor implements HandlerInterceptor {

    private final AuditoriaService service;

    public AuditoriaInterceptor(AuditoriaService service) {
        this.service = service;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        String metodo = request.getMethod();
        if ("GET".equals(metodo) || "OPTIONS".equals(metodo) || "HEAD".equals(metodo)) {
            return;
        }
        String uri = request.getRequestURI();
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String usuario = auth != null && auth.isAuthenticated() ? auth.getName() : null;
        int status = response.getStatus();
        service.registrar(usuario, acao(metodo, uri), uri.replaceFirst("^/api/v1", ""), metodo, status,
                status < 400 && ex == null, null, ClientInfo.ip(request));
    }

    public static String acao(String metodo, String uri) {
        if (uri.endsWith("/get-random-dev-addr") || uri.endsWith("/get-next-f-cnt-down")) {
            return "CONSULTAR";
        }
        if (uri.endsWith("/generate-certificate") || uri.endsWith("/mqtt/certificate")) {
            return "GERAR_CERTIFICADO";
        }
        if (uri.endsWith("/activate")) {
            return "ATIVAR";
        }
        if (uri.endsWith("/queue") && "POST".equals(metodo)) {
            return "ENFILEIRAR";
        }
        if (uri.endsWith("/password")) {
            return "ALTERAR_SENHA";
        }
        return switch (metodo) {
            case "POST" -> "CRIAR";
            case "PUT" -> "ATUALIZAR";
            case "DELETE" -> "EXCLUIR";
            default -> metodo;
        };
    }
}
