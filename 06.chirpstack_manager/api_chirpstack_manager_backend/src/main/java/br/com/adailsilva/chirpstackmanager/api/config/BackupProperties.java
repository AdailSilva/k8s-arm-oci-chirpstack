package br.com.adailsilva.chirpstackmanager.api.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Backup e restauração do banco do painel (prefixo {@code app.backup}).
 *
 * @param diretorio      volume onde ficam os backups (subpastas manuais/, agendados/, seguranca/)
 * @param prefixoArquivo início do nome dos arquivos ({@code chirpstack-manager_database_2026-10-19_02-00-00.backup})
 * @param pgDump         binário do pg_dump (pacote postgresql-client da imagem)
 * @param pgRestore      binário do pg_restore
 * @param psql           binário do psql (restauração de .sql)
 * @param tempoLimite    tempo máximo de um pg_dump/pg_restore
 * @param historicoDias  execuções mais antigas que isso saem do histórico
 */
@ConfigurationProperties(prefix = "app.backup")
public record BackupProperties(
        String diretorio,
        String prefixoArquivo,
        String pgDump,
        String pgRestore,
        String psql,
        Duration tempoLimite,
        Integer historicoDias) {

    public BackupProperties {
        if (diretorio == null || diretorio.isBlank()) {
            diretorio = "./data/backups";
        }
        if (prefixoArquivo == null || prefixoArquivo.isBlank()) {
            prefixoArquivo = "chirpstack-manager_database";
        }
        if (pgDump == null || pgDump.isBlank()) {
            pgDump = "pg_dump";
        }
        if (pgRestore == null || pgRestore.isBlank()) {
            pgRestore = "pg_restore";
        }
        if (psql == null || psql.isBlank()) {
            psql = "psql";
        }
        if (tempoLimite == null) {
            tempoLimite = Duration.ofMinutes(30);
        }
        if (historicoDias == null || historicoDias < 1) {
            historicoDias = 180;
        }
    }
}
