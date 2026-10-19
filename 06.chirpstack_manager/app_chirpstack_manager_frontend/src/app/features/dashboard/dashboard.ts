import { Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { ChartModule } from 'primeng/chart';
import { TableModule } from 'primeng/table';
import { SkeletonModule } from 'primeng/skeleton';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { GatewayListItem, Resumo } from '@/app/core/api/models';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { tempoRelativo } from '@/app/core/util/format';
import { AuthService } from '@/app/core/auth/auth.service';
import { KpiCard } from '@/app/shared/kpi-card';
import { PageHeader } from '@/app/shared/page-header';
import { StateTag } from '@/app/shared/state-tag';
import { LayoutService } from '@/app/layout/service/layout.service';

/**
 * Painel inicial do tenant selecionado.
 */
@Component({
    selector: 'app-dashboard',
    standalone: true,
    imports: [CommonModule, RouterModule, ButtonModule, ChartModule, TableModule, SkeletonModule, KpiCard, PageHeader, StateTag],
    template: `
        <app-page-header title="Painel" [subtitle]="ctx.tenant()?.name ? 'Tenant ' + ctx.tenant()?.name : 'Selecione um tenant no topo da tela'" icon="pi pi-chart-bar">
            <p-button label="Atualizar" icon="pi pi-refresh" severity="secondary" [outlined]="true" (onClick)="carregar()" [loading]="carregando()" />
        </app-page-header>

        @if (!ctx.tenantId()) {
            <div class="card text-center py-12 text-surface-500">
                <i class="pi pi-building text-4xl! mb-4 block"></i>
                Nenhum tenant disponível. {{ auth.isAdmin() ? 'Cadastre um tenant para começar.' : 'Peça a um administrador para cadastrar um tenant.' }}
                @if (auth.isAdmin()) {
                    <div class="mt-4"><p-button label="Ir para tenants" icon="pi pi-arrow-right" routerLink="/tenants" /></div>
                }
            </div>
        } @else {
            <div class="grid grid-cols-12 gap-4">
                @if (resumo(); as r) {
                    <div class="col-span-12 sm:col-span-6 xl:col-span-3">
                        <app-kpi-card label="Gateways online" [value]="r.gateways.online + ' / ' + r.gateways.total" [detail]="r.gateways.offline + ' offline · ' + r.gateways.nuncaVisto + ' nunca vistos'" icon="pi pi-wifi" iconBg="bg-green-50 text-green-600 dark:bg-green-900/30" />
                    </div>
                    <div class="col-span-12 sm:col-span-6 xl:col-span-3">
                        <app-kpi-card label="Dispositivos" [value]="r.dispositivos.total" [detail]="r.dispositivos.ativos24h + ' ativos nas últimas 24 h'" icon="pi pi-microchip" />
                    </div>
                    <div class="col-span-12 sm:col-span-6 xl:col-span-3">
                        <app-kpi-card label="Aplicações" [value]="r.aplicacoes" [detail]="r.dispositivos.nuncaVistos + ' dispositivos nunca vistos'" icon="pi pi-th-large" iconBg="bg-violet-50 text-violet-600 dark:bg-violet-900/30" />
                    </div>
                    <div class="col-span-12 sm:col-span-6 xl:col-span-3">
                        <app-kpi-card label="Perfis de dispositivo" [value]="r.perfis" detail="Configurações LoRaWAN do tenant" icon="pi pi-id-card" iconBg="bg-amber-50 text-amber-600 dark:bg-amber-900/30" />
                    </div>
                } @else {
                    @for (i of [1, 2, 3, 4]; track i) {
                        <div class="col-span-12 sm:col-span-6 xl:col-span-3"><p-skeleton height="7.5rem" borderRadius="1rem" /></div>
                    }
                }

                <div class="col-span-12 xl:col-span-4">
                    <div class="card h-full mb-0!">
                        <div class="font-semibold mb-4">Estado dos gateways</div>
                        @if (resumo()?.gateways?.total) {
                            <p-chart type="doughnut" [data]="graficoGateways()" [options]="opcoesRosca()" height="16rem" />
                        } @else {
                            <div class="h-64 flex items-center justify-center text-surface-400">Nenhum gateway cadastrado</div>
                        }
                    </div>
                </div>

                <div class="col-span-12 xl:col-span-8">
                    <div class="card h-full mb-0!">
                        <div class="font-semibold mb-4">Dispositivos por aplicação</div>
                        @if (resumo()?.dispositivosPorAplicacao?.length) {
                            <p-chart type="bar" [data]="graficoAplicacoes()" [options]="opcoesBarras()" height="16rem" />
                        } @else {
                            <div class="h-64 flex items-center justify-center text-surface-400">Nenhuma aplicação cadastrada</div>
                        }
                    </div>
                </div>

                <div class="col-span-12">
                    <div class="card mb-0!">
                        <div class="flex items-center justify-between mb-4">
                            <span class="font-semibold">Gateways</span>
                            <p-button label="Ver todos" [text]="true" icon="pi pi-arrow-right" iconPos="right" routerLink="/gateways" />
                        </div>
                        <p-table [value]="gateways()" [loading]="carregando()" [tableStyle]="{ 'min-width': '50rem' }" [rows]="8" [paginator]="gateways().length > 8">
                            <ng-template #header>
                                <tr>
                                    <th>Nome</th>
                                    <th>Gateway ID</th>
                                    <th>Estado</th>
                                    <th>Visto por último</th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-g>
                                <tr>
                                    <td><a [routerLink]="['/gateways', g.gatewayId]" class="font-medium text-primary hover:underline">{{ g.name }}</a></td>
                                    <td class="font-mono">{{ g.gatewayId }}</td>
                                    <td><app-state-tag [state]="g.state" /></td>
                                    <td [title]="g.lastSeenAt ?? ''">{{ relativo(g.lastSeenAt) }}</td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage>
                                <tr><td colspan="4" class="text-center text-surface-500 py-6">Nenhum gateway neste tenant.</td></tr>
                            </ng-template>
                        </p-table>
                    </div>
                </div>
            </div>
        }
    `
})
export class Dashboard {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private layout = inject(LayoutService);
    ctx = inject(TenantContextService);
    auth = inject(AuthService);

    resumo = signal<Resumo | null>(null);
    gateways = signal<GatewayListItem[]>([]);
    carregando = signal(false);
    relativo = tempoRelativo;

    constructor() {
        effect(() => {
            const id = this.ctx.tenantId();
            untracked(() => {
                this.resumo.set(null);
                if (id) {
                    this.carregar();
                }
            });
        });
    }

    carregar(): void {
        const id = this.ctx.tenantId();
        if (!id) {
            return;
        }
        this.carregando.set(true);
        this.api.resumo(id).subscribe({
            next: (r) => this.resumo.set(r),
            error: (e) => this.notify.erro(e, 'Falha ao carregar o painel')
        });
        this.api.listGateways({ tenantId: id, limit: 100, orderBy: 'LAST_SEEN_AT', orderByDesc: true }).subscribe({
            next: (r) => {
                this.gateways.set(r.result);
                this.carregando.set(false);
            },
            error: () => this.carregando.set(false)
        });
    }

    private texto = computed(() => (this.layout.isDarkTheme() ? '#a1a1aa' : '#71717a'));

    graficoGateways = computed(() => {
        const g = this.resumo()?.gateways;
        return {
            labels: ['Online', 'Offline', 'Nunca vistos'],
            datasets: [{ data: g ? [g.online, g.offline, g.nuncaVisto] : [], backgroundColor: ['#22c55e', '#ef4444', '#94a3b8'], borderWidth: 0 }]
        };
    });

    opcoesRosca = computed(() => ({
        maintainAspectRatio: false,
        cutout: '68%',
        plugins: { legend: { position: 'bottom', labels: { color: this.texto(), usePointStyle: true } } }
    }));

    graficoAplicacoes = computed(() => {
        const apps = this.resumo()?.dispositivosPorAplicacao ?? [];
        return {
            labels: apps.map((a) => a.name),
            datasets: [
                { label: 'Total', data: apps.map((a) => a.total), backgroundColor: '#3b82f6cc', borderRadius: 6, maxBarThickness: 36 },
                { label: 'Ativos 24 h', data: apps.map((a) => a.ativos24h), backgroundColor: '#22c55ecc', borderRadius: 6, maxBarThickness: 36 }
            ]
        };
    });

    opcoesBarras = computed(() => ({
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: this.texto(), usePointStyle: true } } },
        scales: {
            x: { ticks: { color: this.texto() }, grid: { display: false } },
            y: { beginAtZero: true, ticks: { color: this.texto(), precision: 0 }, grid: { color: this.layout.isDarkTheme() ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)' } }
        }
    }));
}
