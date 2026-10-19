import { Component, computed, effect, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { SelectButtonModule } from 'primeng/selectbutton';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { DeviceProfileListItem } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { dataHora } from '@/app/core/util/format';
import { rotulo, VERSOES_MAC } from '@/app/core/util/options';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';

/** Escopo da listagem de perfis (4.19+): do tenant + globais, só do tenant ou só globais (catálogo). */
export type EscopoPerfil = 'todos' | 'tenant' | 'globais';

/**
 * Lista de perfis de dispositivo (do tenant e globais do catálogo) ou de templates de perfil, conforme {@code data.modo} da rota.
 * Aceita {@code ?modelo=<id do modelo do catálogo>&nomeModelo=...} para listar os perfis globais de um modelo.
 */
@Component({
    selector: 'app-device-profile-list',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, IconFieldModule, InputIconModule, InputTextModule, SelectButtonModule, TableModule, TagModule, TooltipModule, PageHeader],
    template: `
        <app-page-header [title]="template ? 'Templates de perfil' : 'Perfis de dispositivo'" [subtitle]="template ? 'Modelos globais para criar perfis de dispositivo rapidamente' : 'Configuração LoRaWAN dos dispositivos · ' + (ctx.tenant()?.name ?? 'sem tenant')" [icon]="template ? 'pi pi-copy' : 'pi pi-id-card'">
            @if (podeCriar()) {
                <p-button [label]="template ? 'Novo template' : 'Novo perfil'" icon="pi pi-plus" [routerLink]="['novo']" [disabled]="!template && !ctx.tenantId()" />
            }
        </app-page-header>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" [lazyLoadOnInit]="template" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '60rem' }" [rowHover]="true">
                <ng-template #caption>
                    <div class="flex justify-between items-center gap-3 flex-wrap">
                        <div class="flex items-center gap-3 flex-wrap">
                            <span class="text-surface-500 text-sm">{{ total() }} registro(s)</span>
                            @if (!template) {
                                @if (modelo(); as m) {
                                    <p-tag severity="info" icon="pi pi-box" [value]="'Modelo do catálogo: ' + m.nome" />
                                    <p-button label="Limpar" icon="pi pi-times" size="small" [text]="true" (onClick)="limparModelo()" />
                                } @else {
                                    <p-selectbutton [options]="escopos" [ngModel]="escopo()" (ngModelChange)="mudarEscopo($event)" optionLabel="label" optionValue="value" [allowEmpty]="false" size="small" />
                                }
                            }
                        </div>
                        @if (!template) {
                            <p-iconfield>
                                <p-inputicon class="pi pi-search" />
                                <input pInputText type="text" placeholder="Pesquisar por nome" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" />
                            </p-iconfield>
                        }
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>Nome</th>
                        <th>Fabricante</th>
                        @if (!template) {
                            <th>Modelo</th>
                        }
                        <th>Firmware</th>
                        <th>Região</th>
                        <th>Versão MAC</th>
                        <th>Rev. parâmetros</th>
                        <th>Recursos</th>
                        <th>Atualizado em</th>
                        <th class="w-28"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-p>
                    <tr>
                        <td>
                            <a [routerLink]="[p.id]" class="font-medium text-primary hover:underline">{{ p.name }}</a>
                            @if (ehGlobal(p)) {
                                <p-tag value="Global" severity="contrast" class="ml-2" pTooltip="Perfil global do catálogo, compartilhado por todos os tenants" />
                            }
                        </td>
                        @if (template) {
                            <td>{{ p.vendor }}</td>
                            <td>{{ p.firmware }}</td>
                        } @else {
                            <td>{{ p.vendorName || '—' }}</td>
                            <td>{{ p.deviceName || '—' }}</td>
                            <td>{{ p.firmwareVersion || '—' }}</td>
                        }
                        <td>{{ p.region }}</td>
                        <td>{{ mac(p.macVersion) }}</td>
                        <td>{{ p.regParamsRevision }}</td>
                        <td>
                            <p-tag [value]="p.supportsOtaa ? 'OTAA' : 'ABP'" severity="secondary" class="mr-1" />
                            @if (p.supportsClassB) {
                                <p-tag value="Classe B" severity="info" class="mr-1" />
                            }
                            @if (p.supportsClassC) {
                                <p-tag value="Classe C" severity="info" />
                            }
                        </td>
                        <td>{{ data(p.updatedAt) }}</td>
                        <td class="text-right">
                            <p-button [icon]="podeAlterar(p) ? 'pi pi-pencil' : 'pi pi-eye'" [text]="true" [rounded]="true" [routerLink]="[p.id]" />
                            @if (podeAlterar(p)) {
                                <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(p)" />
                            }
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td [attr.colspan]="template ? 9 : 10" class="text-center py-8 text-surface-500">Nenhum registro.</td></tr>
                </ng-template>
            </p-table>
        </div>
    `
})
export class DeviceProfileList extends ListaPaginada<DeviceProfileListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private route = inject(ActivatedRoute);
    ctx = inject(TenantContextService);
    auth = inject(AuthService);

    private router = inject(Router);

    readonly template = this.route.snapshot.data['modo'] === 'template';
    podeCriar = computed(() => (this.template ? this.auth.isAdmin() : this.auth.podeEscrever()));
    data = dataHora;

    readonly escopos = [
        { label: 'Tenant + globais', value: 'todos' as EscopoPerfil },
        { label: 'Só do tenant', value: 'tenant' as EscopoPerfil },
        { label: 'Só globais', value: 'globais' as EscopoPerfil }
    ];
    escopo = signal<EscopoPerfil>('todos');
    /** Filtro por modelo do catálogo (vem da tela Catálogo de dispositivos). */
    modelo = signal<{ id: string; nome: string } | null>(null);

    constructor() {
        super();
        const qp = this.route.snapshot.queryParamMap;
        const m = qp.get('modelo');
        if (m) {
            this.modelo.set({ id: m, nome: qp.get('nomeModelo') ?? m });
        }
        if (!this.template) {
            effect(() => {
                this.ctx.tenantId();
                this.recarregarDoInicio();
            });
        }
    }

    mac(v: string): string {
        return rotulo(VERSOES_MAC, v);
    }

    protected consultar(q: ConsultaPagina) {
        if (this.template) {
            return this.api.listDeviceProfileTemplates({ limit: q.limit, offset: q.offset });
        }
        const modelo = this.modelo();
        if (modelo) {
            return this.api.listDeviceProfiles({ ...q, deviceId: modelo.id, globalOnly: true });
        }
        const escopo = this.escopo();
        if (escopo === 'globais') {
            return this.api.listDeviceProfiles({ ...q, globalOnly: true });
        }
        const tenantId = this.ctx.tenantId();
        return tenantId ? this.api.listDeviceProfiles({ ...q, tenantId, tenantOnly: escopo === 'tenant' ? true : undefined }) : null;
    }

    mudarEscopo(e: EscopoPerfil): void {
        this.escopo.set(e);
        this.recarregarDoInicio();
    }

    limparModelo(): void {
        this.modelo.set(null);
        this.router.navigate([], { relativeTo: this.route, queryParams: {} });
        this.recarregarDoInicio();
    }

    /**
     * Perfil global (listado em "Só globais" ou por modelo do catálogo). O item da lista não traz o
     * tenant, então em "Tenant + globais" a marcação aparece no detalhe do perfil.
     */
    ehGlobal(_p: DeviceProfileListItem): boolean {
        return !this.template && (this.escopo() === 'globais' || !!this.modelo());
    }

    /** Perfis globais valem para todos os tenants: só o ADMIN altera ou exclui. */
    podeAlterar(p: DeviceProfileListItem): boolean {
        return this.ehGlobal(p) ? this.auth.isAdmin() : this.podeCriar();
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    excluir(p: DeviceProfileListItem): void {
        this.notify.confirmarExclusao(`${this.template ? 'o template' : 'o perfil'} "${p.name}"`, () => {
            const op = this.template ? this.api.deleteDeviceProfileTemplate(p.id) : this.api.deleteDeviceProfile(p.id);
            op.subscribe({
                next: () => {
                    this.notify.sucesso('Excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            });
        }, this.template ? undefined : 'Não é possível excluir um perfil em uso por dispositivos.');
    }
}
