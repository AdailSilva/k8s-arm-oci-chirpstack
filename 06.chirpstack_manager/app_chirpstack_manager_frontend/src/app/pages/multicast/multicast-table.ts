import { Component, effect, inject, input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { MulticastGroupListItem } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { TenantContextService } from '@/app/core/tenant/tenant-context.service';
import { dataHora } from '@/app/core/format/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/tabela/lista-paginada';

/**
 * Grupos multicast. Três usos (4.19+):
 * <ul>
 *   <li>com {@code applicationId}: grupos da aplicação;</li>
 *   <li>com {@code applicationId} e {@code devEui}: grupos de que o dispositivo participa;</li>
 *   <li>sem {@code applicationId}: todos os grupos do tenant selecionado, com a coluna Aplicação.</li>
 * </ul>
 */
@Component({
    selector: 'app-multicast-table',
    standalone: true,
    imports: [CommonModule, RouterModule, ButtonModule, TableModule, TagModule, TooltipModule],
    template: `
        <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [tableStyle]="{ 'min-width': '45rem' }" [rowHover]="true">
            <ng-template #caption>
                <div class="flex justify-between items-center">
                    <span class="text-surface-500 text-sm">{{ devEui() ? 'Grupos multicast de que este dispositivo participa.' : 'Downlinks enviados a vários dispositivos ao mesmo tempo (classe B ou C).' }}</span>
                    @if (auth.podeEscrever() && applicationId() && !devEui()) {
                        <p-button label="Novo grupo" icon="pi pi-plus" [routerLink]="['/aplicacoes', applicationId(), 'multicast', 'novo']" />
                    }
                </div>
            </ng-template>
            <ng-template #header>
                <tr>
                    <th>Nome</th>
                    @if (!applicationId()) {
                        <th>Aplicação</th>
                    }
                    <th>Região</th>
                    <th>Tipo</th>
                    <th>Criado em</th>
                    <th class="w-28"></th>
                </tr>
            </ng-template>
            <ng-template #body let-g>
                <tr>
                    <td><a [routerLink]="['/aplicacoes', app(g), 'multicast', g.id]" class="font-medium text-primary hover:underline">{{ g.name }}</a></td>
                    @if (!applicationId()) {
                        <td><a [routerLink]="['/aplicacoes', g.applicationId]" class="hover:underline">{{ g.applicationName || g.applicationId }}</a></td>
                    }
                    <td>{{ g.region }}</td>
                    <td><p-tag [value]="g.groupType === 'CLASS_B' ? 'Classe B' : 'Classe C'" severity="secondary" /></td>
                    <td>{{ data(g.createdAt) }}</td>
                    <td class="text-right">
                        @if (auth.podeEscrever()) {
                            <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" [routerLink]="['/aplicacoes', app(g), 'multicast', g.id, 'editar']" />
                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(g)" />
                        }
                    </td>
                </tr>
            </ng-template>
            <ng-template #emptymessage>
                <tr><td [attr.colspan]="applicationId() ? 5 : 6" class="text-center py-8 text-surface-500">Nenhum grupo multicast.</td></tr>
            </ng-template>
        </p-table>
    `
})
export class MulticastTable extends ListaPaginada<MulticastGroupListItem> {
    applicationId = input<string>();
    devEui = input<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private ctx = inject(TenantContextService);
    auth = inject(AuthService);
    data = dataHora;

    constructor() {
        super();
        // Listagem por tenant acompanha a troca de tenant no topo.
        effect(() => {
            this.ctx.tenantId();
            if (!this.applicationId()) {
                this.recarregarDoInicio();
            }
        });
    }

    app(g: MulticastGroupListItem): string | undefined {
        return this.applicationId() || g.applicationId;
    }

    protected consultar(q: ConsultaPagina) {
        const applicationId = this.applicationId();
        if (applicationId) {
            return this.api.listMulticastGroups({ ...q, applicationId, devEui: this.devEui() });
        }
        const tenantId = this.ctx.tenantId();
        return tenantId ? this.api.listMulticastGroups({ ...q, tenantId }) : null;
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    excluir(g: MulticastGroupListItem): void {
        this.notify.confirmarExclusao(`o grupo multicast "${g.name}"`, () =>
            this.api.deleteMulticastGroup(g.id).subscribe({
                next: () => {
                    this.notify.sucesso('Grupo excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
