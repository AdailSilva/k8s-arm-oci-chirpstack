import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { ProgressSpinnerModule } from 'primeng/progressspinner';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { CertificateResponse, GetGatewayDutyCycleMetricsResponse, GetGatewayMetricsResponse, GetGatewayResponse } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { baixarArquivo, dataHora, num, tempoRelativo } from '@/app/core/format/format';
import { CopyButton } from '@/app/shared/campos/copy-button';
import { MetricChart } from '@/app/shared/graficos/metric-chart';
import { PageHeader } from '@/app/shared/visual/page-header';
import { intervaloDe, PERIODOS, Periodo, PeriodSelector } from '@/app/shared/graficos/period-selector';
import { StateTag } from '@/app/shared/visual/state-tag';

/**
 * Gateway: dados, métricas de tráfego, duty-cycle e certificado de cliente.
 */
@Component({
    selector: 'app-gateway-detail',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, ProgressSpinnerModule, TagModule, TextareaModule, CopyButton, MetricChart, PageHeader, PeriodSelector, StateTag],
    template: `
        <app-page-header [title]="gw()?.gateway?.name ?? id()" [subtitle]="'Gateway ID ' + id()" icon="pi pi-wifi">
            <p-button label="Gateways" icon="pi pi-arrow-left" severity="secondary" [outlined]="true" routerLink="/gateways" />
            @if (auth.podeEscrever()) {
                <p-button label="Certificado TLS" icon="pi pi-shield" severity="secondary" (onClick)="gerarCertificado()" [loading]="gerando()" />
                <p-button label="Editar" icon="pi pi-pencil" severity="secondary" [routerLink]="['/gateways', id(), 'editar']" />
                <p-button label="Excluir" icon="pi pi-trash" severity="danger" [outlined]="true" (onClick)="excluir()" />
            }
        </app-page-header>

        @if (gw(); as g) {
            <div class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Estado</div><div class="mt-1"><app-state-tag [state]="estado()" /></div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Visto por último</div><div class="font-semibold mt-1" [title]="g.lastSeenAt ?? ''">{{ relativo(g.lastSeenAt) }}</div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Estatísticas a cada</div><div class="font-semibold mt-1">{{ n(g.gateway.statsInterval) }} s</div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Prioridade de downlink</div><div class="font-semibold mt-1">{{ g.gateway.downlinkPriority != null ? n(g.gateway.downlinkPriority) : '—' }}</div></div>
                <div class="card mb-0! md:col-span-2">
                    <div class="text-surface-500 text-sm">Localização</div>
                    @if (g.gateway.location.latitude || g.gateway.location.longitude) {
                        <a class="font-semibold mt-1 block text-primary hover:underline" target="_blank" rel="noopener" [href]="'https://www.openstreetmap.org/?mlat=' + g.gateway.location.latitude + '&mlon=' + g.gateway.location.longitude + '#map=16/' + g.gateway.location.latitude + '/' + g.gateway.location.longitude">
                            {{ g.gateway.location.latitude | number: '1.5-6' }}, {{ g.gateway.location.longitude | number: '1.5-6' }} · {{ g.gateway.location.altitude | number: '1.0-0' }} m
                        </a>
                    } @else {
                        <div class="font-semibold mt-1">Não informada</div>
                    }
                </div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Cadastrado em</div><div class="font-semibold mt-1">{{ data(g.createdAt) }}</div></div>
            </div>
            @if (g.gateway.description || tags().length || meta().length) {
                <div class="card mb-6! flex flex-col gap-3">
                    @if (g.gateway.description) {
                        <div>{{ g.gateway.description }}</div>
                    }
                    @if (tags().length) {
                        <div>
                            @for (t of tags(); track t[0]) {
                                <p-tag [value]="t[0] + ': ' + t[1]" severity="secondary" class="mr-1" />
                            }
                        </div>
                    }
                    @if (meta().length) {
                        <div class="text-sm text-surface-500">
                            @for (m of meta(); track m[0]) {
                                <span class="mr-4"><b>{{ m[0] }}</b>: {{ m[1] }}</span>
                            }
                        </div>
                    }
                </div>
            }
        }

        <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
            <span class="font-semibold text-lg">Tráfego</span>
            <app-period-selector [(value)]="periodo" (changed)="carregarMetricas($event)" />
        </div>
        @if (carregandoMetricas()) {
            <div class="flex justify-center py-12"><p-progressspinner styleClass="w-12! h-12!" /></div>
        } @else {
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <app-metric-chart [metric]="metricas()?.rxPackets" title="Pacotes recebidos" type="bar" [showTotal]="true" />
                <app-metric-chart [metric]="metricas()?.txPackets" title="Pacotes transmitidos" type="bar" [showTotal]="true" />
                <app-metric-chart [metric]="metricas()?.rxPacketsPerFreq" title="Recebidos por frequência" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="metricas()?.txPacketsPerFreq" title="Transmitidos por frequência" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="metricas()?.rxPacketsPerDr" title="Recebidos por data rate" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="metricas()?.txPacketsPerDr" title="Transmitidos por data rate" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="metricas()?.txPacketsPerStatus" title="Transmissões por status" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="dutyCycle()?.windowPercentage" title="Duty-cycle (% da janela)" type="line" />
            </div>
        }

        <p-dialog [(visible)]="dialogoCert" header="Certificado de cliente do gateway" [modal]="true" [style]="{ width: '46rem' }" [breakpoints]="{ '768px': '95vw' }">
            @if (certificado(); as c) {
                <p class="mt-0 text-surface-500">Use no ChirpStack Gateway Bridge / MQTT Forwarder com TLS. Válido até <b>{{ data(c.expiresAt) }}</b>. A chave privada não fica guardada: baixe agora.</p>
                @for (p of partes(c); track p.nome) {
                    <div class="mb-4">
                        <div class="flex items-center justify-between mb-1">
                            <span class="font-medium">{{ p.rotulo }}</span>
                            <span>
                                <app-copy-button [value]="p.valor" />
                                <p-button icon="pi pi-download" [text]="true" [rounded]="true" size="small" severity="secondary" (onClick)="baixar(p.nome, p.valor)" />
                            </span>
                        </div>
                        <textarea pTextarea class="w-full font-mono text-xs" rows="4" [ngModel]="p.valor" readonly></textarea>
                    </div>
                }
            }
        </p-dialog>
    `
})
export class GatewayDetail implements OnInit {
    id = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    auth = inject(AuthService);

