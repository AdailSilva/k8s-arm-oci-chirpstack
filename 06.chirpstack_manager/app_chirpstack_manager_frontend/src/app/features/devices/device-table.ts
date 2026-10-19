import { Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { DeviceListItem } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { tempoRelativo } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';

/**
 * Dispositivos de uma aplicação (aba da tela da aplicação).
 */
@Component({
    selector: 'app-device-table',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, IconFieldModule, InputIconModule, InputTextModule, SelectModule, TableModule, TagModule, TooltipModule],
    template: `
        <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50, 100]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '60rem' }" [rowHover]="true">
            <ng-template #caption>
                <div class="flex flex-wrap gap-3 items-center justify-between">
                    <div class="flex flex-wrap gap-2 items-center">
                        <p-iconfield>
                            <p-inputicon class="pi pi-search" />
                            <input pInputText type="text" placeholder="Nome ou DevEUI" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" />
                        </p-iconfield>
                        <p-select [options]="ordens" optionLabel="label" optionValue="value" [ngModel]="ordem()" (ngModelChange)="ordem.set($event); recarregarDoInicio()" styleClass="w-56" />
                        <p-button [icon]="desc() ? 'pi pi-sort-amount-down' : 'pi pi-sort-amount-up-alt'" severity="secondary" [outlined]="true" (onClick)="desc.set(!desc()); recarregarDoInicio()" pTooltip="Inverter ordem" />
                        @if (tagsDisponiveis().length) {
                            <p-select [options]="chavesTag()" [ngModel]="chaveTag()" (ngModelChange)="chaveTag.set($event)" placeholder="Tag" [showClear]="true" styleClass="w-40" />
                            <p-select [options]="valoresTag()" [ngModel]="valorTag()" (ngModelChange)="valorTag.set($event)" placeholder="Valor" [disabled]="!chaveTag()" [filter]="true" styleClass="w-40" />
                            <p-button icon="pi pi-filter" severity="secondary" [outlined]="true" pTooltip="Filtrar pela tag" [disabled]="!chaveTag() || !valorTag()" (onClick)="adicionarFiltroTag()" />
                        }
                        @for (f of filtrosTag(); track f) {
                            <p-tag [value]="f" severity="info" icon="pi pi-tag" class="cursor-pointer" pTooltip="Remover filtro" (click)="removerFiltroTag(f)" />
                        }
                    </div>
                    @if (auth.podeEscrever()) {
                        <p-button label="Novo dispositivo" icon="pi pi-plus" [routerLink]="['/aplicacoes', applicationId(), 'dispositivos', 'novo']" />
                    }
                </div>
            </ng-template>
            <ng-template #header>
                <tr>
                    <th>Nome</th>
                    <th>DevEUI</th>
                    <th>Perfil</th>
                    <th>Bateria</th>
                    <th>Margem</th>
                    <th>Visto por último</th>
                    <th class="w-28"></th>
                </tr>
            </ng-template>
            <ng-template #body let-d>
                <tr>
                    <td>
                        <a [routerLink]="['/aplicacoes', applicationId(), 'dispositivos', d.devEui]" class="font-medium text-primary hover:underline">{{ d.name }}</a>
                        @if (d.description) {
                            <div class="text-xs text-surface-500 truncate max-w-xs">{{ d.description }}</div>
                        }
                    </td>
                    <td class="font-mono">{{ d.devEui }}</td>
                    <td>{{ d.deviceProfileName }}</td>
                    <td>
                        @if (d.deviceStatus) {
                            @if (d.deviceStatus.externalPowerSource) {
                                <p-tag value="Externa" icon="pi pi-bolt" severity="info" />
                            } @else if (d.deviceStatus.batteryLevel >= 0) {
                                <span>{{ d.deviceStatus.batteryLevel | number: '1.0-0' }}%</span>
                            }
                        } @else {
                            <span class="text-surface-400">—</span>
                        }
                    </td>
                    <td>{{ d.deviceStatus ? d.deviceStatus.margin + ' dB' : '—' }}</td>
                    <td>
                        <span [title]="d.lastSeenAt ?? ''" [class]="ativo(d) ? 'text-green-600 dark:text-green-400' : 'text-surface-500'">
                            <i class="pi pi-circle-fill text-[0.5rem]! mr-1" [class.text-green-500]="ativo(d)" [class.text-surface-300]="!ativo(d)"></i>{{ relativo(d.lastSeenAt) }}
                        </span>
                    </td>
                    <td class="text-right">
                        @if (auth.podeEscrever()) {
                            <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" [routerLink]="['/aplicacoes', applicationId(), 'dispositivos', d.devEui, 'editar']" />
                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(d)" />
                        }
                    </td>
                </tr>
            </ng-template>
            <ng-template #emptymessage>
                <tr><td colspan="7" class="text-center py-8 text-surface-500">Nenhum dispositivo.</td></tr>
            </ng-template>
        </p-table>
    `
})
export class DeviceTable extends ListaPaginada<DeviceListItem> implements OnInit {
    applicationId = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);

    ordem = signal('NAME');
    desc = signal(false);
    relativo = tempoRelativo;
    ordens = [
        { label: 'Ordenar por nome', value: 'NAME' },
        { label: 'Ordenar por DevEUI', value: 'DEV_EUI' },
        { label: 'Ordenar por último contato', value: 'LAST_SEEN_AT' },
        { label: 'Ordenar por perfil', value: 'DEVICE_PROFILE_NAME' }
    ];

    /** Filtro por tags (4.19+): chave=valor, todas precisam bater. */
    tagsDisponiveis = signal<{ key: string; values: string[] }[]>([]);
    filtrosTag = signal<string[]>([]);
    chaveTag = signal<string | null>(null);
    valorTag = signal<string | null>(null);
    chavesTag = computed(() => this.tagsDisponiveis().map((t) => t.key));
    valoresTag = computed(() => this.tagsDisponiveis().find((t) => t.key === this.chaveTag())?.values ?? []);

    ngOnInit(): void {
        this.api.listApplicationDeviceTags(this.applicationId()).subscribe({
            next: (r) => this.tagsDisponiveis.set((r.result ?? []).filter((t) => /^[A-Za-z0-9 _.:-]{1,64}$/.test(t.key)))
        });
    }

    adicionarFiltroTag(): void {
        const f = `${this.chaveTag()}=${this.valorTag()}`;
        // Uma condição por chave: trocar o valor substitui o filtro anterior da mesma tag.
        this.filtrosTag.update((l) => [...l.filter((x) => !x.startsWith(this.chaveTag() + '=')), f]);
        this.valorTag.set(null);
        this.recarregarDoInicio();
    }

    removerFiltroTag(f: string): void {
        this.filtrosTag.update((l) => l.filter((x) => x !== f));
        this.recarregarDoInicio();
    }

    protected consultar(q: ConsultaPagina) {
        return this.api.listDevices({ ...q, applicationId: this.applicationId(), orderBy: this.ordem(), orderByDesc: this.desc(), tag: this.filtrosTag() });
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e, 'Falha ao listar dispositivos');
    }

    ativo(d: DeviceListItem): boolean {
        return !!d.lastSeenAt && Date.now() - new Date(d.lastSeenAt).getTime() < 86_400_000;
    }

    excluir(d: DeviceListItem): void {
        this.notify.confirmarExclusao(`o dispositivo "${d.name}" (${d.devEui})`, () =>
            this.api.deleteDevice(d.devEui).subscribe({
                next: () => {
                    this.notify.sucesso('Dispositivo excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
