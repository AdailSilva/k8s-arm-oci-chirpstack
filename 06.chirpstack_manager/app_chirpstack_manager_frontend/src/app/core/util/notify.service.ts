import { HttpErrorResponse } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { ConfirmationService, MessageService } from 'primeng/api';

/**
 * Mensagens (toast) e confirmações com textos em português.
 */
@Injectable({ providedIn: 'root' })
export class NotifyService {
    private messages = inject(MessageService);
    private confirmation = inject(ConfirmationService);

    sucesso(mensagem: string, titulo = 'Pronto'): void {
        this.messages.add({ severity: 'success', summary: titulo, detail: mensagem, life: 3500 });
    }

    info(mensagem: string, titulo = 'Informação'): void {
        this.messages.add({ severity: 'info', summary: titulo, detail: mensagem, life: 4000 });
    }

    aviso(mensagem: string, titulo = 'Atenção'): void {
        this.messages.add({ severity: 'warn', summary: titulo, detail: mensagem, life: 5000 });
    }

    erro(err: unknown, titulo = 'Não foi possível concluir'): void {
        // Sessão encerrada (administrador, inatividade, restauração...): a tela de login já mostra o motivo.
        if (err instanceof HttpErrorResponse && err.status === 401) {
            return;
        }
        this.messages.add({ severity: 'error', summary: titulo, detail: NotifyService.mensagem(err), life: 7000 });
    }

    static mensagem(err: unknown): string {
        if (err instanceof HttpErrorResponse) {
            const body = err.error as { mensagem?: string; detalhe?: string; campos?: { campo: string; mensagem: string }[] } | null;
            if (body?.campos?.length) {
                return body.campos.map((c) => c.mensagem).join(' ');
            }
            if (body?.mensagem) {
                return body.detalhe ? `${body.mensagem} (${body.detalhe})` : body.mensagem;
            }
            if (err.status === 0) {
                return 'Sem conexão com o servidor.';
            }
            return `Erro HTTP ${err.status}.`;
        }
        return err instanceof Error ? err.message : 'Erro inesperado.';
    }

    /** Confirmação de exclusão; executa {@code acao} se o usuário aceitar. */
    confirmarExclusao(descricao: string, acao: () => void, detalhe?: string): void {
        this.confirmation.confirm({
            header: 'Confirmar exclusão',
            message: `Excluir ${descricao}?${detalhe ? '<br><small>' + detalhe + '</small>' : ''} Esta ação não pode ser desfeita.`,
            icon: 'pi pi-exclamation-triangle',
            acceptLabel: 'Excluir',
            rejectLabel: 'Cancelar',
            acceptButtonProps: { severity: 'danger' },
            rejectButtonProps: { severity: 'secondary', outlined: true },
            accept: acao
        });
    }

    confirmar(titulo: string, mensagem: string, acao: () => void, rotulo = 'Confirmar'): void {
        this.confirmation.confirm({
            header: titulo,
            message: mensagem,
            icon: 'pi pi-question-circle',
            acceptLabel: rotulo,
            rejectLabel: 'Cancelar',
            rejectButtonProps: { severity: 'secondary', outlined: true },
            accept: acao
        });
    }
}