    gw = signal<GetGatewayResponse | null>(null);
    estado = signal<string>('NEVER_SEEN');
    tags = signal<[string, string][]>([]);
    meta = signal<[string, string][]>([]);
    metricas = signal<GetGatewayMetricsResponse | null>(null);
    dutyCycle = signal<GetGatewayDutyCycleMetricsResponse | null>(null);
    carregandoMetricas = signal(false);
    certificado = signal<CertificateResponse | null>(null);
    dialogoCert = signal(false);
    gerando = signal(false);
    periodo = '24h';
    relativo = tempoRelativo;
    data = dataHora;
    n = num;

    ngOnInit(): void {
        this.api.getGateway(this.id()).subscribe({
            next: (g) => {
                this.gw.set(g);
                this.tags.set(Object.entries(g.gateway.tags ?? {}));
                this.meta.set(Object.entries(g.gateway.metadata ?? {}));
                this.calcularEstado(g);
            },
            error: (e) => this.notify.erro(e)
        });
        this.carregarMetricas(PERIODOS[0]);
    }

    /** O GetGatewayResponse não traz o estado: calcula pelo último contato e o intervalo de estatísticas. */
    private calcularEstado(g: GetGatewayResponse): void {
        if (!g.lastSeenAt) {
            this.estado.set('NEVER_SEEN');
            return;
        }
        const limite = num(g.gateway.statsInterval, 30) * 2 * 1000;
        this.estado.set(Date.now() - new Date(g.lastSeenAt).getTime() <= limite ? 'ONLINE' : 'OFFLINE');
    }

    carregarMetricas(p: Periodo): void {
        const { start, end } = intervaloDe(p);
        this.carregandoMetricas.set(true);
        forkJoin({
            m: this.api.getGatewayMetrics(this.id(), start, end, p.agregacao),
            d: this.api.getGatewayDutyCycleMetrics(this.id(), start, end)
        }).subscribe({
            next: (r) => {
                this.metricas.set(r.m);
                this.dutyCycle.set(r.d);
                this.carregandoMetricas.set(false);
            },
            error: (e) => {
                this.carregandoMetricas.set(false);
                this.notify.erro(e, 'Falha ao carregar métricas');
            }
        });
    }

    gerarCertificado(): void {
        this.gerando.set(true);
        this.api.generateGatewayCertificate(this.id()).subscribe({
            next: (c) => {
                this.gerando.set(false);
                this.certificado.set(c);
                this.dialogoCert.set(true);
            },
            error: (e) => {
                this.gerando.set(false);
                this.notify.erro(e);
            }
        });
    }

    partes(c: CertificateResponse) {
        return [
            { nome: `${this.id()}-ca.crt`, rotulo: 'Certificado da CA', valor: c.caCert },
            { nome: `${this.id()}.crt`, rotulo: 'Certificado do gateway', valor: c.tlsCert },
            { nome: `${this.id()}.key`, rotulo: 'Chave privada', valor: c.tlsKey }
        ];
    }

    baixar(nome: string, valor: string): void {
        baixarArquivo(nome, valor, 'application/x-pem-file');
    }

    excluir(): void {
        this.notify.confirmarExclusao(`o gateway ${this.id()}`, () =>
            this.api.deleteGateway(this.id()).subscribe({
                next: () => {
                    this.notify.sucesso('Gateway excluído.');
                    this.router.navigate(['/gateways']);
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
