package br.com.adailsilva.chirpstackmanager.backup;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import br.com.adailsilva.chirpstackmanager.config.BackupProperties;

/**
 * Backup do PostgreSQL com os utilitários oficiais (pacote postgresql-client da imagem da API),
 * conectando direto no serviço do banco. Sem kubectl e sem permissões extras no cluster.
 * <ul>
 *   <li>{@code .backup}: {@code pg_dump --format=custom} (compactado, restaurável com pg_restore);</li>
 *   <li>{@code .sql}: {@code pg_dump --format=plain --clean --if-exists} (texto legível).</li>
 * </ul>
 * A restauração roda em transação única sobre um schema limpo: se falhar no meio, o banco fica como estava.
 */
class MotorPostgres implements MotorBackup {

    private final BackupProperties props;
    private final String host;
    private final String porta;
    private final String banco;
    private final String usuario;
    private final String senha;

    MotorPostgres(BackupProperties props, String jdbcUrl, String usuario, String senha) {
        this.props = props;
        // jdbc:postgresql://host:5432/banco?parametros
        URI uri = URI.create(jdbcUrl.substring("jdbc:".length()));
        this.host = uri.getHost() != null ? uri.getHost() : "localhost";
        this.porta = String.valueOf(uri.getPort() > 0 ? uri.getPort() : 5432);
        String path = uri.getPath() == null ? "" : uri.getPath();
        this.banco = path.startsWith("/") ? path.substring(1) : path;
        this.usuario = usuario;
        this.senha = senha;
    }

    @Override
    public String nome() {
        return "PostgreSQL";
    }

    @Override
    public List<String> formatos() {
        return List.of("backup", "sql");
    }

    @Override
    public void gerar(String formato, Path destino) throws Exception {
        List<String> cmd = new ArrayList<>(List.of(props.pgDump(), "--host=" + host, "--port=" + porta,
                "--username=" + usuario, "--dbname=" + banco, "--no-password", "--file=" + destino));
        if ("sql".equals(formato)) {
            cmd.addAll(List.of("--format=plain", "--clean", "--if-exists", "--no-owner", "--no-privileges"));
        } else {
            cmd.addAll(List.of("--format=custom", "--compress=6"));
        }
        executar(cmd, "pg_dump");
    }

    /**
     * Restaura num schema limpo: apaga o {@code public} inteiro e roda o script na mesma transação.
     * Assim tabelas criadas por versões mais novas não sobram (o Flyway as recria em seguida) e,
     * se qualquer comando falhar, nada muda. O .backup é convertido antes em SQL pelo pg_restore.
     */
    @Override
    public void restaurar(Path arquivo) throws Exception {
        String nome = arquivo.getFileName().toString().toLowerCase();
        Path script = arquivo;
        Path convertido = null;
        try {
            if (!nome.endsWith(".sql")) {
                convertido = Files.createTempFile("csm-restauracao", ".sql");
                executar(List.of(props.pgRestore(), "--no-owner", "--no-privileges", "--file=" + convertido,
                        arquivo.toString()), "pg_restore");
                script = convertido;
            }
            executar(List.of(props.psql(), "--host=" + host, "--port=" + porta, "--username=" + usuario,
                    "--dbname=" + banco, "--no-password", "--quiet", "--single-transaction",
                    "--set=ON_ERROR_STOP=1",
                    "--command=DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;",
                    "--file=" + script), "psql");
        } finally {
            if (convertido != null) {
                Files.deleteIfExists(convertido);
            }
        }
    }

    @Override
    public List<Verificacao> verificar() {
        List<Verificacao> v = new ArrayList<>();
        for (String bin : List.of(props.pgDump(), props.pgRestore(), props.psql())) {
            try {
                String versao = executar(List.of(bin, "--version"), bin).trim();
                v.add(new Verificacao(nomeCurto(bin), true, versao));
            } catch (Exception e) {
                v.add(new Verificacao(nomeCurto(bin), false,
                        "Não encontrado. A imagem da API precisa do pacote postgresql-client (" + e.getMessage() + ")"));
            }
        }
        try {
            String r = executar(List.of(props.psql(), "--host=" + host, "--port=" + porta, "--username=" + usuario,
                    "--dbname=" + banco, "--no-password", "--tuples-only", "--no-align",
                    "--command=select current_setting('server_version')"), "psql");
            v.add(new Verificacao("Conexão com o banco", true, "PostgreSQL " + r.trim() + " em " + host + ":" + porta
                    + "/" + banco));
        } catch (Exception e) {
            v.add(new Verificacao("Conexão com o banco", false, e.getMessage()));
        }
        return v;
    }

    private String ocultarSenha(String texto) {
        return senha == null || senha.isEmpty() ? texto : texto.replace(senha, "***");
    }

    private static String nomeCurto(String bin) {
        int i = Math.max(bin.lastIndexOf('/'), bin.lastIndexOf('\\'));
        return i >= 0 ? bin.substring(i + 1) : bin;
    }

    /** Executa e devolve a saída padrão. Falha com as últimas linhas do erro do utilitário. */
    private String executar(List<String> cmd, String rotulo) throws IOException, InterruptedException {
        Path saida = Files.createTempFile("csm-pg-out", ".log");
        Path erro = Files.createTempFile("csm-pg-err", ".log");
        try {
            ProcessBuilder pb = new ProcessBuilder(cmd)
                    .redirectOutput(saida.toFile())
                    .redirectError(erro.toFile());
            Map<String, String> env = pb.environment();
            env.put("PGPASSWORD", senha == null ? "" : senha);
            env.put("PGCONNECT_TIMEOUT", "15");
            env.put("PGAPPNAME", "chirpstack-manager-backup");
            Process p = pb.start();
            Duration limite = props.tempoLimite();
            if (!p.waitFor(limite.toMillis(), TimeUnit.MILLISECONDS)) {
                p.destroyForcibly();
                throw new IOException(rotulo + " passou do tempo limite de " + limite.toMinutes() + " minutos.");
            }
            if (p.exitValue() != 0) {
                List<String> linhas = Files.readAllLines(erro, StandardCharsets.UTF_8);
                String fim = String.join(" | ", linhas.subList(Math.max(0, linhas.size() - 6), linhas.size())).trim();
                throw new IOException(rotulo + " terminou com código " + p.exitValue()
                        + (fim.isEmpty() ? "." : ": " + ocultarSenha(fim)));
            }
            return Files.readString(saida, StandardCharsets.UTF_8);
        } finally {
            Files.deleteIfExists(saida);
            Files.deleteIfExists(erro);
        }
    }
}
