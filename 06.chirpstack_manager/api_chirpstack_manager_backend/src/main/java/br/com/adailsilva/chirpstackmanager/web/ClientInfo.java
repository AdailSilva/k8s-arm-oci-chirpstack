package br.com.adailsilva.chirpstackmanager.web;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Dados do cliente da requisição. Com {@code server.forward-headers-strategy=native}
 * o {@code getRemoteAddr()} já considera o {@code X-Forwarded-For}, mas só quando ele vem de um proxy interno
 * (RemoteIpValve do Tomcat com {@code server.forward-headers-strategy=native}), então o IP não pode ser forjado pelo cliente.
 */
public final class ClientInfo {

    private ClientInfo() {
    }

    public static String ip(HttpServletRequest request) {
        String ip = request.getRemoteAddr();
        return ip != null && ip.length() > 64 ? ip.substring(0, 64) : ip;
    }
}
