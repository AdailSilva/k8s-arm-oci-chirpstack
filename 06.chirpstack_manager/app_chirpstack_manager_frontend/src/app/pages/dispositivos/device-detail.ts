import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TabsModule } from 'primeng/tabs';
import { TagModule } from 'primeng/tag';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { DeviceProfile, GetDeviceResponse } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora, tempoRelativo } from '@/app/core/format/format';
import { MulticastTable } from '@/app/pages/multicast/multicast-table';
import { CopyButton } from '@/app/shared/campos/copy-button';
import { PageHeader } from '@/app/shared/visual/page-header';
import { DeviceActivationPanel } from './device-activation';
import { DeviceKeysPanel } from './device-keys';
import { DeviceMetricsPanel } from './device-metrics';
import { DeviceQueuePanel } from './device-queue';

/**
 * Dispositivo: resumo e métricas, chaves OTAA, ativação e fila de downlink.
 */
@Component({
    selector: 'app-device-detail',
    standalone: true,
    imports: [CommonModule, RouterModule, ButtonModule, TabsModule, TagModule, CopyButton, PageHeader, DeviceActivationPanel, DeviceKeysPanel, DeviceMetricsPanel, DeviceQueuePanel, MulticastTable],
    template: `
        <app-page-header [title]="dev()?.device?.name ?? devEui()" [subtitle]="'DevEUI ' + devEui()" icon="pi pi-microchip">
            <p-button label="Aplicação" icon="pi pi-arrow-left" severity="secondary" [outlined]="true" [routerLink]="['/aplicacoes', applicationId()]" />
            @if (auth.podeEscrever()) {
                <p-button label="Editar" icon="pi pi-pencil" severity="secondary" [routerLink]="['/aplicacoes', applicationId(), 'dispositivos', devEui(), 'editar']" />
                <p-button label="Excluir" icon="pi pi-trash" severity="danger" [outlined]="true" (onClick)="excluir()" />
            }
        </app-page-header>

        @if (dev(); as d) {
            <div class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
                <div class="card mb-0!">
                    <div class="text-surface-500 text-sm">Visto por último</div>
                    <div class="font-semibold mt-1" [title]="d.lastSeenAt ?? ''">{{ relativo(d.lastSeenAt) }}</div>
                </div>
                <div class="card mb-0!">
                    <div class="text-surface-500 text-sm">Classe ativa</div>
                    <div class="font-semibold mt-1">{{ (d.classEnabled || 'CLASS_A').replace('CLASS_', 'Classe ') }}</div>
                </div>
                <div class="card mb-0!">
                    <div class="text-surface-500 text-sm">Bateria</div>
                    <div class="font-semibold mt-1">
                        @if (d.deviceStatus?.externalPowerSource) {
                            Alimentação externa
                        } @else if (d.deviceStatus && d.deviceStatus.batteryLevel >= 0) {
                            {{ d.deviceStatus.batteryLevel | number: '1.0-0' }}%
                        } @else {
                            —
                        }
                    </div>
                </div>
                <div class="card mb-0!">
                    <div class="text-surface-500 text-sm">Margem do link</div>
                    <div class="font-semibold mt-1">{{ d.deviceStatus ? d.deviceStatus.margin + ' dB' : '—' }}</div>
                </div>
                <div class="card mb-0!">
                    <div class="text-surface-500 text-sm">Perfil</div>
                    <a class="font-semibold mt-1 block text-primary hover:underline truncate" [routerLink]="['/perfis-dispositivo', d.device.deviceProfileId]">{{ perfil()?.name ?? '…' }}</a>
                </div>
                <div class="card mb-0!">
                    <div class="text-surface-500 text-sm">Situação</div>
                    <div class="mt-1"><p-tag [value]="d.device.isDisabled ? 'Desativado' : 'Habilitado'" [severity]="d.device.isDisabled ? 'danger' : 'success'" /></div>
                </div>
            </div>
        }

        <div class="card">
            <p-tabs [value]="aba()" (valueChange)="trocarAba($event)">
                <p-tablist>
                    <p-tab value="resumo"><i class="pi pi-chart-line mr-2"></i>Métricas</p-tab>
                    <p-tab value="detalhes"><i class="pi pi-info-circle mr-2"></i>Detalhes</p-tab>
                    @if (auth.podeEscrever()) {
                        <p-tab value="chaves"><i class="pi pi-key mr-2"></i>Chaves OTAA</p-tab>
                        <p-tab value="ativacao"><i class="pi pi-bolt mr-2"></i>Ativação</p-tab>
                    }
                    <p-tab value="fila"><i class="pi pi-send mr-2"></i>Fila de downlink</p-tab>
                    <p-tab value="multicast"><i class="pi pi-sitemap mr-2"></i>Multicast</p-tab>
                </p-tablist>
                <p-tabpanels>
                    <p-tabpanel value="resumo">
                        @if (aba() === 'resumo') {
                            <app-device-metrics [devEui]="devEui()" />
                        }
                    </p-tabpanel>
                    <p-tabpanel value="detalhes">
                        @if (dev(); as d) {
                            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                <div class="flex flex-col gap-4">
                                    <div><div class="text-surface-500 text-sm">DevEUI</div><div class="font-mono flex items-center">{{ d.device.devEui }}<app-copy-button [value]="d.device.devEui" /></div></div>
                                    <div><div class="text-surface-500 text-sm">JoinEUI</div><div class="font-mono flex items-center">{{ d.device.joinEui || '—' }}<app-copy-button [value]="d.device.joinEui" /></div></div>
                                    <div><div class="text-surface-500 text-sm">Descrição</div><div>{{ d.device.description || '—' }}</div></div>
                                    <div><div class="text-surface-500 text-sm">Verificação de frame-counter</div><div>{{ d.device.skipFcntCheck ? 'Desligada' : 'Ligada' }}</div></div>
                                    <div><div class="text-surface-500 text-sm">Criado / atualizado</div><div>{{ data(d.createdAt) }} · {{ data(d.updatedAt) }}</div></div>
                                </div>
                                <div class="flex flex-col gap-4">
                                    <div>
                                        <div class="text-surface-500 text-sm mb-1">Tags</div>
                                        @for (t of pares(d.device.tags); track t[0]) {
                                            <p-tag [value]="t[0] + ': ' + t[1]" severity="secondary" class="mr-1 mb-1" />
                                        } @empty {
                                            <span class="text-surface-400">Nenhuma</span>
                                        }
                                    </div>
                                    <div>
                                        <div class="text-surface-500 text-sm mb-1">Variáveis</div>
                                        @for (t of pares(d.device.variables); track t[0]) {
                                            <p-tag [value]="t[0]" severity="secondary" class="mr-1 mb-1" />
                                        } @empty {
                                            <span class="text-surface-400">Nenhuma</span>
                                        }
                                    </div>
                                </div>
                            </div>
                        }
                    </p-tabpanel>
                    @if (auth.podeEscrever()) {
                        <p-tabpanel value="chaves">
                            @if (aba() === 'chaves' && dev()) {
                                <app-device-keys [devEui]="devEui()" [macVersion]="perfil()?.macVersion" [supportsOtaa]="perfil()?.supportsOtaa ?? true" />
                            }
                        </p-tabpanel>
                        <p-tabpanel value="ativacao">
                            @if (aba() === 'ativacao' && dev()) {
                                <app-device-activation [devEui]="devEui()" [macVersion]="perfil()?.macVersion" [supportsOtaa]="perfil()?.supportsOtaa ?? true" />
                            }
                        </p-tabpanel>
                    }
                    <p-tabpanel value="fila">
                        @if (aba() === 'fila') {
                            <app-device-queue [devEui]="devEui()" />
                        }
                    </p-tabpanel>
                    <p-tabpanel value="multicast">
                        @if (aba() === 'multicast') {
                            <app-multicast-table [applicationId]="applicationId()" [devEui]="devEui()" />
                        }
                    </p-tabpanel>
                </p-tabpanels>
            </p-tabs>
        </div>
    `
})
export class DeviceDetail implements OnInit {
    applicationId = input.required<string>();
    devEui = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    private route = inject(ActivatedRoute);
    auth = inject(AuthService);

