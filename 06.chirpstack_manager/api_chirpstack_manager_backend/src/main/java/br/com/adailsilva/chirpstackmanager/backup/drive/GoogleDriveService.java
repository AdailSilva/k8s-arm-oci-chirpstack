package br.com.adailsilva.chirpstackmanager.backup.drive;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveCliente.ArquivoDrive;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveCliente.Conta;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveCliente.Tokens;
import br.com.adailsilva.chirpstackmanager.config.BackupProperties;
import br.com.adailsilva.chirpstackmanager.config.GoogleDriveProperties;
import br.com.adailsilva.chirpstackmanager.security.CifradorSegredos;
import br.com.adailsilva.chirpstackmanager.web.BusinessException;

/**
 * Conexão com o Google Drive e envio dos backups.
 * <p>
 * Fluxo de conexão (OAuth 2.0 "authorization code"): o ADMIN clica em "Conectar conta Google", a API
 * devolve a URL do consentimento com um {@code state} aleatório de uso único (10 minutos), o Google
 * chama o callback com o código, a API troca o código pelos tokens e grava o refresh token cifrado.
 */
@Service
public class GoogleDriveService {

    private static final Logger log = LoggerFactory.getLogger(GoogleDriveService.class);

    static final String FIN_SECRET = "google-drive.client-secret";
    static final String FIN_REFRESH = "google-drive.refresh-token";

    /** Resultado de um envio: o backup continua válido no servidor mesmo quando o envio falha. */
    public record ResultadoEnvio(boolean sucesso, String mensagem, int enviados, int removidos) {
    }

    public record ConfigResponse(boolean credenciaisDefinidas, String origemCredenciais, String clientId,
                                 boolean clientSecretDefinido, boolean conectado, String contaEmail, String contaNome,
                                 Instant conectadoEm, String conectadoPor, String erroConexao, String pastaNome,
                                 String pastaLink, boolean enviarManuais, int retencaoDias, int manterMinimo,
                                 String redirectUri, boolean chaveCifragemDedicada, Instant ultimoEnvioEm,
                                 String ultimoEnvioStatus, String ultimoEnvioMensagem) {
    }

    public record ConfigRequest(String clientId, String clientSecret, String pastaNome, Boolean enviarManuais,
                                Integer retencaoDias, Integer manterMinimo) {
    }

    private record Credenciais(String clientId, String clientSecret) {
    }

    private final GoogleDriveConfigRepository repository;
    private final GoogleDriveCliente cliente;
    private final CifradorSegredos cifrador;
    private final GoogleDriveProperties props;
    private final BackupProperties backupProps;
    private final TransactionTemplate tx;
    private final SecureRandom random = new SecureRandom();

    public GoogleDriveService(GoogleDriveConfigRepository repository, GoogleDriveCliente cliente,
                              CifradorSegredos cifrador, GoogleDriveProperties props, BackupProperties backupProps,
                              TransactionTemplate tx) {
        this.repository = repository;
        this.cliente = cliente;
        this.cifrador = cifrador;
        this.props = props;
        this.backupProps = backupProps;
        this.tx = tx;
    }

    // ── Configuração ─────────────────────────────────────────────────────────

    public ConfigResponse consultar() {
        GoogleDriveConfig c = config();
        Credenciais cred = credenciais(c);
        boolean daTela = c.getClientId() != null && !c.getClientId().isBlank();
        return new ConfigResponse(cred != null, daTela ? "TELA" : (cred != null ? "AMBIENTE" : null),
                daTela ? c.getClientId() : props.clientId(),
                daTela ? c.getClientSecretCifrado() != null : !props.clientSecret().isBlank(),
                c.isConectado(), c.getContaEmail(), c.getContaNome(), c.getConectadoEm(), c.getConectadoPor(),
                c.getErroConexao(), c.getPastaNome(), GoogleDriveCliente.linkPasta(c.getPastaId()), c.isEnviarManuais(),
                c.getRetencaoDias(), c.getManterMinimo(), props.redirectUri(), cifrador.isChaveDedicada(),
                c.getUltimoEnvioEm(), c.getUltimoEnvioStatus(), c.getUltimoEnvioMensagem());
    }

