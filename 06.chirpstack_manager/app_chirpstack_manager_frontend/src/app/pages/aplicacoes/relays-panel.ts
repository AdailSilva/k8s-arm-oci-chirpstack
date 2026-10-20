import { Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { MessageModule } from 'primeng/message';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { DeviceListItem, RelayDeviceListItem, RelayListItem } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora, num } from '@/app/core/format/format';

/**
 * Relays LoRaWAN (TS011) da aplicação, a partir da 4.19: cada relay é um dispositivo cujo perfil tem
 * "O dispositivo é um relay" ligado. Aqui se escolhe quais dispositivos finais passam por cada relay.
 */
@Component({
    selector: 'app-relays-panel',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, MessageModule, SelectModule, TableModule, TagModule, TooltipModule],
    template: `
        <div class="grid grid-cols-12 gap-6">
            <div class="col-span-12 lg:col-span-5">
                <div class="font-semibold mb-3">Relays da aplicação</div>
                <p-table [value]="relays()" [loading]="carregando()" selectionMode="single" [selection]="relay()" (onRowSelect)="selecionar($any($event.data))" dataKey="devEui" [paginator]="relays().length > 10" [rows]="10" [rowHover]="true">
                    <ng-template #header>
                        <tr><th>Relay</th><th>DevEUI</th></tr>
                    </ng-template>
                    <ng-template #body let-r>
                        <tr [pSelectableRow]="r" class="cursor-pointer">
                            <td class="font-medium">{{ r.name }}</td>
                            <td class="font-mono">{{ r.devEui }}</td>
                        </tr>
                    </ng-template>
                    <ng-template #emptymessage>
                        <tr>
                            <td colspan="2" class="text-center py-8 text-surface-500">
                                Nenhum relay. Um dispositivo vira relay quando o perfil dele tem "O dispositivo é um relay (TS011)" ligado, na aba Relay do perfil de dispositivo.
                            </td>
                        </tr>
                    </ng-template>
                </p-table>
            </div>
            <div class="col-span-12 lg:col-span-7">
                @if (relay(); as r) {
                    <div class="flex items-center justify-between gap-3 mb-3 flex-wrap">
                        <div class="font-semibold">Dispositivos atendidos por <span class="text-primary">{{ r.name }}</span>&nbsp;<span class="text-surface-500 font-normal">({{ totalDispositivos() }})</span></div>
                        @if (auth.podeEscrever()) {
                            <p-button label="Adicionar dispositivo" icon="pi pi-plus" size="small" (onClick)="abrirAdicionar()" />
                        }
                    </div>
                    <p-table [value]="dispositivos()" [loading]="carregandoDispositivos()" [paginator]="dispositivos().length > 10" [rows]="10" [rowHover]="true">
                        <ng-template #header>
                            <tr><th>Dispositivo</th><th>DevEUI</th><th>Adicionado em</th><th class="w-16"></th></tr>
                        </ng-template>
                        <ng-template #body let-d>
                            <tr>
                                <td><a [routerLink]="['/aplicacoes', applicationId(), 'dispositivos', d.devEui]" class="font-medium text-primary hover:underline">{{ d.name }}</a></td>
                                <td class="font-mono">{{ d.devEui }}</td>
                                <td>{{ data(d.createdAt) }}</td>
                                <td class="text-right">
                                    @if (auth.podeEscrever()) {
                                        <p-button icon="pi pi-times" severity="danger" [text]="true" [rounded]="true" pTooltip="Remover do relay" (onClick)="remover(d)" />
                                    }
                                </td>
                            </tr>
                        </ng-template>
                        <ng-template #emptymessage>
                            <tr><td colspan="4" class="text-center py-8 text-surface-500">Nenhum dispositivo atribuído a este relay.</td></tr>
                        </ng-template>
                    </p-table>
                } @else {
                    <p-message severity="info" text="Selecione um relay para ver e gerenciar os dispositivos que ele atende." styleClass="w-full" />
                }
            </div>
        </div>

        <p-dialog [(visible)]="dialogo" header="Adicionar dispositivo ao relay" [modal]="true" [style]="{ width: '34rem' }" [breakpoints]="{ '768px': '95vw' }">
            <div class="flex flex-col gap-3">
                <label class="font-medium" for="rdev">Dispositivo da aplicação</label>
                <p-select inputId="rdev" [options]="candidatos()" optionLabel="rotulo" optionValue="devEui" [(ngModel)]="escolhido" [filter]="true" filterBy="rotulo" placeholder="Selecione" styleClass="w-full" appendTo="body" [loading]="carregandoCandidatos()" />
                <small class="text-surface-500">O perfil do dispositivo deve ter "O dispositivo pode operar através de um relay" ligado; caso contrário o ChirpStack recusa.</small>
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Adicionar" icon="pi pi-check" (onClick)="adicionar()" [disabled]="!escolhido" [loading]="salvando()" />
            </ng-template>
        </p-dialog>
    `
})
export class RelaysPanel implements OnInit {
    applicationId = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);
    data = dataHora;

    relays = signal<RelayListItem[]>([]);
    relay = signal<RelayListItem | null>(null);
    carregando = signal(false);
    dispositivos = signal<RelayDeviceListItem[]>([]);
    totalDispositivos = signal(0);
    carregandoDispositivos = signal(false);

    dialogo = signal(false);
    salvando = signal(false);
    carregandoCandidatos = signal(false);
    private dispositivosApp = signal<DeviceListItem[]>([]);
    escolhido = '';

    /** Dispositivos da aplicação que ainda não estão neste relay e que não são relays. */
    candidatos = computed(() => {
        const jaNoRelay = new Set(this.dispositivos().map((d) => d.devEui));
        const relays = new Set(this.relays().map((r) => r.devEui));
        return this.dispositivosApp()
            .filter((d) => !jaNoRelay.has(d.devEui) && !relays.has(d.devEui))
            .map((d) => ({ devEui: d.devEui, rotulo: `${d.name} · ${d.devEui}` }));
    });

    ngOnInit(): void {
        this.carregarRelays();
    }

    carregarRelays(): void {
        this.carregando.set(true);
        this.api.listRelays(this.applicationId(), { limit: 1000 }).subscribe({
            next: (r) => {
                this.relays.set(r.result ?? []);
                this.carregando.set(false);
            },
            error: (e) => {
                this.carregando.set(false);
                this.notify.erro(e, 'Falha ao listar relays (requer ChirpStack 4.19 ou superior)');
            }
        });
    }

    selecionar(r: RelayListItem): void {
        this.relay.set(r);
        this.carregarDispositivos();
    }

    private carregarDispositivos(): void {
        const r = this.relay();
        if (!r) {
            return;
        }
        this.carregandoDispositivos.set(true);
        this.api.listRelayDevices(r.devEui, { limit: 1000 }).subscribe({
            next: (res) => {
                this.dispositivos.set(res.result ?? []);
                this.totalDispositivos.set(num(res.totalCount));
                this.carregandoDispositivos.set(false);
            },
            error: (e) => {
                this.carregandoDispositivos.set(false);
                this.notify.erro(e);
            }
        });
    }

    abrirAdicionar(): void {
        this.escolhido = '';
        this.dialogo.set(true);
        this.carregandoCandidatos.set(true);
        this.api.listDevices({ applicationId: this.applicationId(), limit: 1000 }).subscribe({
            next: (r) => {
                this.dispositivosApp.set(r.result ?? []);
                this.carregandoCandidatos.set(false);
            },
            error: (e) => {
                this.carregandoCandidatos.set(false);
                this.notify.erro(e);
            }
        });
    }

    adicionar(): void {
        const r = this.relay();
        if (!r || !this.escolhido) {
            return;
        }
        this.salvando.set(true);
        this.api.addRelayDevice(r.devEui, this.escolhido).subscribe({
            next: () => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso('Dispositivo adicionado ao relay.');
                this.carregarDispositivos();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    remover(d: RelayDeviceListItem): void {
        const r = this.relay();
        if (!r) {
            return;
        }
        this.notify.confirmarExclusao(`o dispositivo "${d.name}" do relay "${r.name}"`, () =>
            this.api.removeRelayDevice(r.devEui, d.devEui).subscribe({
                next: () => {
                    this.notify.sucesso('Dispositivo removido do relay.');
                    this.carregarDispositivos();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
