import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TabsModule } from 'primeng/tabs';
import { TagModule } from 'primeng/tag';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { DeviceListItem, GatewayListItem, GetMulticastGroupResponse, MulticastGroupQueueItem } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { base64ParaHex, dataHora, hexParaBase64, num } from '@/app/core/format/format';
import { PageHeader } from '@/app/shared/visual/page-header';
import { StateTag } from '@/app/shared/visual/state-tag';

/**
 * Grupo multicast: membros (dispositivos e gateways) e fila de downlink.
 */
@Component({
    selector: 'app-multicast-detail',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, InputNumberModule, InputTextModule, SelectModule, TableModule, TabsModule, TagModule, PageHeader, StateTag],
    template: `
        <app-page-header [title]="grupo()?.multicastGroup?.name ?? 'Grupo multicast'" [subtitle]="resumo()" icon="pi pi-sitemap">
            <p-button label="Aplicação" icon="pi pi-arrow-left" severity="secondary" [outlined]="true" [routerLink]="['/aplicacoes', applicationId()]" [queryParams]="{ aba: 'multicast' }" />
            @if (auth.podeEscrever()) {
                <p-button label="Editar" icon="pi pi-pencil" severity="secondary" [routerLink]="['/aplicacoes', applicationId(), 'multicast', id(), 'editar']" />
            }
        </app-page-header>

        <div class="card">
            <p-tabs value="dispositivos">
                <p-tablist>
                    <p-tab value="dispositivos"><i class="pi pi-microchip mr-2"></i>Dispositivos ({{ dispositivos().length }})</p-tab>
                    <p-tab value="gateways"><i class="pi pi-wifi mr-2"></i>Gateways ({{ gateways().length }})</p-tab>
                    <p-tab value="fila"><i class="pi pi-send mr-2"></i>Fila</p-tab>
                </p-tablist>
                <p-tabpanels>
                    <p-tabpanel value="dispositivos">
                        @if (auth.podeEscrever()) {
                            <div class="flex gap-2 mb-4">
                                <p-select [options]="dispositivosDisponiveis()" optionLabel="name" optionValue="devEui" [(ngModel)]="novoDispositivo" [filter]="true" filterBy="name,devEui" placeholder="Adicionar dispositivo da aplicação" styleClass="w-full md:w-96" />
                                <p-button label="Adicionar" icon="pi pi-plus" (onClick)="adicionarDispositivo()" [disabled]="!novoDispositivo" />
                            </div>
                        }
                        <p-table [value]="dispositivos()" [paginator]="dispositivos().length > 10" [rows]="10">
                            <ng-template #header><tr><th>Nome</th><th>DevEUI</th><th>Perfil</th><th class="w-20"></th></tr></ng-template>
                            <ng-template #body let-d>
                                <tr>
                                    <td><a [routerLink]="['/aplicacoes', applicationId(), 'dispositivos', d.devEui]" class="text-primary hover:underline">{{ d.name }}</a></td>
                                    <td class="font-mono">{{ d.devEui }}</td>
                                    <td>{{ d.deviceProfileName }}</td>
                                    <td>
                                        @if (auth.podeEscrever()) {
                                            <p-button icon="pi pi-times" severity="danger" [text]="true" [rounded]="true" (onClick)="removerDispositivo(d)" />
                                        }
                                    </td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage><tr><td colspan="4" class="text-center py-6 text-surface-500">Nenhum dispositivo no grupo.</td></tr></ng-template>
                        </p-table>
                    </p-tabpanel>
                    <p-tabpanel value="gateways">
                        <p class="text-surface-500 text-sm mt-0">Sem gateways no grupo, o ChirpStack escolhe automaticamente os que cobrem os dispositivos.</p>
                        @if (auth.podeEscrever()) {
                            <div class="flex gap-2 mb-4">
                                <p-select [options]="gatewaysDisponiveis()" optionLabel="name" optionValue="gatewayId" [(ngModel)]="novoGateway" [filter]="true" filterBy="name,gatewayId" placeholder="Adicionar gateway do tenant" styleClass="w-full md:w-96" />
                                <p-button label="Adicionar" icon="pi pi-plus" (onClick)="adicionarGateway()" [disabled]="!novoGateway" />
                            </div>
                        }
                        <p-table [value]="gateways()">
                            <ng-template #header><tr><th>Nome</th><th>Gateway ID</th><th>Estado</th><th class="w-20"></th></tr></ng-template>
                            <ng-template #body let-g>
                                <tr>
                                    <td>{{ g.name }}</td>
                                    <td class="font-mono">{{ g.gatewayId }}</td>
                                    <td><app-state-tag [state]="g.state" /></td>
                                    <td>
                                        @if (auth.podeEscrever()) {
                                            <p-button icon="pi pi-times" severity="danger" [text]="true" [rounded]="true" (onClick)="removerGateway(g)" />
                                        }
                                    </td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage><tr><td colspan="4" class="text-center py-6 text-surface-500">Nenhum gateway fixo.</td></tr></ng-template>
                        </p-table>
                    </p-tabpanel>
                    <p-tabpanel value="fila">
                        <div class="grid grid-cols-12 gap-6">
                            @if (auth.podeEscrever()) {
                                <div class="col-span-12 lg:col-span-4 flex flex-col gap-4">
                                    <div>
                                        <label class="block font-medium mb-2">FPort</label>
                                        <p-inputnumber [(ngModel)]="fPort" [min]="1" [max]="223" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">Payload (hex)</label>
                                        <input pInputText class="w-full font-mono" [(ngModel)]="payload" placeholder="01 0A FF" />
                                    </div>
                                    <p-button label="Enfileirar" icon="pi pi-send" (onClick)="enfileirar()" />
                                    <p-button label="Limpar fila" icon="pi pi-trash" severity="danger" [outlined]="true" (onClick)="limparFila()" [disabled]="!fila().length" />
                                </div>
                            }
                            <div class="col-span-12" [ngClass]="{ 'lg:col-span-8': auth.podeEscrever() }">
                                <p-table [value]="fila()">
                                    <ng-template #header><tr><th>FCnt</th><th>FPort</th><th>Payload (hex)</th><th>Expira em</th></tr></ng-template>
                                    <ng-template #body let-q>
                                        <tr>
                                            <td>{{ n(q.fCnt) }}</td>
                                            <td>{{ q.fPort }}</td>
                                            <td class="font-mono">{{ hex(q.data) }}</td>
                                            <td>{{ q.expiresAt ? data(q.expiresAt) : '—' }}</td>
                                        </tr>
                                    </ng-template>
                                    <ng-template #emptymessage><tr><td colspan="4" class="text-center py-6 text-surface-500">Fila vazia.</td></tr></ng-template>
                                </p-table>
                            </div>
                        </div>
                    </p-tabpanel>
                </p-tabpanels>
            </p-tabs>
        </div>
    `
})
export class MulticastDetail implements OnInit {
    applicationId = input.required<string>();
    id = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    auth = inject(AuthService);

