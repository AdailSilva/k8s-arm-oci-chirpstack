package br.com.adailsilva.chirpstackmanager.api.service.backup;

import java.nio.file.Path;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;

import javax.sql.DataSource;

/**
 * Backup do H2 (perfil dev): {@code SCRIPT DROP TO} gera um .sql que apaga e recria tudo;
 * {@code RUNSCRIPT FROM} restaura. Só o formato .sql.
 */
class MotorH2 implements MotorBackup {

    private final DataSource dataSource;

    MotorH2(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public String nome() {
        return "H2 (desenvolvimento)";
    }

    @Override
    public List<String> formatos() {
        return List.of("sql");
    }

    @Override
    public void gerar(String formato, Path destino) throws Exception {
        try (Connection c = dataSource.getConnection(); Statement st = c.createStatement()) {
            st.execute("SCRIPT DROP TO '" + literal(destino) + "' CHARSET 'UTF-8'");
        }
    }

    @Override
    public void restaurar(Path arquivo) throws Exception {
        try (Connection c = dataSource.getConnection(); Statement st = c.createStatement()) {
            // Banco limpo antes: tabelas de versões mais novas não podem sobrar (o Flyway as recria).
            st.execute("DROP ALL OBJECTS");
            st.execute("RUNSCRIPT FROM '" + literal(arquivo) + "' CHARSET 'UTF-8'");
        }
    }

    @Override
    public List<Verificacao> verificar() {
        try (Connection c = dataSource.getConnection(); Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT H2VERSION()")) {
            rs.next();
            return List.of(new Verificacao("Conexão com o banco", true, "H2 " + rs.getString(1)));
        } catch (Exception e) {
            return List.of(new Verificacao("Conexão com o banco", false, e.getMessage()));
        }
    }

    /** O caminho é montado pelo próprio serviço (nunca vem do usuário); mesmo assim, aspas são escapadas. */
    private static String literal(Path p) {
        return p.toAbsolutePath().toString().replace("'", "''");
    }
}