    dev = signal<GetDeviceResponse | null>(null);
    perfil = signal<DeviceProfile | null>(null);
    aba = signal('resumo');
    relativo = tempoRelativo;
    data = dataHora;

    ngOnInit(): void {
        this.aba.set(this.route.snapshot.queryParamMap.get('aba') ?? 'resumo');
        this.api.getDevice(this.devEui()).subscribe({
            next: (d) => {
                this.dev.set(d);
                this.api.getDeviceProfile(d.device.deviceProfileId).subscribe({ next: (p) => this.perfil.set(p.deviceProfile) });
            },
            error: (e) => this.notify.erro(e)
        });
    }

    trocarAba(v: string | number | undefined): void {
        const aba = String(v ?? 'resumo');
        this.aba.set(aba);
        this.router.navigate([], { queryParams: { aba }, replaceUrl: true });
    }

    pares(t: Record<string, string> | undefined): [string, string][] {
        return Object.entries(t ?? {});
    }

    excluir(): void {
        this.notify.confirmarExclusao(`o dispositivo ${this.devEui()}`, () =>
            this.api.deleteDevice(this.devEui()).subscribe({
                next: () => {
                    this.notify.sucesso('Dispositivo excluído.');
                    this.router.navigate(['/aplicacoes', this.applicationId()]);
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
