package br.com.adailsilva.chirpstackmanager.backup;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import br.com.adailsilva.chirpstackmanager.backup.BackupJob.Origem;
import br.com.adailsilva.chirpstackmanager.backup.drive.GoogleDriveService;
import br.com.adailsilva.chirpstackmanager.web.BusinessException;

/**
 * Backup automático: grade semanal de horários (vários por dia), formatos, destinos e retenção.
 * <p>
 * O relógio ({@link BackupAgendamentoJob}) roda a cada minuto em todas as réplicas; só a que consegue
 * avançar {@code ultimo_disparo} no banco executa aquele horário. Horários perdidos por até 10 minutos
 * (API reiniciando, pausa do coletor) ainda são executados.
 */
@Service
public class BackupAgendamentoService {

    private static final Logger log = LoggerFactory.getLogger(BackupAgendamentoService.class);
    private static final int TOLERANCIA_MINUTOS = 10;
    private static final DateTimeFormatter HORA = DateTimeFormatter.ofPattern("HH:mm");

    public record Horario(int dia, String hora) {
    }

    public record AgendamentoResponse(boolean ativo, List<String> formatos, boolean destinoServidor,
                                      boolean destinoDrive, int retencaoDias, int manterMinimo, List<Horario> horarios,
                                      Instant proximaExecucao, String fusoHorario, Instant atualizadoEm,
                                      String atualizadoPor, boolean driveConectado, List<String> formatosDisponiveis) {
    }

    public record AgendamentoRequest(Boolean ativo, List<String> formatos, Boolean destinoServidor,
                                     Boolean destinoDrive, Integer retencaoDias, Integer manterMinimo,
                                     List<Horario> horarios) {
    }

    private final BackupAgendamentoRepository repository;
    private final BackupAgendamentoHorarioRepository horarios;
    private final BackupService backup;
    private final GoogleDriveService drive;
    private final TransactionTemplate tx;
    private final ZoneId zona;

    public BackupAgendamentoService(BackupAgendamentoRepository repository,
                                    BackupAgendamentoHorarioRepository horarios, BackupService backup,
                                    GoogleDriveService drive, TransactionTemplate tx,
                                    @Value("${app.fuso-horario:America/Fortaleza}") String fuso) {
        this.repository = repository;
        this.horarios = horarios;
        this.backup = backup;
        this.drive = drive;
        this.tx = tx;
        this.zona = ZoneId.of(fuso);
    }

    public AgendamentoResponse consultar() {
        BackupAgendamento c = config();
        List<BackupAgendamentoHorario> grade = grade();
        List<String> disponiveis = backup.motor().formatos();
        List<String> formatos = c.listaFormatos().stream().filter(disponiveis::contains).toList();
        return new AgendamentoResponse(c.isAtivo(), formatos.isEmpty() ? List.of(disponiveis.get(0)) : formatos, c.isDestinoServidor(), c.isDestinoDrive(),
                c.getRetencaoDias(), c.getManterMinimo(),
                grade.stream().map(h -> new Horario(h.getDiaSemana(), h.getHora().format(HORA))).toList(),
                c.isAtivo() ? proxima(grade) : null, zona.getId(), c.getAtualizadoEm(), c.getAtualizadoPor(),
                drive.isConectado(), backup.motor().formatos());
    }

