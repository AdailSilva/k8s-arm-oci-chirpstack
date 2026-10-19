package br.com.adailsilva.chirpstackmanager.backup.drive;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Supplier;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Cliente HTTP do Google — OAuth 2.0 e Google Drive API v3, sem SDK (só o {@link HttpClient} do JDK
 * e o Jackson que o Spring já traz).
 * <p>
 * <b>Escopo {@code drive.file}</b>: o sistema enxerga e altera SOMENTE os arquivos e pastas que ele
 * mesmo criou, nunca o resto do Drive da conta. É também um escopo não sensível, que dispensa a
 * verificação do app pelo Google. {@code openid email profile} servem só para mostrar a conta.
 * <p>
 * <b>Upload resumable</b> em blocos de 8 MiB: o dump não precisa caber na memória e uma queda de rede
 * retoma do último byte confirmado.
 */
@Component
public class GoogleDriveCliente {

    private static final Logger log = LoggerFactory.getLogger(GoogleDriveCliente.class);

    static final String AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
    static final String TOKEN_URL = "https://oauth2.googleapis.com/token";
    static final String REVOKE_URL = "https://oauth2.googleapis.com/revoke";
    static final String FILES_URL = "https://www.googleapis.com/drive/v3/files";
    static final String UPLOAD_URL = "https://www.googleapis.com/upload/drive/v3/files";
    static final String MIME_PASTA = "application/vnd.google-apps.folder";

    public static final String ESCOPOS = "openid email profile https://www.googleapis.com/auth/drive.file";

    /** Bloco do upload resumable: múltiplo de 256 KiB, como a API exige. */
    private static final int BLOCO = 8 * 1024 * 1024;
    private static final int MAX_FALHAS_SEGUIDAS = 6;

    public record Tokens(String accessToken, String refreshToken, long expiraEmSegundos, String idToken) {
    }

    public record Conta(String email, String nome) {
    }

    public record ArquivoDrive(String id, String nome, Long tamanho, Instant criadoEm) {
    }

