package br.com.adailsilva.chirpstackmanager.sessao;

import java.util.Locale;

/**
 * Resumo legível do User-Agent: "Chrome · Windows (computador)". Só para exibição.
 */
public final class Dispositivo {

    private Dispositivo() {
    }

    public static String descrever(String userAgent) {
        if (userAgent == null || userAgent.isBlank()) {
            return "Desconhecido";
        }
        String ua = userAgent.toLowerCase(Locale.ROOT);
        String navegador;
        if (ua.contains("edg/") || ua.contains("edga/") || ua.contains("edgios/")) {
            navegador = "Edge";
        } else if (ua.contains("opr/") || ua.contains("opera")) {
            navegador = "Opera";
        } else if (ua.contains("samsungbrowser")) {
            navegador = "Samsung Internet";
        } else if (ua.contains("firefox/") || ua.contains("fxios/")) {
            navegador = "Firefox";
        } else if (ua.contains("chrome/") || ua.contains("crios/") || ua.contains("chromium")) {
            navegador = "Chrome";
        } else if (ua.contains("safari/")) {
            navegador = "Safari";
        } else if (ua.contains("curl") || ua.contains("python") || ua.contains("java") || ua.contains("postman")) {
            navegador = "Cliente HTTP";
        } else {
            navegador = "Navegador";
        }

        String sistema;
        if (ua.contains("android")) {
            sistema = "Android";
        } else if (ua.contains("iphone") || ua.contains("ipad") || ua.contains("ipod")) {
            sistema = "iOS";
        } else if (ua.contains("windows")) {
            sistema = "Windows";
        } else if (ua.contains("mac os x") || ua.contains("macintosh")) {
            sistema = "macOS";
        } else if (ua.contains("cros")) {
            sistema = "ChromeOS";
        } else if (ua.contains("linux")) {
            sistema = "Linux";
        } else {
            sistema = null;
        }

        String tipo;
        if (ua.contains("ipad") || ua.contains("tablet") || (ua.contains("android") && !ua.contains("mobile"))) {
            tipo = "tablet";
        } else if (ua.contains("mobile") || ua.contains("iphone")) {
            tipo = "celular";
        } else {
            tipo = "computador";
        }
        String texto = navegador + (sistema != null ? " · " + sistema : "") + " (" + tipo + ")";
        return texto.length() > 120 ? texto.substring(0, 120) : texto;
    }
}