    public ConfigResponse salvar(ConfigRequest req, String por) {
        tx.executeWithoutResult(st -> {
            GoogleDriveConfig c = config();
            if (req.clientId() != null) {
                String novo = req.clientId().trim();
                if (!novo.equals(c.getClientId() == null ? "" : c.getClientId()) && c.isConectado()) {
                    // A autorização gravada pertence ao cliente OAuth anterior.
                    c.limparConexao();
                    c.setErroConexao("O Client ID mudou: conecte a conta Google novamente.");
                }
                c.setClientId(novo.isEmpty() ? null : novo);
                if (novo.isEmpty()) {
                    c.setClientSecretCifrado(null);
                }
            }
            if (req.clientSecret() != null && !req.clientSecret().isBlank()) {
                c.setClientSecretCifrado(cifrador.cifrar(req.clientSecret().trim(), FIN_SECRET));
            }
            if (req.pastaNome() != null) {
                String pasta = normalizarPasta(req.pastaNome());
                if (!pasta.equals(c.getPastaNome())) {
                    c.setPastaNome(pasta);
                    c.setPastaId(null);
                }
            }
            if (req.enviarManuais() != null) {
                c.setEnviarManuais(req.enviarManuais());
            }
            if (req.retencaoDias() != null) {
                if (req.retencaoDias() < 0 || req.retencaoDias() > 3650) {
                    throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Retenção no Drive: de 0 a 3650 dias.");
                }
                c.setRetencaoDias(req.retencaoDias());
            }
            if (req.manterMinimo() != null) {
                if (req.manterMinimo() < 1 || req.manterMinimo() > 100) {
                    throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Manter no mínimo: de 1 a 100 arquivos.");
                }
                c.setManterMinimo(req.manterMinimo());
            }
            c.setAtualizadoPor(por);
            repository.save(c);
        });
        return consultar();
    }

    // ── Conexão (OAuth) ──────────────────────────────────────────────────────

