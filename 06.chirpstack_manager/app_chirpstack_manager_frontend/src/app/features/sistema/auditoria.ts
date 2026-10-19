import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { SistemaService } from '@/app/core/api/sistema.service';
import { RegistroAuditoria } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';

/**
 * Auditoria: logins e operações de escrita feitas pelo painel. Somente ADMIN.
 */
@Component({
    selector: 'app-auditoria',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, IconFieldModule, InputIconModule, InputTextModule, SelectModule, TableModule, TagModule, PageHeader],
    template: `
        <app-page-header title="Auditoria" subtitle="Logins e alterações feitas no ChirpStack através deste painel" icon="pi pi-history">
            <p-button icon="pi pi-refresh" label="Atualizar" severity="secondary" [outlined]="true" (onClick)="carregar()" [loading]="carregando()" />
        </app-page-header>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[20, 50, 100]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '70rem' }" [rowHover]="true" styleClass="p-datatable-sm">
                <ng-template #caption>
                    <div class="flex flex-wrap gap-2 justify-end">
                        <p-select [options]="acoes" [ngModel]="acao()" (ngModelChange)="acao.set($event ?? ''); recarregarDoInicio()" placeholder="Todas as ações" [showClear]="true" styleClass="w-56" />
                        <p-iconfield>
                            <p-inputicon class="pi pi-search" />
                            <input pInputText type="text" placeholder="Usuário, recurso ou ação" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" />
                        </p-iconfield>
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th class="w-44">Data/hora</th>
                        <th>Usuário</th>
                        <th>Ação</th>
                        <th>Recurso</th>
                        <th>Resultado</th>
                        <th>IP</th>
                    </tr>
                </ng-template>
                <ng-template #body let-a>
                    <tr>
                        <td class="text-sm">{{ data(a.criadoEm) }}</td>
                        <td>{{ a.usuario || '—' }}</td>
                        <td><p-tag [value]="a.acao" [severity]="cor(a.acao)" /></td>
                        <td class="font-mono text-xs break-all">
                            @if (a.metodo) {
                                <b>{{ a.metodo }}</b>
                            }
                            {{ a.recurso }}
                            @if (a.detalhe) {
                                <div class="text-surface-500 font-sans">{{ a.detalhe }}</div>
                            }
                        </td>
                        <td>
                            <i [class]="a.sucesso ? 'pi pi-check-circle text-green-500' : 'pi pi-times-circle text-red-500'"></i>
                            <span class="text-sm ml-1">{{ a.statusHttp ?? '' }}</span>
                        </td>
                        <td class="text-sm font-mono">{{ a.ip }}</td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="6" class="text-center py-8 text-surface-500">Nenhum registro.</td></tr>
                </ng-template>
            </p-table>
        </div>
    `
})
export class Auditoria extends ListaPaginada<RegistroAuditoria> {
    private api = inject(SistemaService);
    private notify = inject(NotifyService);

    acao = signal('');
    acoes = ['LOGIN', 'LOGIN_FALHA', 'LOGIN_BLOQUEADO_IP', 'LOGOUT', 'CRIAR', 'ATUALIZAR', 'EXCLUIR', 'ATIVAR', 'ENFILEIRAR', 'GERAR_CERTIFICADO', 'ALTERAR_SENHA', 'CONSULTAR', 'REFRESH_REUTILIZADO'];
    data = dataHora;

    constructor() {
        super();
        this.rows.set(50);
    }

    protected consultar(q: ConsultaPagina) {
        return this.api.listarAuditoria(q.search, this.acao(), Math.floor(q.offset / q.limit), q.limit);
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    cor(acao: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
        if (acao.startsWith('LOGIN_') || acao === 'REFRESH_REUTILIZADO') {
            return 'danger';
        }
        switch (acao) {
            case 'LOGIN':
            case 'LOGOUT':
                return 'secondary';
            case 'CRIAR':
                return 'success';
            case 'EXCLUIR':
                return 'danger';
            case 'ATUALIZAR':
            case 'ATIVAR':
                return 'warn';
            default:
                return 'info';
        }
    }
}
