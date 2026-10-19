package br.com.adailsilva.chirpstackmanager.backup;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import javax.sql.DataSource;

import org.flywaydb.core.Flyway;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;

import br.com.adailsilva.chirpstackmanager.backup.BackupJob.Origem;
import br.com.adailsilva.chirpstackmanager.backup.BackupJob.Status;
import br.com.adailsilva.chirpstackmanager.backup.BackupJob.Tipo;
import br.com.adailsilva.chirpstackmanager.backup.MotorBackup.Verificacao;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveConfig;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveService;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveService.ResultadoEnvio;
import br.com.adailsilva.chirpstackmanager.config.BackupProperties;
import br.com.adailsilva.chirpstackmanager.sessao.MotivoEncerramento;
import br.com.adailsilva.chirpstackmanager.sessao.SessaoService;
import br.com.adailsilva.chirpstackmanager.web.BusinessException;
import jakarta.annotation.PreDestroy;

/**
 * Backup e restauração do banco do painel (usuários, sessões, auditoria e configurações).
 *
 * <ul>
 *   <li>As operações rodam em segundo plano; a tela acompanha o progresso pelo job
 *       ({@code tb_backup_job}), consultável em qualquer réplica.</li>
 *   <li>Uma operação por vez no cluster inteiro: não se faz um segundo dump sobre o mesmo banco nem
 *       se copia uma base no meio de uma restauração.</li>
 *   <li>Arquivos só dentro do volume de backups, em pastas fixas ({@link Pasta}) e com nome validado:
 *       nada de caminho vindo do navegador.</li>
 *   <li>Restaurar gera antes um backup de segurança (opcional, ligado por padrão), aplica as migrações
 *       pendentes (o backup pode ser de uma versão anterior) e encerra todas as sessões.</li>
 * </ul>
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);

    /** Pastas do volume de backups. */
    public enum Pasta {
        MANUAIS("manuais"), AGENDADOS("agendados"), SEGURANCA("seguranca");

        private final String dir;

        Pasta(String dir) {
            this.dir = dir;
        }

        public String dir() {
            return dir;
        }

        public static Pasta de(String valor) {
            for (Pasta p : values()) {
                if (p.dir.equalsIgnoreCase(valor) || p.name().equalsIgnoreCase(valor)) {
                    return p;
                }
            }
            throw new BusinessException(HttpStatus.BAD_REQUEST, "Pasta de backup inválida.");
        }
    }

    public record ArquivoBackup(String pasta, String nome, String formato, long tamanho, Instant modificadoEm) {
    }

    public record Motor(String nome, List<String> formatos) {
    }

    private static final Pattern NOME_VALIDO = Pattern.compile("^[A-Za-z0-9][A-Za-z0-9._-]{0,199}\\.(backup|sql)$");
    private static final Set<Status> ATIVOS = EnumSet.of(Status.PENDENTE, Status.EXECUTANDO);
    private static final DateTimeFormatter CARIMBO = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss");

    private final BackupProperties props;
    private final BackupJobRepository jobs;
    private final TransactionTemplate tx;
    private final GoogleDriveService drive;
    private final SessaoService sessoes;
    private final ObjectProvider<Flyway> flyway;
    private final MotorBackup motor;
    private final ZoneId zona;
    private final String instancia;
    private final Path base;

    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
    /** Trava local; a verificação no banco cobre as outras réplicas. */
    private final AtomicBoolean ocupado = new AtomicBoolean(false);

    public BackupService(BackupProperties props, BackupJobRepository jobs, TransactionTemplate tx,
                         GoogleDriveService drive, SessaoService sessoes, ObjectProvider<Flyway> flyway,
                         DataSource dataSource,
                         @Value("${spring.datasource.url}") String url,
                         @Value("${spring.datasource.username:}") String usuario,
                         @Value("${spring.datasource.password:}") String senha,
                         @Value("${app.fuso-horario:America/Fortaleza}") String fuso) {
        this.props = props;
        this.jobs = jobs;
        this.tx = tx;
        this.drive = drive;
        this.sessoes = sessoes;
        this.flyway = flyway;
        this.zona = ZoneId.of(fuso);
        this.base = Path.of(props.diretorio()).toAbsolutePath().normalize();
        String host = System.getenv("HOSTNAME");
        this.instancia = host != null && !host.isBlank() ? host : "local";
        if (url.startsWith("jdbc:postgresql:")) {
            this.motor = new MotorPostgres(props, url, usuario, senha);
        } else if (url.startsWith("jdbc:h2:")) {
            this.motor = new MotorH2(dataSource);
        } else {
            throw new IllegalStateException("Banco não suportado pelo módulo de backup: " + url);
        }
    }

    @PreDestroy
    void encerrar() {
        executor.shutdownNow();
    }

    // ── Consultas ────────────────────────────────────────────────────────────

    public Motor motor() {
        return new Motor(motor.nome(), motor.formatos());
    }

    /** Verificação prévia: utilitários, conexão com o banco, volume gravável e espaço livre. */
    public List<Verificacao> verificar() {
        List<Verificacao> v = new ArrayList<>(motor.verificar());
        try {
            Files.createDirectories(base);
            Path teste = Files.createTempFile(base, ".teste-escrita", ".tmp");
            Files.delete(teste);
            long livre = Files.getFileStore(base).getUsableSpace();
            v.add(new Verificacao("Volume de backups", true, base + " (" + tamanho(livre) + " livres)"));
        } catch (Exception e) {
            v.add(new Verificacao("Volume de backups", false, "Sem permissão de escrita em " + base + ": " + e.getMessage()));
        }
        boolean conectado = drive.isConectado();
        v.add(new Verificacao("Google Drive", conectado, conectado ? "Conta conectada" : "Não conectado (opcional)"));
        return v;
    }

    public List<ArquivoBackup> listarArquivos() {
        List<ArquivoBackup> lista = new ArrayList<>();
        for (Pasta pasta : Pasta.values()) {
            Path dir = base.resolve(pasta.dir());
            if (!Files.isDirectory(dir)) {
                continue;
            }
            try (DirectoryStream<Path> ds = Files.newDirectoryStream(dir)) {
                for (Path p : ds) {
                    String nome = p.getFileName().toString();
                    if (Files.isRegularFile(p) && NOME_VALIDO.matcher(nome).matches()) {
                        lista.add(new ArquivoBackup(pasta.dir(), nome, extensao(nome), Files.size(p),
                                Files.getLastModifiedTime(p).toInstant()));
                    }
                }
            } catch (IOException e) {
                log.warn("Não foi possível listar {}: {}", dir, e.getMessage());
            }
        }
        lista.sort(Comparator.comparing(ArquivoBackup::modificadoEm).reversed());
        return lista;
    }

    /** Caminho de um arquivo existente, validado contra o volume de backups. */
    public Path arquivo(String pasta, String nome) {
        Pasta p = Pasta.de(pasta);
        if (nome == null || !NOME_VALIDO.matcher(nome).matches()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "Nome de arquivo inválido.");
        }
        Path dir = base.resolve(p.dir()).normalize();
        Path arq = dir.resolve(nome).normalize();
        if (!arq.startsWith(dir) || !Files.isRegularFile(arq)) {
            throw new BusinessException(HttpStatus.NOT_FOUND, "Arquivo de backup não encontrado.");
        }
        return arq;
    }

    public void excluirArquivo(String pasta, String nome) {
        try {
            Files.delete(arquivo(pasta, nome));
        } catch (IOException e) {
            throw new BusinessException(HttpStatus.CONFLICT, "Não foi possível excluir o arquivo: " + e.getMessage());
        }
    }

    public BackupJob job(String id) {
        return jobs.findById(id).orElseThrow(() -> new BusinessException(HttpStatus.NOT_FOUND, "Execução não encontrada."));
    }

    public List<BackupJob> historico(int limite, boolean soAgendados) {
        PageRequest page = PageRequest.of(0, Math.min(Math.max(limite, 1), 200));
        return soAgendados
                ? jobs.findByOrigemInOrderByCriadoEmDesc(List.of(Origem.AGENDADO, Origem.EXECUTAR_AGORA), page)
                : jobs.findAllByOrderByCriadoEmDesc(page);
    }

    public boolean haOperacaoEmAndamento() {
        return ocupado.get() || jobs.existsByStatusIn(ATIVOS);
    }

    // ── Backup ───────────────────────────────────────────────────────────────

    /** Backup pela tela: pasta manuais/, com envio opcional ao Google Drive. */
    public BackupJob iniciarBackup(List<String> formatosPedidos, Boolean enviarDrive, String por) {
        List<String> formatos = validarFormatos(formatosPedidos);
        boolean drivePedido = enviarDrive != null ? enviarDrive : drive.isEnviarManuais();
        if (drivePedido && !drive.isConectado()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "O Google Drive não está conectado. Conecte a conta na aba Google Drive ou desmarque o envio.");
        }
        BackupJob job = criarJob(Tipo.BACKUP, Origem.MANUAL, por, j -> {
            j.setFormatos(String.join(",", formatos));
            j.setEnviarDrive(drivePedido);
        });
        executar(job, () -> executarBackup(job.getId(), Pasta.MANUAIS, formatos, drivePedido, true, 0, 1));
        return job;
    }

    /**
     * Backup do agendamento (relógio ou "Executar agora"): pasta agendados/ e retenção.
     * Sem destino servidor, os arquivos ficam numa área temporária apagada depois do envio ao Drive.
     */
    public BackupJob iniciarAgendado(BackupAgendamento cfg, Origem origem, Instant agendadoPara, String por) {
        // Formatos que o motor não oferece (ex.: "backup" no H2 de desenvolvimento) são ignorados.
        List<String> formatos = validarFormatos(cfg.listaFormatos().stream().filter(motor.formatos()::contains).toList());
        BackupJob job = criarJob(Tipo.BACKUP, origem, por, j -> {
            j.setFormatos(String.join(",", formatos));
            j.setEnviarDrive(cfg.isDestinoDrive());
            j.setAgendadoPara(agendadoPara);
        });
        executar(job, () -> executarBackup(job.getId(), Pasta.AGENDADOS, formatos, cfg.isDestinoDrive(),
                cfg.isDestinoServidor(), cfg.getRetencaoDias(), cfg.getManterMinimo()));
        return job;
    }

    /** Horário agendado que não rodou porque já havia outra operação em andamento. */
    public void registrarIgnorado(Instant agendadoPara, String motivo) {
        tx.executeWithoutResult(st -> {
            BackupJob j = new BackupJob(Tipo.BACKUP, Origem.AGENDADO, "agendamento", instancia);
            j.setStatus(Status.IGNORADO);
            j.setAgendadoPara(agendadoPara);
            j.setMensagem(motivo);
            j.setFinalizadoEm(Instant.now());
            jobs.save(j);
        });
    }

    private void executarBackup(String jobId, Pasta pasta, List<String> formatos, boolean enviarDrive,
                                boolean destinoServidor, int retencaoDias, int manterMinimo) {
        List<Path> gerados = new ArrayList<>();
        Path dirTemp = null;
        try {
            atualizar(jobId, j -> {
                j.setStatus(Status.EXECUTANDO);
                j.setIniciadoEm(Instant.now());
                j.setProgresso(5);
                j.setMensagem("Gerando backup (" + motor.nome() + ")");
            });
            Path dir;
            if (destinoServidor) {
                dir = Files.createDirectories(base.resolve(pasta.dir()));
            } else {
                dirTemp = Files.createTempDirectory("csm-backup");
                dir = dirTemp;
            }
            String carimbo = LocalDateTime.now(zona).format(CARIMBO);
            for (int i = 0; i < formatos.size(); i++) {
                String formato = formatos.get(i);
                Path destino = dir.resolve(props.prefixoArquivo() + "_" + carimbo + "." + formato);
                gerarArquivo(formato, destino);
                gerados.add(destino);
                int prog = 10 + (60 * (i + 1) / formatos.size());
                atualizar(jobId, j -> {
                    j.setProgresso(prog);
                    j.setMensagem("Arquivo ." + formato + " gerado");
                });
            }
            long total = 0;
            for (Path p : gerados) {
                total += Files.size(p);
            }
            long tamanhoTotal = total;
            List<String> nomes = gerados.stream().map(p -> p.getFileName().toString()).toList();
            atualizar(jobId, j -> {
                j.setArquivos(nomes);
                j.setTamanhoBytes(tamanhoTotal);
            });

            ResultadoEnvio envio = null;
            if (enviarDrive) {
                atualizar(jobId, j -> {
                    j.setProgresso(75);
                    j.setMensagem("Enviando ao Google Drive");
                    j.setDriveStatus("ENVIANDO");
                });
                envio = drive.enviar(gerados);
            }
            int removidos = destinoServidor && pasta == Pasta.AGENDADOS
                    ? aplicarRetencao(base.resolve(pasta.dir()), retencaoDias, manterMinimo) : 0;
            if (envio != null) {
                removidos += envio.removidos();
            }

            String mensagem;
            Status status;
            if (envio != null && !envio.sucesso()) {
                status = Status.PARCIAL;
                if (!destinoServidor) {
                    // O envio falhou e não havia cópia no servidor: guarda em agendados/ para não perder o backup.
                    Path guarda = Files.createDirectories(base.resolve(Pasta.AGENDADOS.dir()));
                    for (Path p : gerados) {
                        Files.move(p, guarda.resolve(p.getFileName()), StandardCopyOption.REPLACE_EXISTING);
                    }
                    mensagem = "Backup gerado, mas o envio ao Google Drive falhou. Os arquivos foram guardados em agendados/.";
                } else {
                    mensagem = "Backup gerado no servidor, mas o envio ao Google Drive falhou.";
                }
            } else {
                status = Status.SUCESSO;
                mensagem = destinoServidor ? "Backup concluído (" + tamanho(tamanhoTotal) + ")"
                        : "Backup concluído e enviado ao Google Drive (" + tamanho(tamanhoTotal) + ")";
            }
            ResultadoEnvio env = envio;
            int rem = removidos;
            atualizar(jobId, j -> {
                j.setStatus(status);
                j.setProgresso(100);
                j.setMensagem(mensagem);
                j.setRemovidos(rem);
                if (env != null) {
                    j.setDriveStatus(env.sucesso() ? "SUCESSO" : "ERRO");
                    j.setDriveMensagem(env.mensagem());
                }
                j.setFinalizadoEm(Instant.now());
            });
            log.info("Backup {} concluído: {} ({})", jobId, nomes, status);
        } catch (Exception e) {
            log.error("Backup {} falhou", jobId, e);
            for (Path p : gerados) {
                apagarSilencioso(p);
            }
            falhar(jobId, "O backup falhou.", e);
        } finally {
            if (dirTemp != null) {
                apagarArvore(dirTemp);
            }
        }
    }

    /** Gera num arquivo ".parcial" e renomeia no fim: a lista nunca mostra um backup pela metade. */
    private void gerarArquivo(String formato, Path destino) throws Exception {
        Path parcial = destino.resolveSibling(destino.getFileName() + ".parcial");
        try {
            motor.gerar(formato, parcial);
            if (!Files.exists(parcial) || Files.size(parcial) == 0) {
                throw new IOException("O arquivo gerado está vazio.");
            }
            Files.move(parcial, destino, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
        } finally {
            apagarSilencioso(parcial);
        }
    }

    /**
     * Retenção do servidor: por formato, mantém os {@code manterMinimo} mais recentes e apaga os
     * demais com mais de {@code dias}. Só mexe em arquivos com o prefixo deste sistema.
     */
    int aplicarRetencao(Path dir, int dias, int manterMinimo) {
        if (dias <= 0 || !Files.isDirectory(dir)) {
            return 0;
        }
        Instant limite = Instant.now().minus(Duration.ofDays(dias));
        int removidos = 0;
        try (var stream = Files.list(dir)) {
            Map<String, List<Path>> porFormato = stream
                    .filter(p -> Files.isRegularFile(p))
                    .filter(p -> {
                        String n = p.getFileName().toString();
                        return n.startsWith(props.prefixoArquivo()) && NOME_VALIDO.matcher(n).matches();
                    })
                    .collect(Collectors.groupingBy(p -> extensao(p.getFileName().toString())));
            for (List<Path> lista : porFormato.values()) {
                lista.sort(Comparator.comparing(BackupService::modificado).reversed());
                for (int i = manterMinimo; i < lista.size(); i++) {
                    Path p = lista.get(i);
                    if (modificado(p).isBefore(limite)) {
                        Files.deleteIfExists(p);
                        removidos++;
                    }
                }
            }
        } catch (IOException e) {
            log.warn("Retenção de {} falhou: {}", dir, e.getMessage());
        }
        return removidos;
    }

    // ── Restauração ──────────────────────────────────────────────────────────

    /** Restaura a partir de um arquivo enviado pelo navegador. */
    public BackupJob iniciarRestauracao(MultipartFile arquivo, boolean backupSeguranca, String por) {
        if (arquivo == null || arquivo.isEmpty()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "Selecione o arquivo de backup.");
        }
        String original = arquivo.getOriginalFilename() == null ? "" : arquivo.getOriginalFilename();
        String formato = extensao(original);
        validarFormatoRestauracao(formato);
        Path temp;
        try {
            temp = Files.createTempFile("csm-restauracao", "." + formato);
            try (InputStream in = arquivo.getInputStream()) {
                Files.copy(in, temp, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            throw new BusinessException(HttpStatus.INTERNAL_SERVER_ERROR, "Não foi possível receber o arquivo: " + e.getMessage());
        }
        try {
            validarConteudo(temp, formato);
        } catch (BusinessException e) {
            apagarSilencioso(temp);
            throw e;
        }
        String nomeExibido = original.replaceAll("[^A-Za-z0-9._ -]", "_");
        return iniciarRestauracao(temp, true, nomeExibido, backupSeguranca, por);
    }

    /** Restaura um arquivo que já está no servidor (sem baixar e reenviar). */
    public BackupJob iniciarRestauracaoDoServidor(String pasta, String nome, boolean backupSeguranca, String por) {
        Path arq = arquivo(pasta, nome);
        String formato = extensao(nome);
        validarFormatoRestauracao(formato);
        validarConteudo(arq, formato);
        return iniciarRestauracao(arq, false, Pasta.de(pasta).dir() + "/" + nome, backupSeguranca, por);
    }

    private BackupJob iniciarRestauracao(Path arquivo, boolean temporario, String nomeExibido, boolean backupSeguranca,
                                         String por) {
        BackupJob job;
        try {
            job = criarJob(Tipo.RESTORE, Origem.MANUAL, por, j -> {
                j.setFormatos(extensao(arquivo.getFileName().toString()));
                j.setArquivos(List.of(nomeExibido));
            });
        } catch (RuntimeException e) {
            if (temporario) {
                apagarSilencioso(arquivo);
            }
            throw e;
        }
        executar(job, () -> {
            try {
                executarRestauracao(job.getId(), arquivo, backupSeguranca, por);
            } finally {
                if (temporario) {
                    apagarSilencioso(arquivo);
                }
            }
        });
        return job;
    }

    private void executarRestauracao(String jobId, Path arquivo, boolean backupSeguranca, String por) {
        boolean restaurou = false;
        BackupJob copia = null;
        try {
            atualizar(jobId, j -> {
                j.setStatus(Status.EXECUTANDO);
                j.setIniciadoEm(Instant.now());
                j.setProgresso(5);
                j.setMensagem("Preparando a restauração");
            });
            String seguranca = null;
            if (backupSeguranca) {
                atualizar(jobId, j -> {
                    j.setProgresso(15);
                    j.setMensagem("Gerando backup de segurança do banco atual");
                });
                String formato = motor.formatos().get(0);
                Path dir = Files.createDirectories(base.resolve(Pasta.SEGURANCA.dir()));
                Path destino = dir.resolve(props.prefixoArquivo() + "_" + LocalDateTime.now(zona).format(CARIMBO)
                        + "_pre-restauracao." + formato);
                gerarArquivo(formato, destino);
                seguranca = destino.getFileName().toString();
            }
            String seg = seguranca;
            atualizar(jobId, j -> {
                j.setProgresso(40);
                j.setMensagem("Restaurando o banco de dados");
                if (seg != null) {
                    List<String> arqs = new ArrayList<>(j.listaArquivos());
                    arqs.add("seguranca/" + seg);
                    j.setArquivos(arqs);
                }
            });

            // O que precisa sobreviver à restauração: este job e a conexão atual com o Google.
            copia = job(jobId).copia();
            GoogleDriveConfig driveAtual = drive.instantaneo();

            motor.restaurar(arquivo);
            restaurou = true;

            Flyway f = flyway.getIfAvailable();
            if (f != null) {
                // O backup pode ser de uma versão anterior do sistema: aplica as migrações que faltarem.
                f.migrate();
            }
            // O dump trouxe o retrato de quando foi gerado, inclusive o próprio job em EXECUTANDO:
            // sem isto, novas operações ficariam bloqueadas como se houvesse uma em andamento.
            tx.executeWithoutResult(st -> jobs.findByStatusIn(ATIVOS).forEach(j -> {
                if (!j.getId().equals(jobId)) {
                    j.setStatus(Status.ERRO);
                    j.setMensagem("Interrompido: estado trazido pela restauração do backup.");
                    j.setFinalizadoEm(Instant.now());
                }
            }));
            drive.reaplicar(driveAtual);
            sessoes.descartarCache();
            int encerradas = sessoes.encerrarTodas(MotivoEncerramento.RESTAURACAO_BACKUP, por, null);

            BackupJob fim = copia;
            fim.setStatus(Status.SUCESSO);
            fim.setProgresso(100);
            fim.setMensagem("Banco restaurado. " + encerradas + " sessão(ões) encerrada(s): todos precisam entrar novamente.");
            fim.setFinalizadoEm(Instant.now());
            tx.executeWithoutResult(st -> jobs.save(fim));
            log.warn("Banco restaurado por {} a partir de {}.", por, arquivo.getFileName());
        } catch (Exception e) {
            log.error("Restauração {} falhou", jobId, e);
            String prefixo = restaurou
                    ? "O banco foi restaurado, mas a atualização da estrutura falhou. Reinicie a API."
                    : "A restauração falhou e o banco não foi alterado.";
            if (restaurou && copia != null) {
                BackupJob fim = copia;
                fim.setStatus(Status.ERRO);
                fim.setMensagem(prefixo);
                fim.setErro(e.getMessage());
                fim.setFinalizadoEm(Instant.now());
                try {
                    tx.executeWithoutResult(st -> jobs.save(fim));
                } catch (RuntimeException ex) {
                    log.error("Não foi possível regravar o job da restauração: {}", ex.getMessage());
                }
            } else {
                falhar(jobId, prefixo, e);
            }
        }
    }

    // ── Infra ────────────────────────────────────────────────────────────────

    private BackupJob criarJob(Tipo tipo, Origem origem, String por, Consumer<BackupJob> ajuste) {
        if (!ocupado.compareAndSet(false, true)) {
            throw new BusinessException(HttpStatus.CONFLICT, "Já existe um backup ou restauração em andamento.");
        }
        try {
            BackupJob job = tx.execute(st -> {
                if (jobs.existsByStatusIn(ATIVOS)) {
                    throw new BusinessException(HttpStatus.CONFLICT,
                            "Já existe um backup ou restauração em andamento.");
                }
                BackupJob j = new BackupJob(tipo, origem, por, instancia);
                ajuste.accept(j);
                return jobs.save(j);
            });
            return job;
        } catch (RuntimeException e) {
            ocupado.set(false);
            throw e;
        }
    }

    private void executar(BackupJob job, Runnable tarefa) {
        try {
            executor.submit(() -> {
                try {
                    tarefa.run();
                } finally {
                    ocupado.set(false);
                }
            });
        } catch (RuntimeException e) {
            ocupado.set(false);
            falhar(job.getId(), "Não foi possível iniciar a execução.", e);
            throw e;
        }
    }

    private void atualizar(String jobId, Consumer<BackupJob> alteracao) {
        tx.executeWithoutResult(st -> jobs.findById(jobId).ifPresent(alteracao));
    }

    private void falhar(String jobId, String mensagem, Exception e) {
        try {
            atualizar(jobId, j -> {
                j.setStatus(Status.ERRO);
                j.setMensagem(mensagem);
                j.setErro(e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName());
                j.setFinalizadoEm(Instant.now());
            });
        } catch (RuntimeException ex) {
            log.error("Não foi possível registrar a falha do job {}: {}", jobId, ex.getMessage());
        }
    }

    private List<String> validarFormatos(List<String> pedidos) {
        Set<String> formatos = new LinkedHashSet<>();
        if (pedidos != null) {
            for (String f : pedidos) {
                if (f != null && !f.isBlank()) {
                    formatos.add(f.trim().toLowerCase(Locale.ROOT));
                }
            }
        }
        if (formatos.isEmpty()) {
            formatos.add(motor.formatos().get(0));
        }
        for (String f : formatos) {
            if (!motor.formatos().contains(f)) {
                throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "Formato ." + f + " não disponível para " + motor.nome() + ". Use: " + motor.formatos() + ".");
            }
        }
        return List.copyOf(formatos);
    }

    private void validarFormatoRestauracao(String formato) {
        if (!motor.formatos().contains(formato)) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Envie um arquivo " + motor.formatos().stream().map(f -> "." + f).collect(Collectors.joining(" ou "))
                            + " gerado por este sistema.");
        }
    }

    /** Confere a assinatura do arquivo: .backup começa com "PGDMP"; .sql precisa ser texto. */
    private static void validarConteudo(Path arquivo, String formato) {
        byte[] inicio = new byte[4096];
        int n;
        try (InputStream in = Files.newInputStream(arquivo)) {
            n = in.readNBytes(inicio, 0, inicio.length);
        } catch (IOException e) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "Não foi possível ler o arquivo.");
        }
        if (n == 0) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "O arquivo está vazio.");
        }
        if ("backup".equals(formato)) {
            if (n < 5 || !"PGDMP".equals(new String(inicio, 0, 5, StandardCharsets.US_ASCII))) {
                throw new BusinessException(HttpStatus.BAD_REQUEST,
                        "O arquivo .backup não é um dump do PostgreSQL (formato custom do pg_dump).");
            }
        } else {
            for (int i = 0; i < n; i++) {
                if (inicio[i] == 0) {
                    throw new BusinessException(HttpStatus.BAD_REQUEST, "O arquivo .sql não é um arquivo de texto.");
                }
            }
        }
    }

    private static String extensao(String nome) {
        int i = nome.lastIndexOf('.');
        return i >= 0 ? nome.substring(i + 1).toLowerCase(Locale.ROOT) : "";
    }

    private static Instant modificado(Path p) {
        try {
            return Files.getLastModifiedTime(p).toInstant();
        } catch (IOException e) {
            return Instant.EPOCH;
        }
    }

    static String tamanho(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        double v = bytes;
        String[] u = {"KB", "MB", "GB", "TB"};
        int i = -1;
        while (v >= 1024 && i < u.length - 1) {
            v /= 1024;
            i++;
        }
        return String.format(Locale.forLanguageTag("pt-BR"), "%.1f %s", v, u[i]);
    }

    private static void apagarSilencioso(Path p) {
        try {
            Files.deleteIfExists(p);
        } catch (IOException ignorado) {
            // limpeza
        }
    }

    private static void apagarArvore(Path dir) {
        try (var s = Files.walk(dir)) {
            s.sorted(Comparator.reverseOrder()).forEach(BackupService::apagarSilencioso);
        } catch (IOException ignorado) {
            // limpeza
        }
    }

    // ── Manutenção ───────────────────────────────────────────────────────────

    /** Na subida: jobs que ficaram "executando" num pod que caiu viram erro. */
    @EventListener(ApplicationReadyEvent.class)
    public void aoIniciar() {
        try {
            Files.createDirectories(base);
        } catch (IOException e) {
            log.warn("Volume de backups indisponível em {}: {}", base, e.getMessage());
        }
        recolherOrfaos(Duration.ZERO);
    }

    /** De hora em hora: órfãos e limpeza do histórico. */
    @Scheduled(cron = "0 17 * * * *")
    public void manutencao() {
        try {
            recolherOrfaos(props.tempoLimite().plusMinutes(10));
            tx.executeWithoutResult(st -> jobs.apagarAntesDe(Instant.now().minus(Duration.ofDays(props.historicoDias())),
                    ATIVOS));
        } catch (RuntimeException e) {
            log.warn("Manutenção do histórico de backup falhou: {}", e.getMessage());
        }
    }

    /**
     * Na subida ({@code idade} zero) recolhe só os desta instância — eles morreram com o processo
     * anterior. No horário, recolhe qualquer um preso há mais que o tempo limite.
     */
    private void recolherOrfaos(Duration idade) {
        try {
            tx.executeWithoutResult(st -> {
                Instant limite = Instant.now().minus(idade);
                for (BackupJob j : jobs.findByStatusIn(ATIVOS)) {
                    boolean desta = instancia.equals(j.getInstancia());
                    boolean velho = j.getCriadoEm().isBefore(limite);
                    // Uma execução desta instância ainda em curso (envio longo ao Drive, por exemplo) não é órfã.
                    boolean rodandoAqui = desta && ocupado.get() && !idade.isZero();
                    if (!rodandoAqui && ((idade.isZero() && desta) || (!idade.isZero() && velho))) {
                        j.setStatus(Status.ERRO);
                        j.setMensagem("Interrompido: a API reiniciou durante a execução.");
                        j.setFinalizadoEm(Instant.now());
                    }
                }
            });
        } catch (RuntimeException e) {
            log.warn("Não foi possível recolher execuções interrompidas: {}", e.getMessage());
        }
    }
}
