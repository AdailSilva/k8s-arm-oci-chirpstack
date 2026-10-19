import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { MessageModule } from 'primeng/message';
import { TableLazyLoadEvent, TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { DeviceProfileDeviceListItem, DeviceProfileVendorListItem, Tags } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora, num } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';

interface Detalhe {
    titulo: string;
    campos: [string, string][];
    metadata: [string, string][];
}

/**
 * Catálogo de dispositivos do ChirpStack (4.19+): fabricantes (LoRa Alliance Vendor ID) e modelos,
 * importados com {@code chirpstack import-device-profiles -d <repositório>}. Cada modelo tem perfis de dispositivo
 * globais, compartilhados por todos os tenants. Consulta para todos; exclusão só para o ADMIN.
 */
@Component({
    selector: 'app-catalogo-dispositivos',
    standalone: true,
    imports: [CommonModule, RouterModule, ButtonModule, DialogModule, MessageModule, TableModule, TagModule, TooltipModule, PageHeader],
    template: `
        <app-page-header title="Catálogo de dispositivos" subtitle="Fabricantes e modelos importados no ChirpStack, com perfis globais para todos os tenants" icon="pi pi-box" />

        <div class="grid grid-cols-12 gap-6">
            <div class="col-span-12 xl:col-span-6">
                <div class="card mb-0!">
                    <div class="font-semibold text-lg mb-4">Fabricantes</div>
                    <p-table [value]="itens()" [lazy]="true" [lazyLoadOnInit]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" selectionMode="single" [selection]="fabricante()" (onRowSelect)="selecionar($any($event.data))" dataKey="id" [rowHover]="true">
                        <ng-template #header>
                            <tr>
                                <th>Nome</th>
                                <th>Vendor ID</th>
                                <th>OUIs</th>
                                <th class="w-28"></th>
                            </tr>
                        </ng-template>
                        <ng-template #body let-v>
                            <tr [pSelectableRow]="v" class="cursor-pointer">
                                <td class="font-medium">{{ v.name }}</td>
                                <td class="font-mono">{{ v.vendorId }} <span class="text-surface-500">({{ hex(v.vendorId) }})</span></td>
                                <td>
                                    @for (o of (v.ouis ?? []).slice(0, 3); track o) {
                                        <p-tag [value]="o" severity="secondary" styleClass="font-mono mr-1" />
                                    }
                                    @if ((v.ouis ?? []).length > 3) {
                                        <span class="text-surface-500 text-sm">+{{ v.ouis.length - 3 }}</span>
                                    }
                                </td>
                                <td class="text-right" (click)="$event.stopPropagation()">
                                    <p-button icon="pi pi-info-circle" [text]="true" [rounded]="true" pTooltip="Detalhes" (onClick)="detalharFabricante(v)" />
                                    @if (auth.isAdmin()) {
                                        <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluirFabricante(v)" />
                                    }
                                </td>
                            </tr>
                        </ng-template>
                        <ng-template #emptymessage>
                            <tr>
                                <td colspan="4" class="text-center py-8 text-surface-500">
                                    Catálogo vazio. Importe o repositório de perfis no servidor do ChirpStack: <code>chirpstack -c /etc/chirpstack import-device-profiles -d &lt;pasta do lorawan-device-profiles&gt;</code>.
                                </td>
                            </tr>
                        </ng-template>
                    </p-table>
                </div>
            </div>

            <div class="col-span-12 xl:col-span-6">
                <div class="card mb-0!">
                    <div class="font-semibold text-lg mb-4">
                        Modelos
                        @if (fabricante(); as f) {
                            <span class="text-surface-500 font-normal">· {{ f.name }}</span>
                        }
                    </div>
                    @if (!fabricante()) {
                        <p-message severity="info" text="Selecione um fabricante para ver os modelos." styleClass="w-full" />
                    } @else {
                        <p-table [value]="modelos()" [lazy]="true" (onLazyLoad)="onLazyModelos($event)" [paginator]="true" [rows]="rowsModelos()" [first]="firstModelos()" [totalRecords]="totalModelos()" [loading]="carregandoModelos()" [rowsPerPageOptions]="[10, 20, 50]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [rowHover]="true">
                            <ng-template #header>
                                <tr>
                                    <th>Modelo</th>
                                    <th>Atualizado em</th>
                                    <th class="w-44"></th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-d>
                                <tr>
                                    <td class="font-medium">{{ d.name }}</td>
                                    <td>{{ data(d.updatedAt) }}</td>
                                    <td class="text-right whitespace-nowrap">
                                        <p-button icon="pi pi-id-card" [text]="true" [rounded]="true" pTooltip="Perfis deste modelo" (onClick)="verPerfis(d)" />
                                        <p-button icon="pi pi-info-circle" [text]="true" [rounded]="true" pTooltip="Detalhes" (onClick)="detalharModelo(d)" />
                                        @if (auth.isAdmin()) {
                                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluirModelo(d)" />
                                        }
                                    </td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage>
                                <tr><td colspan="3" class="text-center py-8 text-surface-500">Nenhum modelo para este fabricante.</td></tr>
                            </ng-template>
                        </p-table>
                    }
                </div>
            </div>
        </div>

        <p-dialog [visible]="!!detalhe()" (visibleChange)="!$event && detalhe.set(null)" [header]="detalhe()?.titulo ?? ''" [modal]="true" [style]="{ width: '42rem' }" [breakpoints]="{ '768px': '95vw' }">
            @if (detalhe(); as d) {
                <div class="flex flex-col gap-2">
                    @for (c of d.campos; track c[0]) {
                        <div class="grid grid-cols-3 gap-2"><span class="text-surface-500">{{ c[0] }}</span><span class="col-span-2 break-all">{{ c[1] || '—' }}</span></div>
                    }
                    <div class="font-semibold mt-3">Metadados</div>
                    @for (m of d.metadata; track m[0]) {
                        <div class="grid grid-cols-3 gap-2 text-sm"><span class="font-mono text-surface-500 break-all">{{ m[0] }}</span><span class="col-span-2 break-all">{{ m[1] }}</span></div>
                    } @empty {
                        <span class="text-surface-500 text-sm">Sem metadados.</span>
                    }
                </div>
            }
        </p-dialog>
    `
})
export class CatalogoDispositivos extends ListaPaginada<DeviceProfileVendorListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    auth = inject(AuthService);
    data = dataHora;

    fabricante = signal<DeviceProfileVendorListItem | null>(null);
    modelos = signal<DeviceProfileDeviceListItem[]>([]);
    totalModelos = signal(0);
    firstModelos = signal(0);
    rowsModelos = signal(20);
    carregandoModelos = signal(false);
    detalhe = signal<Detalhe | null>(null);

    protected consultar(q: ConsultaPagina) {
        return this.api.listDeviceProfileVendors({ limit: q.limit, offset: q.offset });
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e, 'Falha ao listar o catálogo (requer ChirpStack 4.19 ou superior)');
    }

    hex(v: number | string): string {
        return '0x' + num(v).toString(16).toUpperCase().padStart(8, '0');
    }

    selecionar(v: DeviceProfileVendorListItem): void {
        this.fabricante.set(v);
        this.firstModelos.set(0);
        this.carregarModelos();
    }

    onLazyModelos(e: TableLazyLoadEvent): void {
        this.firstModelos.set(e.first ?? 0);
        this.rowsModelos.set(e.rows ?? 20);
        this.carregarModelos();
    }

    private carregarModelos(): void {
        const f = this.fabricante();
        if (!f) {
            return;
        }
        this.carregandoModelos.set(true);
        this.api.listDeviceProfileDevices(f.id, { limit: this.rowsModelos(), offset: this.firstModelos() }).subscribe({
            next: (r) => {
                this.modelos.set(r.result ?? []);
                this.totalModelos.set(num(r.totalCount));
                this.carregandoModelos.set(false);
            },
            error: (e) => {
                this.carregandoModelos.set(false);
                this.notify.erro(e);
            }
        });
    }

    private static meta(m?: Tags): [string, string][] {
        return Object.entries(m ?? {}).sort((a, b) => a[0].localeCompare(b[0]));
    }

    detalharFabricante(v: DeviceProfileVendorListItem): void {
        this.api.getDeviceProfileVendor(v.id).subscribe({
            next: (r) =>
                this.detalhe.set({
                    titulo: `Fabricante · ${r.vendor.name}`,
                    campos: [
                        ['ID', r.vendor.id],
                        ['Vendor ID (LoRa Alliance)', `${r.vendor.vendorId} (${this.hex(r.vendor.vendorId)})`],
                        ['OUIs', (r.vendor.ouis ?? []).join(', ')],
                        ['Criado em', dataHora(r.createdAt)],
                        ['Atualizado em', dataHora(r.updatedAt)]
                    ],
                    metadata: CatalogoDispositivos.meta(r.vendor.metadata)
                }),
            error: (e) => this.notify.erro(e)
        });
    }

    detalharModelo(d: DeviceProfileDeviceListItem): void {
        this.api.getDeviceProfileDevice(d.id).subscribe({
            next: (r) =>
                this.detalhe.set({
                    titulo: `Modelo · ${r.device.name}`,
                    campos: [
                        ['ID', r.device.id],
                        ['Fabricante', this.fabricante()?.name ?? r.device.vendorId],
                        ['Descrição', r.device.description],
                        ['Criado em', dataHora(r.createdAt)],
                        ['Atualizado em', dataHora(r.updatedAt)]
                    ],
                    metadata: CatalogoDispositivos.meta(r.device.metadata)
                }),
            error: (e) => this.notify.erro(e)
        });
    }

    verPerfis(d: DeviceProfileDeviceListItem): void {
        const nome = `${this.fabricante()?.name ?? ''} ${d.name}`.trim();
        this.router.navigate(['/perfis-dispositivo'], { queryParams: { modelo: d.id, nomeModelo: nome } });
    }

    excluirFabricante(v: DeviceProfileVendorListItem): void {
        this.notify.confirmarExclusao(`o fabricante "${v.name}" do catálogo`, () =>
            this.api.deleteDeviceProfileVendor(v.id).subscribe({
                next: () => {
                    this.notify.sucesso('Fabricante excluído.');
                    if (this.fabricante()?.id === v.id) {
                        this.fabricante.set(null);
                    }
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Também exclui os modelos do fabricante e os perfis globais deles. Falha se algum dispositivo usar um desses perfis. Uma nova importação recria o fabricante.'
        );
    }

    excluirModelo(d: DeviceProfileDeviceListItem): void {
        this.notify.confirmarExclusao(`o modelo "${d.name}" do catálogo`, () =>
            this.api.deleteDeviceProfileDevice(d.id).subscribe({
                next: () => {
                    this.notify.sucesso('Modelo excluído.');
                    this.carregarModelos();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Também exclui os perfis globais deste modelo. Falha se algum dispositivo usar um desses perfis. Uma nova importação recria o modelo.'
        );
    }
}