    private final ObjectMapper mapper;
    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(20))
            .followRedirects(HttpClient.Redirect.NEVER)
            .build();

    public GoogleDriveCliente(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    // ── OAuth ────────────────────────────────────────────────────────────────

    /**
     * URL do consentimento. {@code access_type=offline} + {@code prompt=consent} garantem o refresh
     * token a cada conexão; {@code select_account} pergunta qual conta usar.
     */
    public String urlAutorizacao(String clientId, String redirectUri, String state) {
        Map<String, String> p = new LinkedHashMap<>();
        p.put("response_type", "code");
        p.put("client_id", clientId);
        p.put("redirect_uri", redirectUri);
        p.put("scope", ESCOPOS);
        p.put("access_type", "offline");
        p.put("prompt", "consent select_account");
        p.put("include_granted_scopes", "true");
        p.put("state", state);
        return AUTH_URL + "?" + form(p);
    }

    public Tokens trocarCodigo(String clientId, String clientSecret, String redirectUri, String codigo) {
        Map<String, String> p = new LinkedHashMap<>();
        p.put("grant_type", "authorization_code");
        p.put("code", codigo);
        p.put("client_id", clientId);
        p.put("client_secret", clientSecret);
        p.put("redirect_uri", redirectUri);
        return token(p, "Troca do código de autorização");
    }

    /** Novo access token (vale cerca de 1 h) a partir do refresh token gravado. */
    public Tokens renovar(String clientId, String clientSecret, String refreshToken) {
        Map<String, String> p = new LinkedHashMap<>();
        p.put("grant_type", "refresh_token");
        p.put("refresh_token", refreshToken);
        p.put("client_id", clientId);
        p.put("client_secret", clientSecret);
        return token(p, "Renovação do acesso");
    }

    /** Revoga o token no Google. Melhor esforço: desconectar não pode falhar por isto. */
    public void revogar(String token) {
        if (token == null || token.isBlank()) {
            return;
        }
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(REVOKE_URL))
                    .timeout(Duration.ofSeconds(20))
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .POST(HttpRequest.BodyPublishers.ofString("token=" + enc(token)))
                    .build();
            HttpResponse<String> r = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (r.statusCode() != 200) {
                log.info("Revogação do token Google respondeu {} (token possivelmente já inválido).", r.statusCode());
            }
        } catch (IOException e) {
            log.warn("Não foi possível revogar o token no Google: {}", e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Conta autorizada, lida do id_token. Sem conferir a assinatura de propósito: o token veio direto
     * do endpoint do Google, por TLS, nesta mesma troca — e serve só para exibir o e-mail.
     */
    public Conta contaDoIdToken(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            return new Conta(null, null);
        }
        try {
            String[] partes = idToken.split("\\.");
            if (partes.length < 2) {
                return new Conta(null, null);
            }
            JsonNode n = mapper.readTree(Base64.getUrlDecoder().decode(partes[1]));
            return new Conta(texto(n, "email"), texto(n, "name"));
        } catch (RuntimeException e) {
            log.warn("id_token do Google ilegível: {}", e.getMessage());
            return new Conta(null, null);
        }
    }

    private Tokens token(Map<String, String> params, String operacao) {
        HttpRequest req = HttpRequest.newBuilder(URI.create(TOKEN_URL))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form(params)))
                .build();
        HttpResponse<String> r = enviar(req, operacao);
        JsonNode n = json(r.body());
        if (r.statusCode() != 200) {
            String erro = texto(n, "error");
            String desc = texto(n, "error_description");
            boolean revogado = "invalid_grant".equals(erro);
            String msg;
            if (revogado) {
                msg = "O Google recusou a autorização gravada (revogada, expirada ou de outro cliente OAuth). "
                        + "Se o app está em modo \"Teste\" na tela de consentimento, o Google invalida a autorização "
                        + "a cada 7 dias: publique o app (\"Em produção\") e conecte a conta de novo.";
            } else if ("invalid_client".equals(erro) || "unauthorized_client".equals(erro)) {
                msg = "Client ID ou Client Secret recusados pelo Google. Confira as credenciais do cliente OAuth.";
            } else if ("redirect_uri_mismatch".equals(erro)) {
                msg = "O URI de redirecionamento não está cadastrado no cliente OAuth do Google Cloud. "
                        + "Cadastre exatamente o endereço mostrado na tela.";
            } else {
                msg = operacao + " falhou no Google (" + r.statusCode() + (erro != null ? " " + erro : "") + ")"
                        + (desc != null ? ": " + desc : ".");
            }
            throw new GoogleDriveException(msg, r.statusCode(), revogado);
        }
        return new Tokens(texto(n, "access_token"), texto(n, "refresh_token"), n.path("expires_in").asLong(3600),
                texto(n, "id_token"));
    }

    // ── Pastas e arquivos ────────────────────────────────────────────────────

    /**
     * Garante a pasta de destino e devolve o id. Se {@code pastaIdAtual} ainda existe (fora da
     * lixeira), é ela; senão percorre o caminho a partir da raiz, reaproveitando as pastas que o
     * próprio sistema já criou e criando as que faltam.
     */
    public String garantirPasta(String token, String pastaIdAtual, String caminho) {
        if (pastaIdAtual != null && !pastaIdAtual.isBlank()) {
            HttpResponse<String> r = enviar(get(FILES_URL + "/" + enc(pastaIdAtual) + "?fields=id,trashed,mimeType",
                    token), "Consulta da pasta");
            if (r.statusCode() == 200) {
                JsonNode n = json(r.body());
                if (!n.path("trashed").asBoolean(false) && MIME_PASTA.equals(texto(n, "mimeType"))) {
                    return pastaIdAtual;
                }
            } else if (r.statusCode() != 404) {
                throw erroApi(r, "Consulta da pasta");
            }
        }
        String pai = "root";
        for (String seg : caminho.split("/")) {
            String nome = seg.trim();
            if (nome.isEmpty()) {
                continue;
            }
            String q = "name = '" + escaparQuery(nome) + "' and mimeType = '" + MIME_PASTA + "' and '"
                    + escaparQuery(pai) + "' in parents and trashed = false";
            HttpResponse<String> r = enviar(get(FILES_URL + "?spaces=drive&pageSize=1&fields=files(id)&q=" + enc(q),
                    token), "Busca da pasta");
            if (r.statusCode() != 200) {
                throw erroApi(r, "Busca da pasta");
            }
            JsonNode files = json(r.body()).path("files");
            if (files.isArray() && files.size() > 0) {
                pai = texto(files.get(0), "id");
                continue;
            }
            Map<String, Object> meta = new LinkedHashMap<>();
            meta.put("name", nome);
            meta.put("mimeType", MIME_PASTA);
            meta.put("parents", List.of(pai));
            HttpResponse<String> c = enviar(postJson(FILES_URL + "?fields=id", token, meta), "Criação da pasta");
            if (c.statusCode() != 200) {
                throw erroApi(c, "Criação da pasta");
            }
            pai = texto(json(c.body()), "id");
            log.info("Google Drive: pasta \"{}\" criada ({}).", nome, pai);
        }
        if ("root".equals(pai)) {
            throw new GoogleDriveException("Informe o nome da pasta de destino no Drive.", 400, false);
        }
        return pai;
    }

    /** Arquivos (não pastas) dentro da pasta, do mais novo para o mais antigo. */
    public List<ArquivoDrive> listar(String token, String pastaId) {
        List<ArquivoDrive> out = new ArrayList<>();
        String q = "'" + escaparQuery(pastaId) + "' in parents and trashed = false and mimeType != '" + MIME_PASTA + "'";
        String pagina = null;
        do {
            String url = FILES_URL + "?spaces=drive&pageSize=1000&orderBy=createdTime%20desc"
                    + "&fields=nextPageToken,files(id,name,size,createdTime)&q=" + enc(q)
                    + (pagina != null ? "&pageToken=" + enc(pagina) : "");
            HttpResponse<String> r = enviar(get(url, token), "Listagem da pasta");
            if (r.statusCode() != 200) {
                throw erroApi(r, "Listagem da pasta");
            }
            JsonNode n = json(r.body());
            for (JsonNode f : n.path("files")) {
                String criado = texto(f, "createdTime");
                out.add(new ArquivoDrive(texto(f, "id"), texto(f, "name"),
                        f.hasNonNull("size") ? f.path("size").asLong() : null,
                        criado != null ? Instant.parse(criado) : null));
            }
            pagina = texto(n, "nextPageToken");
        } while (pagina != null);
        return out;
    }

    /** Apaga definitivamente (a lixeira continua ocupando a cota). */
    public void apagar(String token, String arquivoId) {
        HttpRequest req = HttpRequest.newBuilder(URI.create(FILES_URL + "/" + enc(arquivoId)))
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", "Bearer " + token)
                .DELETE().build();
        HttpResponse<String> r = enviar(req, "Exclusão de arquivo");
        if (r.statusCode() != 204 && r.statusCode() != 200 && r.statusCode() != 404) {
            throw erroApi(r, "Exclusão de arquivo");
        }
    }

    public static String linkPasta(String pastaId) {
        return pastaId == null || pastaId.isBlank() ? null : "https://drive.google.com/drive/folders/" + pastaId;
    }

    // ── Upload resumable ─────────────────────────────────────────────────────

    /**
     * Envia o arquivo para a pasta. {@code token} é consultado a cada bloco: um envio longo pode
     * passar da validade do access token.
     */
    public ArquivoDrive enviarArquivo(Supplier<String> token, String pastaId, Path arquivo, String nome)
            throws IOException {
        long total = Files.size(arquivo);
        String sessao = abrirSessao(token.get(), pastaId, nome, total);
        boolean reaberta = false;
        int falhas = 0;
        long enviado = 0;
        byte[] buf = new byte[BLOCO];

        try (FileChannel ch = FileChannel.open(arquivo, StandardOpenOption.READ)) {
            while (true) {
                int n = total == 0 ? 0 : ler(ch, enviado, buf);
                String faixa = total == 0 ? "bytes */0" : "bytes " + enviado + "-" + (enviado + n - 1) + "/" + total;
                HttpResponse<String> r = null;
                try {
                    HttpRequest req = HttpRequest.newBuilder(URI.create(sessao))
                            .timeout(Duration.ofMinutes(5))
                            .header("Authorization", "Bearer " + token.get())
                            .header("Content-Range", faixa)
                            .PUT(HttpRequest.BodyPublishers.ofByteArray(buf, 0, n))
                            .build();
                    r = http.send(req, HttpResponse.BodyHandlers.ofString());
                } catch (IOException e) {
                    log.warn("Google Drive: falha de rede no envio de {} (byte {}): {}", nome, enviado, e.getMessage());
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    throw new IOException("Envio interrompido.", e);
                }

                if (r != null) {
                    int st = r.statusCode();
                    if (st == 200 || st == 201) {
                        return arquivoDe(json(r.body()), nome, total);
                    }
                    if (st == 308) {
                        long novo = proximoByte(r);
                        if (novo > enviado) {
                            enviado = novo;
                            falhas = 0;
                            continue;
                        }
                        log.warn("Google Drive: bloco de {} não confirmado (byte {}).", nome, enviado);
                    } else if (st == 404 || st == 410) {
                        // A sessão de envio expirou ou foi descartada pelo Google: recomeça uma vez.
                        if (reaberta) {
                            throw erroApi(r, "Envio do arquivo");
                        }
                        sessao = abrirSessao(token.get(), pastaId, nome, total);
                        reaberta = true;
                        enviado = 0;
                        continue;
                    } else if (st >= 400 && st < 500 && st != 408 && st != 429) {
                        throw erroApi(r, "Envio do arquivo");
                    } else {
                        log.warn("Google Drive: resposta {} no envio de {}; tentando de novo.", st, nome);
                    }
                }

                // Falha transitória (rede, 5xx, 429): espera e pergunta ao Google até onde chegou.
                if (++falhas > MAX_FALHAS_SEGUIDAS) {
                    throw new GoogleDriveException("O envio de " + nome + " ao Google Drive falhou "
                            + MAX_FALHAS_SEGUIDAS + " vezes seguidas (rede instável ou Google indisponível).", 503, false);
                }
                dormir(Math.min(60_000L, 1000L << falhas));
                HttpResponse<String> s = consultarSessao(token.get(), sessao, total);
                if (s != null) {
                    if (s.statusCode() == 200 || s.statusCode() == 201) {
                        return arquivoDe(json(s.body()), nome, total);
                    }
                    if (s.statusCode() == 308) {
                        enviado = proximoByte(s);
                    }
                }
            }
        }
    }

    private String abrirSessao(String token, String pastaId, String nome, long total) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("name", nome);
        meta.put("parents", List.of(pastaId));
        String tipo = nome.toLowerCase(Locale.ROOT).endsWith(".sql") || nome.toLowerCase(Locale.ROOT).endsWith(".txt")
                ? "text/plain" : "application/octet-stream";
        HttpRequest req = HttpRequest.newBuilder(
                        URI.create(UPLOAD_URL + "?uploadType=resumable&fields=id,name,size,createdTime"))
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json; charset=UTF-8")
                .header("X-Upload-Content-Type", tipo)
                .header("X-Upload-Content-Length", String.valueOf(total))
                .POST(HttpRequest.BodyPublishers.ofString(escreverJson(meta), StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> r = enviar(req, "Abertura do envio");
        if (r.statusCode() != 200) {
            throw erroApi(r, "Abertura do envio");
        }
        return r.headers().firstValue("Location")
                .orElseThrow(() -> new GoogleDriveException("O Google não devolveu o endereço do envio.", 502, false));
    }

    private HttpResponse<String> consultarSessao(String token, String sessao, long total) {
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(sessao))
                    .timeout(Duration.ofSeconds(30))
                    .header("Authorization", "Bearer " + token)
                    .header("Content-Range", "bytes */" + total)
                    .PUT(HttpRequest.BodyPublishers.noBody())
                    .build();
            return http.send(req, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            return null;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return null;
        }
    }

    /** "Range: bytes=0-12345" → 12346. Sem o cabeçalho, nada foi gravado ainda. */
    private static long proximoByte(HttpResponse<String> r) {
        return r.headers().firstValue("Range")
                .map(v -> v.substring(v.lastIndexOf('-') + 1).trim())
                .map(v -> Long.parseLong(v) + 1)
                .orElse(0L);
    }

    private static int ler(FileChannel ch, long posicao, byte[] buf) throws IOException {
        ByteBuffer bb = ByteBuffer.wrap(buf);
        long pos = posicao;
        while (bb.hasRemaining()) {
            int n = ch.read(bb, pos);
            if (n < 0) {
                break;
            }
            pos += n;
        }
        return bb.position();
    }

    private ArquivoDrive arquivoDe(JsonNode n, String nome, long total) {
        String criado = texto(n, "createdTime");
        return new ArquivoDrive(texto(n, "id"), texto(n, "name") != null ? texto(n, "name") : nome,
                n.hasNonNull("size") ? n.path("size").asLong() : total,
                criado != null ? Instant.parse(criado) : Instant.now());
    }

    // ── HTTP utilitário ──────────────────────────────────────────────────────

    private static HttpRequest get(String url, String token) {
        return HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", "Bearer " + token)
                .GET().build();
    }

    private HttpRequest postJson(String url, String token, Object corpo) {
        return HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofString(escreverJson(corpo), StandardCharsets.UTF_8))
                .build();
    }

    private HttpResponse<String> enviar(HttpRequest req, String operacao) {
        try {
            return http.send(req, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            throw new GoogleDriveException(operacao + ": não foi possível falar com o Google ("
                    + e.getClass().getSimpleName() + (e.getMessage() != null ? ": " + e.getMessage() : "")
                    + "). Verifique se o servidor tem acesso à internet.", 503, false);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new GoogleDriveException(operacao + " interrompida.", 503, false);
        }
    }

    /** Traduz o erro da Drive API em algo que a pessoa consiga resolver. */
    private GoogleDriveException erroApi(HttpResponse<String> r, String operacao) {
        JsonNode n = json(r.body());
        JsonNode err = n.path("error");
        String msg = err.isObject() ? texto(err, "message") : texto(n, "error_description");
        String motivo = null;
        if (err.path("errors").isArray() && err.path("errors").size() > 0) {
            motivo = texto(err.path("errors").get(0), "reason");
        }
        int st = r.statusCode();
        String texto;
        if ("storageQuotaExceeded".equals(motivo) || (msg != null && msg.contains("storage quota"))) {
            texto = "A conta do Google Drive está sem espaço. Libere espaço ou reduza a retenção no Drive.";
        } else if ("accessNotConfigured".equals(motivo) || (msg != null && msg.contains("has not been used in project"))) {
            texto = "A Google Drive API não está ativada no projeto do Google Cloud. Ative-a em APIs e serviços → "
                    + "Biblioteca → Google Drive API e tente de novo em alguns minutos.";
        } else if (st == 401) {
            texto = "O Google recusou o acesso (token inválido). Conecte a conta Google novamente.";
        } else if (st == 403 && ("insufficientPermissions".equals(motivo) || "forbidden".equals(motivo))) {
            texto = "A conta não concedeu permissão ao Drive. Conecte de novo e marque a permissão do Google Drive.";
        } else {
            texto = operacao + " falhou no Google Drive (" + st + (motivo != null ? " " + motivo : "") + ")"
                    + (msg != null ? ": " + msg : ".");
        }
        return new GoogleDriveException(texto, st, st == 401);
    }

    private JsonNode json(String corpo) {
        if (corpo == null || corpo.isBlank()) {
            return mapper.createObjectNode();
        }
        try {
            return mapper.readTree(corpo);
        } catch (RuntimeException e) {
            return mapper.createObjectNode();
        }
    }

    private String escreverJson(Object o) {
        return mapper.writeValueAsString(o);
    }

    private static String texto(JsonNode n, String campo) {
        JsonNode v = n == null ? null : n.get(campo);
        return v == null || v.isNull() || v.isMissingNode() ? null : v.asString();
    }

    private static String form(Map<String, String> p) {
        return p.entrySet().stream().map(e -> enc(e.getKey()) + "=" + enc(e.getValue()))
                .collect(Collectors.joining("&"));
    }

    private static String enc(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8).replace("+", "%20");
    }

    /** Aspas simples e barra invertida escapadas, como a linguagem de busca do Drive pede. */
    private static String escaparQuery(String s) {
        return s.replace("\\", "\\\\").replace("'", "\\'");
    }

    private static void dormir(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
