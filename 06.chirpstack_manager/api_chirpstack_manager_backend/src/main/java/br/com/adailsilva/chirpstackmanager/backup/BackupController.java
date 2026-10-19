package br.com.adailsilva.chirpstackmanager.backup;

import java.nio.file.Path;
import java.util.List;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import br.com.adailsilva.chirpstackmanager.auditoria.AuditoriaService;
import br.com.adailsilva.chirpstackmanager.backup.BackupAgendamentoService.AgendamentoRequest;
import br.com.adailsilva.chirpstackmanager.backup.BackupAgendamentoService.AgendamentoResponse;
import br.com.adailsilva.chirpstackmanager.backup.BackupDtos.BackupRequest;
import br.com.adailsilva.chirpstackmanager.backup.BackupDtos.JobResponse;
import br.com.adailsilva.chirpstackmanager.backup.BackupDtos.RestauracaoServidorRequest;
import br.com.adailsilva.chirpstackmanager.backup.BackupDtos.VisaoGeral;
import br.com.adailsilva.chirpstackmanager.backup.BackupService.ArquivoBackup;
import br.com.adailsilva.chirpstackmanager.config.BackupProperties;
import br.com.adailsilva.chirpstackmanager.security.Ids;
import br.com.adailsilva.chirpstackmanager.security.Perfis;
import br.com.adailsilva.chirpstackmanager.web.ClientInfo;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.Pattern;

/**
 * Backup e restauração do banco do painel, backup automático (somente ADMIN).
 */
@RestController
@RequestMapping("/api/v1/backup")
@PreAuthorize(Perfis.ADMIN)
@Validated
public class BackupController {

    private final BackupService service;
    private final BackupAgendamentoService agendamento;
    private final AuditoriaService auditoria;
    private final BackupProperties props;

    public BackupController(BackupService service, BackupAgendamentoService agendamento, AuditoriaService auditoria,
                            BackupProperties props) {
        this.service = service;
        this.agendamento = agendamento;
        this.auditoria = auditoria;
        this.props = props;
    }

    /** Motor, formatos e verificação prévia (utilitários, banco, volume, Drive). */
    @GetMapping
    public VisaoGeral visaoGeral() {
        BackupService.Motor m = service.motor();
        return new VisaoGeral(m.nome(), m.formatos(), service.verificar(), service.haOperacaoEmAndamento(),
                Path.of(props.diretorio()).toAbsolutePath().normalize().toString());
    }

    @GetMapping("/arquivos")
    public List<ArquivoBackup> arquivos() {
        return service.listarArquivos();
    }

    @GetMapping("/arquivos/download")
    public ResponseEntity<Resource> download(@RequestParam String pasta, @RequestParam String nome,
                                             @AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        Path arq = service.arquivo(pasta, nome);
        auditoria.registrar(jwt.getSubject(), "BAIXAR_BACKUP", "/backup/arquivos/" + pasta + "/" + nome, "GET", 200,
                true, null, ClientInfo.ip(http));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(nome).build().toString())
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(new FileSystemResource(arq));
    }

    @DeleteMapping("/arquivos")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@RequestParam String pasta, @RequestParam String nome, @AuthenticationPrincipal Jwt jwt,
                        HttpServletRequest http) {
        service.excluirArquivo(pasta, nome);
        auditoria.registrar(jwt.getSubject(), "EXCLUIR_BACKUP", "/backup/arquivos/" + pasta + "/" + nome, "DELETE",
                204, true, null, ClientInfo.ip(http));
    }

    @PostMapping("/executar")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public JobResponse executar(@RequestBody(required = false) BackupRequest req, @AuthenticationPrincipal Jwt jwt,
                                HttpServletRequest http) {
        BackupJob job = service.iniciarBackup(req != null ? req.formatos() : null, req != null ? req.enviarDrive() : null,
                jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "GERAR_BACKUP", "/backup/executar", "POST", 202, true,
                "Formatos: " + job.getFormatos() + (job.isEnviarDrive() ? " + Google Drive" : ""), ClientInfo.ip(http));
        return JobResponse.of(job);
    }

    @PostMapping(value = "/restaurar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.ACCEPTED)
    public JobResponse restaurar(@RequestPart("arquivo") MultipartFile arquivo,
                                 @RequestParam(defaultValue = "true") boolean backupSeguranca,
                                 @AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        BackupJob job = service.iniciarRestauracao(arquivo, backupSeguranca, jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "RESTAURAR_BACKUP", "/backup/restaurar", "POST", 202, true,
                "Arquivo enviado: " + job.getArquivos(), ClientInfo.ip(http));
        return JobResponse.of(job);
    }

    @PostMapping("/restaurar/servidor")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public JobResponse restaurarDoServidor(@RequestBody RestauracaoServidorRequest req, @AuthenticationPrincipal Jwt jwt,
                                           HttpServletRequest http) {
        BackupJob job = service.iniciarRestauracaoDoServidor(req.pasta(), req.nome(),
                req.backupSeguranca() == null || req.backupSeguranca(), jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "RESTAURAR_BACKUP", "/backup/restaurar/servidor", "POST", 202, true,
                "Arquivo do servidor: " + req.pasta() + "/" + req.nome(), ClientInfo.ip(http));
        return JobResponse.of(job);
    }

    @GetMapping("/jobs/{id}")
    public JobResponse job(@PathVariable @Pattern(regexp = Ids.UUID) String id) {
        return JobResponse.of(service.job(id));
    }

    @GetMapping("/jobs")
    public List<JobResponse> historico(@RequestParam(defaultValue = "50") int limite,
                                       @RequestParam(defaultValue = "false") boolean agendados) {
        return service.historico(limite, agendados).stream().map(JobResponse::of).toList();
    }

    // ── Backup automático ────────────────────────────────────────────────────

    @GetMapping("/agendamento")
    public AgendamentoResponse agendamento() {
        return agendamento.consultar();
    }

    @PutMapping("/agendamento")
    public AgendamentoResponse salvarAgendamento(@RequestBody AgendamentoRequest req, @AuthenticationPrincipal Jwt jwt,
                                                 HttpServletRequest http) {
        AgendamentoResponse r = agendamento.salvar(req, jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "AGENDAR_BACKUP", "/backup/agendamento", "PUT", 200, true,
                (r.ativo() ? "Ativo" : "Desligado") + ", " + r.horarios().size() + " horário(s), formatos "
                        + r.formatos() + (r.destinoDrive() ? ", Google Drive" : ""),
                ClientInfo.ip(http));
        return r;
    }

    @PostMapping("/agendamento/executar-agora")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public JobResponse executarAgora(@AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        BackupJob job = agendamento.executarAgora(jwt.getSubject());
        auditoria.registrar(jwt.getSubject(), "GERAR_BACKUP", "/backup/agendamento/executar-agora", "POST", 202, true,
                "Com a configuração do agendamento", ClientInfo.ip(http));
        return JobResponse.of(job);
    }
}
