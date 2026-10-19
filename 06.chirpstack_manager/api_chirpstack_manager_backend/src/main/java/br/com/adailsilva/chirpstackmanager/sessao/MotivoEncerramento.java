package br.com.adailsilva.chirpstackmanager.sessao;

/**
 * Por que uma sessão terminou. A mensagem é a que o usuário lê na tela de login.
 */
public enum MotivoEncerramento {

    LOGOUT("Você saiu do sistema."),
    INATIVIDADE("Sua sessão foi encerrada por inatividade."),
    EXPIRADA("Sua sessão atingiu o tempo máximo permitido. Entre novamente."),
    ENCERRADA_ADMIN("Sua sessão foi encerrada por um administrador."),
    LIMITE_SESSOES("Sua sessão foi encerrada porque você entrou em outro dispositivo (limite de sessões simultâneas)."),
    SENHA_ALTERADA("Sua senha foi alterada. Entre novamente com a nova senha."),
    USUARIO_DESATIVADO("Seu usuário foi desativado. Procure um administrador."),
    USUARIO_BLOQUEADO("Seu acesso foi bloqueado por um administrador."),
    USUARIO_EXCLUIDO("Seu usuário foi removido do sistema."),
    REUSO_TOKEN("Sua sessão foi encerrada por segurança (credencial reutilizada). Entre novamente."),
    RESTAURACAO_BACKUP("O banco de dados foi restaurado a partir de um backup. Entre novamente."),
    /** Só em memória: a sessão do token não existe mais (por exemplo, depois de uma restauração). */
    INVALIDA("Sua sessão não é mais válida. Entre novamente.");

    private final String mensagem;

    MotivoEncerramento(String mensagem) {
        this.mensagem = mensagem;
    }

    public String mensagem() {
        return mensagem;
    }
}