    grupo = signal<GetMulticastGroupResponse | null>(null);
    dispositivos = signal<DeviceListItem[]>([]);
    gateways = signal<GatewayListItem[]>([]);
    fila = signal<MulticastGroupQueueItem[]>([]);
    dispositivosDisponiveis = signal<DeviceListItem[]>([]);
    gatewaysDisponiveis = signal<GatewayListItem[]>([]);
    resumo = signal('');
    novoDispositivo: string | null = null;
    novoGateway: string | null = null;
    fPort = 1;
    payload = '';
    hex = base64ParaHex;
    data = dataHora;
    n = num;

    ngOnInit(): void {
        if (this.auth.podeEscrever()) {
            this.api.getMulticastGroup(this.id()).subscribe({
                next: (g) => {
                    this.grupo.set(g);
                    const m = g.multicastGroup;
                    this.resumo.set(`${m.groupType === 'CLASS_B' ? 'Classe B' : 'Classe C'} · ${m.region} · DR ${num(m.dr)} · ${(num(m.frequency) / 1e6).toFixed(1)} MHz · McAddr ${m.mcAddr}`);
                },
                error: (e) => this.notify.erro(e)
            });
        }
        this.carregarMembros();
        this.carregarFila();
    }

    carregarMembros(): void {
        forkJoin({
            devs: this.api.listDevices({ multicastGroupId: this.id(), limit: 1000 }),
            todos: this.api.listDevices({ applicationId: this.applicationId(), limit: 1000 }),
            gws: this.api.listGateways({ multicastGroupId: this.id(), limit: 1000 }),
            app: this.api.getApplication(this.applicationId())
        }).subscribe({
            next: (r) => {
                this.dispositivos.set(r.devs.result);
                const noGrupo = new Set(r.devs.result.map((d) => d.devEui));
                this.dispositivosDisponiveis.set(r.todos.result.filter((d) => !noGrupo.has(d.devEui)));
                this.gateways.set(r.gws.result);
                const gwNoGrupo = new Set(r.gws.result.map((g) => g.gatewayId));
                this.api.listGateways({ tenantId: r.app.application.tenantId, limit: 1000 }).subscribe({
                    next: (t) => this.gatewaysDisponiveis.set(t.result.filter((g) => !gwNoGrupo.has(g.gatewayId)))
                });
            },
            error: (e) => this.notify.erro(e)
        });
    }

