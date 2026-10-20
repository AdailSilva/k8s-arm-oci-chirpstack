import { Component, effect, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { GatewayListItem } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { TenantContextService } from '@/app/core/tenant/tenant-context.service';
import { tempoRelativo } from '@/app/core/format/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/tabela/lista-paginada';
import { PageHeader } from '@/app/shared/visual/page-header';
import { StateTag } from '@/app/shared/visual/state-tag';

/**
 * Gateways do tenant selecionado.
 */
@Component({
    selector: 'app-gateway-list',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, IconFieldModule, InputIconModule, InputTextModule, SelectModule, TableModule, TooltipModule, PageHeader, StateTag],
    template: `
        <app-page-header title="Gateways" [subtitle]="'Concentradores LoRa conectados ao ChirpStack · ' + (ctx.tenant()?.name ?? 'sem tenant')" icon="pi pi-wifi">
            <p-button icon="pi pi-refresh" severity="secondary" [outlined]="true" (onClick)="carregar()" [loading]="carregando()" />
            @if (auth.podeEscrever()) {
                <p-button label="Novo gateway" icon="pi pi-plus" routerLink="/gateways/novo" [disabled]="!ctx.tenantId() || !ctx.tenant()?.canHaveGateways" />
            }
        </app-page-header>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" [lazyLoadOnInit]="false" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50, 100]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '60rem' }" [rowHover]="true">
                <ng-template #caption>
                    <div class="flex flex-wrap gap-2 justify-end">
                        <p-select [options]="ordens" optionLabel="label" optionValue="value" [ngModel]="ordem()" (ngModelChange)="ordem.set($event); recarregarDoInicio()" styleClass="w-60" />
                        <p-button [icon]="desc() ? 'pi pi-sort-amount-down' : 'pi pi-sort-amount-up-alt'" severity="secondary" [outlined]="true" (onClick)="desc.set(!desc()); recarregarDoInicio()" pTooltip="Inverter ordem" />
                        <p-iconfield>
                            <p-inputicon class="pi pi-search" />
                            <input pInputText type="text" placeholder="Nome ou Gateway ID" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" />
                        </p-iconfield>
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>Nome</th>
                        <th>Gateway ID</th>
                        <th>Estado</th>
                        <th>Visto por último</th>
                        <th>Localização</th>
                        <th class="w-28"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-g>
                    <tr>
                        <td>
                            <a [routerLink]="['/gateways', g.gatewayId]" class="font-medium text-primary hover:underline">{{ g.name }}</a>
                            @if (g.description) {
                                <div class="text-xs text-surface-500 truncate max-w-xs">{{ g.description }}</div>
                            }
                        </td>
                        <td class="font-mono">{{ g.gatewayId }}</td>
                        <td><app-state-tag [state]="g.state" /></td>
                        <td [title]="g.lastSeenAt ?? ''">{{ relativo(g.lastSeenAt) }}</td>
                        <td class="text-sm text-surface-500">
                            @if (g.location && (g.location.latitude || g.location.longitude)) {
                                <a [href]="'https://www.openstreetmap.org/?mlat=' + g.location.latitude + '&mlon=' + g.location.longitude + '#map=15/' + g.location.latitude + '/' + g.location.longitude" target="_blank" rel="noopener" class="hover:underline">
                                    <i class="pi pi-map-marker mr-1"></i>{{ g.location.latitude | number: '1.4-5' }}, {{ g.location.longitude | number: '1.4-5' }}
                                </a>
                            } @else {
                                —
                            }
                        </td>
                        <td class="text-right">
                            @if (auth.podeEscrever()) {
                                <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" [routerLink]="['/gateways', g.gatewayId, 'editar']" />
                                <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(g)" />
                            }
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="6" class="text-center py-8 text-surface-500">{{ ctx.tenantId() ? 'Nenhum gateway neste tenant.' : 'Selecione um tenant no topo da tela.' }}</td></tr>
                </ng-template>
            </p-table>
        </div>
    `
})
export class GatewayList extends ListaPaginada<GatewayListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    ctx = inject(TenantContextService);
    auth = inject(AuthService);

    ordem = signal('NAME');
    desc = signal(false);
    relativo = tempoRelativo;
    ordens = [
        { label: 'Ordenar por nome', value: 'NAME' },
        { label: 'Ordenar por Gateway ID', value: 'GATEWAY_ID' },
        { label: 'Ordenar por último contato', value: 'LAST_SEEN_AT' }
    ];

    constructor() {
        super();
        effect(() => {
            this.ctx.tenantId();
            this.recarregarDoInicio();
        });
    }

    protected consultar(q: ConsultaPagina) {
        const tenantId = this.ctx.tenantId();
        return tenantId ? this.api.listGateways({ ...q, tenantId, orderBy: this.ordem(), orderByDesc: this.desc() }) : null;
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e, 'Falha ao listar gateways');
    }

    excluir(g: GatewayListItem): void {
        this.notify.confirmarExclusao(`o gateway "${g.name}" (${g.gatewayId})`, () =>
            this.api.deleteGateway(g.gatewayId).subscribe({
                next: () => {
                    this.notify.sucesso('Gateway excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
