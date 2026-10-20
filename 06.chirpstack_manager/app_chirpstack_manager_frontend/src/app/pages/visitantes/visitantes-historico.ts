import { Component, inject, input, signal, effect, untracked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DatePickerModule } from 'primeng/datepicker';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { VisitantesService } from '@/app/pages/visitantes/visitantes.service';
import { SessaoVisitante, VisitanteUsuario } from '@/app/core/http/models';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora } from '@/app/core/format/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/tabela/lista-paginada';
import { duracao, corMotivo } from './visitantes-util';

/** Histórico de acessos (sessões) com filtros por usuário, situação e período. */
@Component({
    selector: 'app-visitantes-historico',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, DatePickerModule, IconFieldModule, InputIconModule, InputTextModule, SelectModule, TableModule, TagModule, TooltipModule],
    template: `
        <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[20, 50, 100]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '72rem' }" [rowHover]="true" styleClass="p-datatable-sm">
            <ng-template #caption>
                <div class="flex flex-wrap gap-2 items-center justify-end">
                    <p-select [options]="usuarios()" optionLabel="nome" optionValue="usuarioId" [ngModel]="usuarioId()" (ngModelChange)="usuarioId.set($event); recarregarDoInicio()" placeholder="Todos os usuários" [showClear]="true" [filter]="true" filterBy="nome,email" styleClass="w-56" appendTo="body" />
                    <p-select [options]="situacoes" optionLabel="label" optionValue="value" [ngModel]="situacao()" (ngModelChange)="situacao.set($event ?? ''); recarregarDoInicio()" placeholder="Todas as situações" [showClear]="true" styleClass="w-44" appendTo="body" />
                    <p-datepicker [ngModel]="periodo()" (ngModelChange)="mudarPeriodo($event)" selectionMode="range" [readonlyInput]="true" dateFormat="dd/mm/yy" placeholder="Período" [showIcon]="true" [showButtonBar]="true" appendTo="body" styleClass="w-60" />
                    <p-iconfield>
                        <p-inputicon class="pi pi-search" />
                        <input pInputText type="text" placeholder="Nome, e-mail, IP ou dispositivo" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" class="w-64" />
                    </p-iconfield>
                </div>
            </ng-template>
            <ng-template #header>
                <tr>
                    <th>Usuário</th>
                    <th class="w-44">Entrada</th>
                    <th class="w-44">Saída</th>
                    <th class="w-28">Duração</th>
                    <th>Dispositivo</th>
                    <th class="w-36">IP</th>
                    <th class="w-52">Situação</th>
                </tr>
            </ng-template>
            <ng-template #body let-s>
                <tr>
                    <td>
                        <div class="font-medium">{{ s.usuarioNome }}</div>
                        <div class="text-sm text-surface-500">{{ s.usuarioEmail }}</div>
                    </td>
                    <td class="text-sm">{{ data(s.iniciadaEm) }}</td>
                    <td class="text-sm">{{ s.encerradaEm ? data(s.encerradaEm) : '—' }}</td>
                    <td class="text-sm tabular-nums">{{ duracao(s.duracaoSegundos) }}</td>
                    <td class="text-sm" [pTooltip]="s.userAgent" tooltipPosition="top">{{ s.dispositivo || '—' }}</td>
                    <td class="text-sm font-mono">{{ s.ip || '—' }}</td>
                    <td>
                        @if (s.aberta) {
                            <p-tag [value]="s.online ? 'On-line' : 'Aberta (ausente)'" [severity]="s.online ? 'success' : 'info'" [rounded]="true" />
                        } @else {
                            <p-tag [value]="s.motivoDescricao" [severity]="cor(s.motivoEncerramento)" [rounded]="true" [pTooltip]="s.encerradaPor ? 'Por ' + s.encerradaPor : ''" />
                        }
                    </td>
                </tr>
            </ng-template>
            <ng-template #emptymessage>
                <tr><td colspan="7" class="text-center py-8 text-surface-500">Nenhum acesso no filtro escolhido.</td></tr>
            </ng-template>
        </p-table>
    `
})
export class VisitantesHistorico extends ListaPaginada<SessaoVisitante> {
    private api = inject(VisitantesService);
    private notify = inject(NotifyService);

    usuarios = input<VisitanteUsuario[]>([]);
    /** Filtro aplicado de fora (botão "Histórico" na aba Por usuário). */
    filtroUsuario = input<number | null>(null);

    usuarioId = signal<number | null>(null);
    situacao = signal<'' | 'ABERTA' | 'ENCERRADA'>('');
    periodo = signal<Date[] | null>(null);
    situacoes = [
        { label: 'Abertas', value: 'ABERTA' },
        { label: 'Encerradas', value: 'ENCERRADA' }
    ];
    data = dataHora;
    duracao = duracao;
    cor = corMotivo;

    constructor() {
        super();
        effect(() => {
            const id = this.filtroUsuario();
            untracked(() => {
                if (id !== null && id !== this.usuarioId()) {
                    this.usuarioId.set(id);
                    this.recarregarDoInicio();
                }
            });
        });
    }

    mudarPeriodo(v: Date[] | null): void {
        this.periodo.set(v);
        if (!v || (v[0] && v[1]) || v.length === 0) {
            this.recarregarDoInicio();
        }
    }

    protected consultar(q: ConsultaPagina) {
        const p = this.periodo();
        const de = p?.[0] ? new Date(p[0].getFullYear(), p[0].getMonth(), p[0].getDate()) : null;
        const fim = p?.[1] ?? p?.[0];
        const ate = fim ? new Date(fim.getFullYear(), fim.getMonth(), fim.getDate() + 1) : null;
        return this.api.acessos({ usuarioId: this.usuarioId(), busca: q.search, situacao: this.situacao(), de, ate }, Math.floor(q.offset / q.limit), q.limit);
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }
}