    /** Gera o state de uso único e devolve a URL do consentimento do Google. */
    public String iniciarAutorizacao(String por) {
        GoogleDriveConfig c = config();
        Credenciais cred = credenciais(c);
        if (cred == null) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Cadastre o Client ID e o Client Secret do cliente OAuth antes de conectar.");
        }
        byte[] b = new byte[32];
        random.nextBytes(b);
        String state = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
        tx.executeWithoutResult(st -> {
            GoogleDriveConfig atual = config();
            atual.setOauthState(state);
            atual.setOauthStateExpira(Instant.now().plus(10, ChronoUnit.MINUTES));
            atual.setOauthStateUsuario(por);
            repository.save(atual);
        });
        return cliente.urlAutorizacao(cred.clientId(), props.redirectUri(), state);
    }

    /** Callback do Google. Devolve o endereço do frontend para onde o navegador deve voltar. */
    public String concluirAutorizacao(String codigo, String state, String erro) {
        GoogleDriveConfig c = config();
        boolean stateValido = state != null && !state.isBlank() && state.equals(c.getOauthState())
                && c.getOauthStateExpira() != null && c.getOauthStateExpira().isAfter(Instant.now());
        String usuario = c.getOauthStateUsuario();
        if (!stateValido) {
            return retorno("erro", "A autorização expirou ou não foi iniciada por este sistema. Tente conectar de novo.");
        }
        // Uso único: o state é descartado antes de qualquer outra coisa.
        tx.executeWithoutResult(st -> {
            GoogleDriveConfig atual = config();
            atual.setOauthState(null);
            atual.setOauthStateExpira(null);
            atual.setOauthStateUsuario(null);
            repository.save(atual);
        });
        if (erro != null && !erro.isBlank()) {
            return retorno("erro", "access_denied".equals(erro)
                    ? "A permissão foi negada na tela do Google."
                    : "O Google recusou a autorização (" + erro + ").");
        }
        if (codigo == null || codigo.isBlank()) {
            return retorno("erro", "O Google não devolveu o código de autorização.");
        }
        try {
            Credenciais cred = credenciais(c);
            if (cred == null) {
                return retorno("erro", "Credenciais do cliente OAuth não configuradas.");
            }
            Tokens t = cliente.trocarCodigo(cred.clientId(), cred.clientSecret(), props.redirectUri(), codigo);
            if (t.refreshToken() == null || t.refreshToken().isBlank()) {
                return retorno("erro", "O Google não devolveu a autorização permanente (refresh token). Remova o "
                        + "acesso do app em myaccount.google.com/permissions e conecte de novo.");
            }
            Conta conta = cliente.contaDoIdToken(t.idToken());
            String pastaId = cliente.garantirPasta(t.accessToken(), null, c.getPastaNome());
            tx.executeWithoutResult(st -> {
                GoogleDriveConfig atual = config();
                atual.setRefreshTokenCifrado(cifrador.cifrar(t.refreshToken(), FIN_REFRESH));
                atual.setContaEmail(conta.email());
                atual.setContaNome(conta.nome());
                atual.setConectadoEm(Instant.now());
                atual.setConectadoPor(usuario);
                atual.setPastaId(pastaId);
                atual.setErroConexao(null);
                repository.save(atual);
            });
            log.info("Google Drive conectado à conta {} por {}.", conta.email(), usuario);
            return retorno("conectado", conta.email());
        } catch (GoogleDriveException e) {
            return retorno("erro", e.getMessage());
        } catch (RuntimeException e) {
            log.error("Falha ao concluir a conexão com o Google Drive", e);
            return retorno("erro", "Falha inesperada ao concluir a conexão.");
        }
    }

    public ConfigResponse desconectar(String por) {
        GoogleDriveConfig c = config();
        if (c.isConectado()) {
            try {
                cliente.revogar(cifrador.decifrar(c.getRefreshTokenCifrado(), FIN_REFRESH));
            } catch (IllegalStateException e) {
                log.info("Refresh token do Google ilegível ao desconectar: {}", e.getMessage());
            }
        }
        tx.executeWithoutResult(st -> {
            GoogleDriveConfig atual = config();
            atual.limparConexao();
            atual.setErroConexao(null);
            atual.setAtualizadoPor(por);
            repository.save(atual);
        });
        return consultar();
    }

    /** Envia e apaga um arquivo de teste na pasta configurada. */
    public ResultadoEnvio testar() {
        Path tmp = null;
        try {
            tmp = Files.createTempFile("csm-teste-drive", ".txt");
            Files.writeString(tmp, "Teste de envio do ChirpStack Manager em " + Instant.now() + "\n");
            Rodada s = abrir();
            ArquivoDrive a = cliente.enviarArquivo(s::token, s.pastaId(), tmp, "teste-chirpstack-manager.txt");
            cliente.apagar(s.token(), a.id());
            registrarResultado("SUCESSO", "Teste de envio concluído.");
            return new ResultadoEnvio(true, "Arquivo de teste enviado e removido da pasta \"" + config().getPastaNome()
                    + "\".", 1, 0);
        } catch (Exception e) {
            String msg = e instanceof GoogleDriveException || e instanceof BusinessException ? e.getMessage()
                    : "Falha no teste: " + e.getMessage();
            registrarResultado("ERRO", msg);
            return new ResultadoEnvio(false, msg, 0, 0);
        } finally {
            apagarSilencioso(tmp);
        }
    }

    // ── Envio dos backups ────────────────────────────────────────────────────

    public boolean isConectado() {
        return config().isConectado();
    }

    public boolean isEnviarManuais() {
        GoogleDriveConfig c = config();
        return c.isConectado() && c.isEnviarManuais();
    }

    /** Envia os arquivos e aplica a retenção do Drive. Nunca lança: o resultado diz o que houve. */
    public ResultadoEnvio enviar(List<Path> arquivos) {
        if (!config().isConectado()) {
            String msg = "Google Drive não conectado: os arquivos ficaram só no servidor.";
            registrarResultado("ERRO", msg);
            return new ResultadoEnvio(false, msg, 0, 0);
        }
        int enviados = 0;
        try {
            Rodada s = abrir();
            for (Path p : arquivos) {
                cliente.enviarArquivo(s::token, s.pastaId(), p, p.getFileName().toString());
                enviados++;
            }
            int removidos = aplicarRetencao(s);
            String msg = enviados + " arquivo(s) enviado(s) para \"" + config().getPastaNome() + "\""
                    + (removidos > 0 ? "; " + removidos + " antigo(s) removido(s) pela retenção" : "") + ".";
            registrarResultado("SUCESSO", msg);
            return new ResultadoEnvio(true, msg, enviados, removidos);
        } catch (Exception e) {
            String msg = (e instanceof GoogleDriveException || e instanceof BusinessException ? e.getMessage()
                    : "Falha no envio: " + e.getMessage())
                    + (enviados > 0 ? " (" + enviados + " de " + arquivos.size() + " enviado(s))" : "");
            log.warn("Envio ao Google Drive falhou: {}", msg);
            registrarResultado("ERRO", msg);
            if (e instanceof GoogleDriveException g && g.isAutorizacaoInvalida()) {
                marcarErroConexao(msg);
            }
            return new ResultadoEnvio(false, msg, enviados, 0);
        }
    }

    /** Antes de restaurar o banco: a conexão atual com o Google deve sobreviver à restauração. */
    public GoogleDriveConfig instantaneo() {
        return config().copia();
    }

    public void reaplicar(GoogleDriveConfig copia) {
        tx.executeWithoutResult(st -> repository.save(copia));
    }

    // ── Internos ─────────────────────────────────────────────────────────────

    /** Access token renovado + pasta garantida para uma rodada de envios. */
    private final class Rodada {
        private final Credenciais cred;
        private final String refresh;
        private String token;
        private Instant validoAte;
        private final String pastaId;

        Rodada(Credenciais cred, String refresh, GoogleDriveConfig c) {
            this.cred = cred;
            this.refresh = refresh;
            renovar();
            this.pastaId = cliente.garantirPasta(token, c.getPastaId(), c.getPastaNome());
            if (!pastaId.equals(c.getPastaId())) {
                tx.executeWithoutResult(st -> {
                    GoogleDriveConfig atual = config();
                    atual.setPastaId(pastaId);
                    repository.save(atual);
                });
            }
        }

        private void renovar() {
            Tokens t = cliente.renovar(cred.clientId(), cred.clientSecret(), refresh);
            token = t.accessToken();
            validoAte = Instant.now().plusSeconds(Math.max(t.expiraEmSegundos() - 120, 60));
        }

        String token() {
            if (Instant.now().isAfter(validoAte)) {
                renovar();
            }
            return token;
        }

        String pastaId() {
            return pastaId;
        }
    }

    private Rodada abrir() {
        GoogleDriveConfig c = config();
        Credenciais cred = credenciais(c);
        if (cred == null) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Credenciais do cliente OAuth não configuradas.");
        }
        if (!c.isConectado()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Conecte uma conta Google antes de enviar.");
        }
        String refresh;
        try {
            refresh = cifrador.decifrar(c.getRefreshTokenCifrado(), FIN_REFRESH);
        } catch (IllegalStateException e) {
            String msg = "A autorização gravada não pode ser lida (a chave de cifragem mudou). Conecte a conta Google novamente.";
            marcarErroConexao(msg);
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, msg);
        }
        try {
            return new Rodada(cred, refresh, c);
        } catch (GoogleDriveException e) {
            if (e.isAutorizacaoInvalida()) {
                marcarErroConexao(e.getMessage());
            }
            throw e;
        }
    }

    /**
     * Retenção no Drive: só arquivos de backup deste sistema (pelo prefixo), por formato, mantendo os
     * N mais recentes; os demais com mais de {@code retencaoDias} são apagados.
     */
    private int aplicarRetencao(Rodada s) {
        GoogleDriveConfig c = config();
        if (c.getRetencaoDias() <= 0) {
            return 0;
        }
        Instant limite = Instant.now().minus(Duration.ofDays(c.getRetencaoDias()));
        String prefixo = backupProps.prefixoArquivo();
        Map<String, List<ArquivoDrive>> porFormato = cliente.listar(s.token(), s.pastaId()).stream()
                .filter(a -> a.nome() != null && a.nome().startsWith(prefixo))
                .collect(Collectors.groupingBy(a -> extensao(a.nome())));
        int removidos = 0;
        for (List<ArquivoDrive> lista : porFormato.values()) {
            List<ArquivoDrive> ordenada = new ArrayList<>(lista);
            ordenada.sort((a, b) -> compararData(b.criadoEm(), a.criadoEm()));
            for (int i = c.getManterMinimo(); i < ordenada.size(); i++) {
                ArquivoDrive a = ordenada.get(i);
                if (a.criadoEm() != null && a.criadoEm().isBefore(limite)) {
                    cliente.apagar(s.token(), a.id());
                    removidos++;
                }
            }
        }
        return removidos;
    }

    private static int compararData(Instant a, Instant b) {
        if (a == null) {
            return b == null ? 0 : -1;
        }
        return b == null ? 1 : a.compareTo(b);
    }

    private static String extensao(String nome) {
        int i = nome.lastIndexOf('.');
        return i >= 0 ? nome.substring(i + 1).toLowerCase(Locale.ROOT) : "";
    }

    private Credenciais credenciais(GoogleDriveConfig c) {
        if (c.getClientId() != null && !c.getClientId().isBlank() && c.getClientSecretCifrado() != null) {
            try {
                return new Credenciais(c.getClientId(), cifrador.decifrar(c.getClientSecretCifrado(), FIN_SECRET));
            } catch (IllegalStateException e) {
                log.warn("Client Secret do Google gravado não pode ser decifrado: {}", e.getMessage());
            }
        }
        if (!props.clientId().isBlank() && !props.clientSecret().isBlank()) {
            return new Credenciais(props.clientId(), props.clientSecret());
        }
        return null;
    }

    private GoogleDriveConfig config() {
        return repository.findById(GoogleDriveConfig.ID).orElseGet(() -> {
            GoogleDriveConfig c = new GoogleDriveConfig();
            c.setPastaNome(props.pastaPadrao());
            return c;
        });
    }

    private void registrarResultado(String status, String mensagem) {
        try {
            tx.executeWithoutResult(st -> {
                GoogleDriveConfig c = config();
                c.setUltimoEnvioEm(Instant.now());
                c.setUltimoEnvioStatus(status);
                c.setUltimoEnvioMensagem(mensagem);
                repository.save(c);
            });
        } catch (RuntimeException e) {
            log.warn("Não foi possível registrar o resultado do envio ao Drive: {}", e.getMessage());
        }
    }

    private void marcarErroConexao(String mensagem) {
        try {
            tx.executeWithoutResult(st -> {
                GoogleDriveConfig c = config();
                c.setErroConexao(mensagem);
                repository.save(c);
            });
        } catch (RuntimeException e) {
            log.warn("Não foi possível registrar o erro de conexão do Drive: {}", e.getMessage());
        }
    }

    private String retorno(String situacao, String mensagem) {
        String base = props.retornoFrontend();
        return base + (base.contains("?") ? "&" : "?") + "aba=drive&drive=" + situacao + "&mensagem="
                + URLEncoder.encode(mensagem == null ? "" : mensagem, StandardCharsets.UTF_8);
    }

    private static String normalizarPasta(String pasta) {
        String p = pasta == null ? "" : pasta.trim().replaceAll("/+", "/").replaceAll("^/|/$", "");
        if (p.isEmpty()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Informe o nome da pasta no Drive.");
        }
        if (p.length() > 200) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Nome da pasta: até 200 caracteres.");
        }
        return p;
    }

    private static void apagarSilencioso(Path p) {
        if (p != null) {
            try {
                Files.deleteIfExists(p);
            } catch (Exception ignorado) {
                // arquivo temporário
            }
        }
    }
}
