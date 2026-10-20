package br.com.adailsilva.chirpstackmanager.api.service.backup;

import java.nio.file.Path;
import java.util.List;

/**
 * Quem sabe gerar e restaurar o banco: PostgreSQL (produção, com pg_dump/pg_restore/psql) ou
 * H2 (desenvolvimento, com SCRIPT/RUNSCRIPT).
 */
public interface MotorBackup {

    /** Item da verificação prévia: cada um responde por uma causa só. */
    record Verificacao(String item, boolean ok, String detalhe) {
    }

    String nome();

    /** "backup" (formato custom do pg_dump) e/ou "sql" (texto). */
    List<String> formatos();

    void gerar(String formato, Path destino) throws Exception;

    void restaurar(Path arquivo) throws Exception;

    List<Verificacao> verificar();
}