    carregarFila(): void {
        this.api.listMulticastQueue(this.id()).subscribe({ next: (r) => this.fila.set(r.items ?? []), error: (e) => this.notify.erro(e) });
    }

    adicionarDispositivo(): void {
        if (!this.novoDispositivo) {
            return;
        }
        this.api.addMulticastDevice(this.id(), this.novoDispositivo).subscribe({
            next: () => {
                this.novoDispositivo = null;
                this.notify.sucesso('Dispositivo adicionado ao grupo.');
                this.carregarMembros();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    removerDispositivo(d: DeviceListItem): void {
        this.api.removeMulticastDevice(this.id(), d.devEui).subscribe({
            next: () => {
                this.notify.sucesso('Dispositivo removido do grupo.');
                this.carregarMembros();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    adicionarGateway(): void {
        if (!this.novoGateway) {
            return;
        }
        this.api.addMulticastGateway(this.id(), this.novoGateway).subscribe({
            next: () => {
                this.novoGateway = null;
                this.notify.sucesso('Gateway adicionado ao grupo.');
                this.carregarMembros();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    removerGateway(g: GatewayListItem): void {
        this.api.removeMulticastGateway(this.id(), g.gatewayId).subscribe({
            next: () => {
                this.notify.sucesso('Gateway removido do grupo.');
                this.carregarMembros();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    enfileirar(): void {
        let data: string;
        try {
            data = hexParaBase64(this.payload);
        } catch {
            this.notify.aviso('Payload hexadecimal inválido.');
            return;
        }
        this.api.enqueueMulticast(this.id(), { fPort: this.fPort, data }).subscribe({
            next: (r) => {
                this.notify.sucesso(`Downlink enfileirado (FCnt ${num(r.fCnt)}).`);
                this.payload = '';
                this.carregarFila();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    limparFila(): void {
        this.notify.confirmar('Limpar fila', 'Remover todos os downlinks pendentes do grupo?', () =>
            this.api.flushMulticastQueue(this.id()).subscribe({
                next: () => {
                    this.notify.sucesso('Fila limpa.');
                    this.carregarFila();
                },
                error: (e) => this.notify.erro(e)
            }), 'Limpar');
    }
}