    public AgendamentoResponse salvar(AgendamentoRequest req, String por) {
        boolean ativo = Boolean.TRUE.equals(req.ativo());
        boolean servidor = req.destinoServidor() == null || req.destinoServidor();
        boolean destinoDrive = Boolean.TRUE.equals(req.destinoDrive());
        if (!servidor && !destinoDrive) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Escolha pelo menos um destino: servidor e/ou Google Drive.");
        }
        if (destinoDrive && !drive.isConectado()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Conecte a conta Google na aba Google Drive antes de usá-la como destino.");
        }
        int retencao = req.retencaoDias() == null ? 30 : req.retencaoDias();
        int minimo = req.manterMinimo() == null ? 3 : req.manterMinimo();
        if (retencao < 0 || retencao > 3650) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Retenção: de 0 (nunca apagar) a 3650 dias.");
        }
        if (minimo < 1 || minimo > 100) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Manter no mínimo: de 1 a 100 arquivos.");
        }
        Set<String> formatos = new LinkedHashSet<>();
        for (String f : req.formatos() == null ? List.<String>of() : req.formatos()) {
            String n = f == null ? "" : f.trim().toLowerCase();
            if (!backup.motor().formatos().contains(n)) {
                throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Formato inválido: " + f);
            }
            formatos.add(n);
        }
        if (formatos.isEmpty()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Escolha pelo menos um formato.");
        }
        Set<BackupAgendamentoHorario.Chave> chaves = new LinkedHashSet<>();
        for (Horario h : req.horarios() == null ? List.<Horario>of() : req.horarios()) {
            if (h == null || h.dia() < 1 || h.dia() > 7) {
                throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Dia da semana inválido.");
            }
            LocalTime hora;
            try {
                hora = LocalTime.parse(h.hora(), HORA);
            } catch (DateTimeParseException | NullPointerException e) {
                throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Horário inválido: " + h.hora() + " (use HH:mm).");
            }
            chaves.add(new BackupAgendamentoHorario.Chave(h.dia(), hora));
        }
        if (ativo && chaves.isEmpty()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Inclua pelo menos um horário para ativar o backup automático.");
        }
        if (chaves.size() > 7 * 24) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY, "Horários demais na grade (máximo 24 por dia).");
        }
        tx.executeWithoutResult(st -> {
            BackupAgendamento c = config();
            c.setAtivo(ativo);
            c.setFormatos(String.join(",", formatos));
            c.setDestinoServidor(servidor);
            c.setDestinoDrive(destinoDrive);
            c.setRetencaoDias(retencao);
            c.setManterMinimo(minimo);
            c.setAtualizadoPor(por);
            repository.save(c);
            horarios.deleteAllInBatch();
            horarios.flush();
            horarios.saveAll(chaves.stream()
                    .map(k -> new BackupAgendamentoHorario(k.getDiaSemana(), k.getHora())).toList());
        });
        return consultar();
    }

    /** "Executar agora": um backup com a configuração do agendamento, fora da grade. */
    public BackupJob executarAgora(String por) {
        BackupAgendamento c = config();
        if (c.isDestinoDrive() && !drive.isConectado()) {
            throw new BusinessException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "O agendamento envia ao Google Drive, mas a conta não está conectada.");
        }
        return backup.iniciarAgendado(c, Origem.EXECUTAR_AGORA, null, por);
    }

    /** Chamado a cada minuto pelo relógio. */
    public void verificarAgenda() {
        BackupAgendamento c = config();
        if (!c.isAtivo()) {
            return;
        }
        List<BackupAgendamentoHorario> grade = grade();
        if (grade.isEmpty()) {
            return;
        }
        LocalDateTime agora = LocalDateTime.now(zona).truncatedTo(ChronoUnit.MINUTES);
        LocalDateTime slot = null;
        for (int m = 0; m <= TOLERANCIA_MINUTOS && slot == null; m++) {
            LocalDateTime t = agora.minusMinutes(m);
            int dia = t.getDayOfWeek().getValue();
            LocalTime hora = t.toLocalTime();
            if (grade.stream().anyMatch(h -> h.getDiaSemana() == dia && h.getHora().equals(hora))) {
                slot = t;
            }
        }
        if (slot == null || (c.getUltimoDisparo() != null && !slot.isAfter(c.getUltimoDisparo()))) {
            return;
        }
        LocalDateTime horario = slot;
        Integer ganhou = tx.execute(st -> repository.reivindicar(horario));
        if (ganhou == null || ganhou == 0) {
            return; // outra réplica ficou com este horário
        }
        Instant agendadoPara = horario.atZone(zona).toInstant();
        if (backup.haOperacaoEmAndamento()) {
            backup.registrarIgnorado(agendadoPara, "Ignorado: já havia um backup ou restauração em andamento.");
            log.warn("Backup agendado para {} ignorado: outra operação em andamento.", horario);
            return;
        }
        if (c.isDestinoDrive() && !c.isDestinoServidor() && !drive.isConectado()) {
            backup.registrarIgnorado(agendadoPara, "Ignorado: o único destino é o Google Drive e a conta não está conectada.");
            return;
        }
        try {
            BackupJob job = backup.iniciarAgendado(c, Origem.AGENDADO, agendadoPara, "agendamento");
            log.info("Backup agendado para {} iniciado (job {}).", horario, job.getId());
        } catch (BusinessException e) {
            backup.registrarIgnorado(agendadoPara, "Ignorado: " + e.getMessage());
        }
    }

    private Instant proxima(List<BackupAgendamentoHorario> grade) {
        if (grade.isEmpty()) {
            return null;
        }
        LocalDateTime agora = LocalDateTime.now(zona);
        for (int d = 0; d <= 7; d++) {
            LocalDate dia = agora.toLocalDate().plusDays(d);
            DayOfWeek dow = dia.getDayOfWeek();
            List<LocalTime> horas = grade.stream()
                    .filter(h -> h.getDiaSemana() == dow.getValue())
                    .map(BackupAgendamentoHorario::getHora)
                    .sorted()
                    .toList();
            for (LocalTime h : horas) {
                LocalDateTime t = dia.atTime(h);
                if (t.isAfter(agora)) {
                    return t.atZone(zona).toInstant();
                }
            }
        }
        return null;
    }

    private List<BackupAgendamentoHorario> grade() {
        List<BackupAgendamentoHorario> lista = new ArrayList<>(horarios.findAll());
        lista.sort(Comparator.comparingInt(BackupAgendamentoHorario::getDiaSemana)
                .thenComparing(BackupAgendamentoHorario::getHora));
        return lista;
    }

    private BackupAgendamento config() {
        return repository.findById(BackupAgendamento.ID).orElseGet(BackupAgendamento::new);
    }
}
