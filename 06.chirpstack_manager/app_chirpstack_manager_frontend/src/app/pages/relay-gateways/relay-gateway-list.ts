import { Component, effect, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { MessageModule } from 'primeng/message';
import { TableModule } from 'primeng/table';
import { TextareaModule } from 'primeng/textarea';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { RelayGateway, RelayGatewayListItem } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { TenantContextService } from '@/app/core/tenant/tenant-context.service';
import { num, tempoRelativo } from '@/app/core/format/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/tabela/lista-paginada';
import { PageHeader } from '@/app/shared/visual/page-header';
import { StateTag } from '@/app/shared/visual/state-tag';

/**
 * Relay gateways (dispositivos relay TS011 detectados pelo ChirpStack).
 * São criados automaticamente; aqui se ajusta nome, descrição e parâmetros, ou se exclui.
 */
@Component({
    selector: 'app-relay-gateway-list',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, DialogModule, InputNumberModule, InputTextModule, MessageModule, TableModule, TextareaModule, TooltipModule, PageHeader, StateTag],
    template: `
        <app-page-header title="Relay gateways" [subtitle]="'Relays LoRaWAN (TS011) detectados · ' + (ctx.tenant()?.name ?? 'sem tenant')" icon="pi pi-share-alt" />

        <p-message severity="info" styleClass="mb-4 w-full" text="Relay gateways aparecem automaticamente quando um dispositivo com perfil de relay encaminha tráfego. Não há cadastro manual." />

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" [lazyLoadOnInit]="false" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [tableStyle]="{ 'min-width': '50rem' }" [rowHover]="true">
                <ng-template #header>
                    <tr>
                        <th>Nome</th>
                        <th>Relay ID</th>
                        <th>Estado</th>
                        <th>Região</th>
                        <th>Visto por último</th>
                        <th class="w-28"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-r>
                    <tr>
                        <td class="font-medium">{{ r.name || '—' }}</td>
                        <td class="font-mono">{{ r.relayId }}</td>
                        <td><app-state-tag [state]="r.state" /></td>
                        <td>{{ r.regionConfigId || '—' }}</td>
                        <td>{{ relativo(r.lastSeenAt) }}</td>
                        <td class="text-right">
                            @if (auth.podeEscrever()) {
                                <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" (onClick)="editar(r)" />
                                <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(r)" />
                            }
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="6" class="text-center py-8 text-surface-500">Nenhum relay gateway detectado.</td></tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogo" header="Editar relay gateway" [modal]="true" [style]="{ width: '36rem' }">
            <div class="flex flex-col gap-5">
                <div><span class="text-surface-500">Relay ID:</span> <b class="font-mono">{{ form.relayId }}</b></div>
                <div>
                    <label class="block font-medium mb-2">Nome</label>
                    <input pInputText class="w-full" [(ngModel)]="form.name" />
                </div>
                <div>
                    <label class="block font-medium mb-2">Descrição</label>
                    <textarea pTextarea class="w-full" rows="2" [(ngModel)]="form.description"></textarea>
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block font-medium mb-2">Intervalo de estatísticas (s)</label>
                        <p-inputnumber [(ngModel)]="form.statsInterval" [min]="1" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Configuração da região</label>
                        <input pInputText class="w-full" [(ngModel)]="form.regionConfigId" />
                    </div>
                </div>
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" />
            </ng-template>
        </p-dialog>
    `
})
export class RelayGatewayList extends ListaPaginada<RelayGatewayListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    ctx = inject(TenantContextService);
    auth = inject(AuthService);

    dialogo = signal(false);
    form: RelayGateway = { tenantId: '', relayId: '', name: '', description: '', statsInterval: 30, regionConfigId: '' };
    relativo = tempoRelativo;

    constructor() {
        super();
        effect(() => {
            this.ctx.tenantId();
            this.recarregarDoInicio();
        });
    }

    protected consultar(q: ConsultaPagina) {
        const tenantId = this.ctx.tenantId();
        return tenantId ? this.api.listRelayGateways({ limit: q.limit, offset: q.offset, tenantId }) : null;
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    editar(r: RelayGatewayListItem): void {
        this.form = { tenantId: r.tenantId, relayId: r.relayId, name: r.name, description: r.description, statsInterval: num(r.statsInterval, 30), regionConfigId: r.regionConfigId };
        this.dialogo.set(true);
    }

    salvar(): void {
        this.api.updateRelayGateway(this.form.tenantId, this.form.relayId, this.form).subscribe({
            next: () => {
                this.dialogo.set(false);
                this.notify.sucesso('Relay gateway atualizado.');
                this.carregar();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    excluir(r: RelayGatewayListItem): void {
        this.notify.confirmarExclusao(`o relay gateway ${r.relayId}`, () =>
            this.api.deleteRelayGateway(r.tenantId, r.relayId).subscribe({
                next: () => {
                    this.notify.sucesso('Relay gateway excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
