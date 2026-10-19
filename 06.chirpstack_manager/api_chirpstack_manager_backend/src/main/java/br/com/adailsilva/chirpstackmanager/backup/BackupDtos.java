package br.com.adailsilva.chirpstackmanager.backup;

import java.time.Instant;
import java.util.List;

public final class BackupDtos {

    private BackupDtos() {
    }

    public record BackupRequest(List<String> formatos, Boolean enviarDrive) {
    }

    public record RestauracaoServidorRequest(String pasta, String nome, Boolean backupSeguranca) {
    }

    public record JobResponse(String id, String tipo, String origem, String status, int progresso, String mensagem,
                              String erro, List<String> formatos, List<String> arquivos, Long tamanhoBytes,
                              boolean enviarDrive, String driveStatus, String driveMensagem, int removidos,
                              String solicitadoPor, String instancia, Instant agendadoPara, Instant criadoEm,
                              Instant iniciadoEm, Instant finalizadoEm, boolean emAndamento) {
        public static JobResponse of(BackupJob j) {
            return new JobResponse(j.getId(), j.getTipo().name(), j.getOrigem().name(), j.getStatus().name(),
                    j.getProgresso(), j.getMensagem(), j.getErro(),
                    j.getFormatos() == null || j.getFormatos().isBlank() ? List.of() : List.of(j.getFormatos().split(",")),
                    j.listaArquivos(), j.getTamanhoBytes(), j.isEnviarDrive(), j.getDriveStatus(), j.getDriveMensagem(),
                    j.getRemovidos(), j.getSolicitadoPor(), j.getInstancia(), j.getAgendadoPara(), j.getCriadoEm(),
                    j.getIniciadoEm(), j.getFinalizadoEm(), j.isEmAndamento());
        }
    }

    public record VisaoGeral(String motor, List<String> formatos, List<MotorBackup.Verificacao> verificacoes,
                             boolean emAndamento, String diretorio) {
    }
}
