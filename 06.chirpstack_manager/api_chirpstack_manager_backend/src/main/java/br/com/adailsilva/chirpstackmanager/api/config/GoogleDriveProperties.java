package br.com.adailsilva.chirpstackmanager.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Envio de backups ao Google Drive (prefixo {@code app.google-drive}).
 * <p>
 * As credenciais do cliente OAuth podem ser cadastradas na tela (Backup → Google Drive), com o
 * Client Secret gravado cifrado, ou vir daqui (Secret do Kubernetes). A tela tem prioridade.
 *
 * @param clientId        Client ID da instalação ({@code GOOGLE_DRIVE_CLIENT_ID})
 * @param clientSecret    Client Secret da instalação ({@code GOOGLE_DRIVE_CLIENT_SECRET})
 * @param redirectUri     endereço PÚBLICO do callback; precisa estar cadastrado, igual, em
 *                        "URIs de redirecionamento autorizados" do cliente OAuth no Google Cloud
 * @param retornoFrontend rota do frontend para onde o navegador volta depois do consentimento
 * @param pastaPadrao     pasta padrão no Drive (aceita níveis separados por "/")
 */
@ConfigurationProperties(prefix = "app.google-drive")
public record GoogleDriveProperties(
        String clientId,
        String clientSecret,
        String redirectUri,
        String retornoFrontend,
        String pastaPadrao) {

    public GoogleDriveProperties {
        if (clientId == null) {
            clientId = "";
        }
        if (clientSecret == null) {
            clientSecret = "";
        }
        if (redirectUri == null || redirectUri.isBlank()) {
            redirectUri = "http://localhost:4200/api/v1/backup/google-drive/callback";
        }
        if (retornoFrontend == null || retornoFrontend.isBlank()) {
            retornoFrontend = "/sistema/backup";
        }
        if (pastaPadrao == null || pastaPadrao.isBlank()) {
            pastaPadrao = "ChirpStack Manager/Backups";
        }
    }
}
