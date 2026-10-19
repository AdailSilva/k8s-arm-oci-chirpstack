import { Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TagModule } from 'primeng/tag';
import { ProgressSpinnerModule } from 'primeng/progressspinner';
import { forkJoin } from 'rxjs';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { GetDeviceLinkMetricsResponse, GetDeviceMetricsResponse, Metric } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { MetricChart } from '@/app/shared/metric-chart';
import { intervaloDe, PERIODOS, Periodo, PeriodSelector } from '@/app/shared/period-selector';

/**
 * Métricas do dispositivo: enlace (pacotes, RSSI, SNR, frequência, DR) e medições do codec.
 */
@Component({
    selector: 'app-device-metrics',
    standalone: true,
    imports: [CommonModule, TagModule, ProgressSpinnerModule, MetricChart, PeriodSelector],
    template: `
        <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
            <span class="font-semibold text-lg">Métricas</span>
            <app-period-selector [(value)]="periodo" (changed)="carregar($event)" />
        </div>
        @if (carregando()) {
            <div class="flex justify-center py-12"><p-progressspinner styleClass="w-12! h-12!" /></div>
        } @else {
            @if (estados().length) {
                <div class="flex flex-wrap gap-2 mb-4">
                    @for (s of estados(); track s.name) {
                        <p-tag [value]="s.name + ': ' + s.value" severity="info" />
                    }
                </div>
            }
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <app-metric-chart [metric]="link()?.rxPackets" title="Pacotes recebidos" type="bar" [showTotal]="true" />
                <app-metric-chart [metric]="link()?.errors" title="Erros" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="link()?.gwRssi" title="RSSI (dBm)" type="line" />
                <app-metric-chart [metric]="link()?.gwSnr" title="SNR (dB)" type="line" />
                <app-metric-chart [metric]="link()?.rxPacketsPerFreq" title="Pacotes por frequência" type="bar" [stacked]="true" />
                <app-metric-chart [metric]="link()?.rxPacketsPerDr" title="Pacotes por data rate" type="bar" [stacked]="true" />
                @for (m of medicoes(); track m.name) {
                    <app-metric-chart [metric]="m" [title]="m.name" />
                }
            </div>
            @if (!medicoes().length) {
                <p class="text-surface-500 text-sm mt-4">Medições do dispositivo aparecem aqui quando o codec do perfil decodifica valores e eles estão configurados em "Medições" no perfil de dispositivo.</p>
            }
        }
    `
})
export class DeviceMetricsPanel implements OnInit {
    devEui = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);

    periodo = '24h';
    carregando = signal(false);
    link = signal<GetDeviceLinkMetricsResponse | null>(null);
    metricas = signal<GetDeviceMetricsResponse | null>(null);
    medicoes = computed<Metric[]>(() => Object.values(this.metricas()?.metrics ?? {}));
    estados = computed(() => Object.values(this.metricas()?.states ?? {}));

    ngOnInit(): void {
        this.carregar(PERIODOS[0]);
    }

    carregar(p: Periodo): void {
        const { start, end } = intervaloDe(p);
        this.carregando.set(true);
        forkJoin({
            link: this.api.getDeviceLinkMetrics(this.devEui(), start, end, p.agregacao),
            metricas: this.api.getDeviceMetrics(this.devEui(), start, end, p.agregacao)
        }).subscribe({
            next: (r) => {
                this.link.set(r.link);
                this.metricas.set(r.metricas);
                this.carregando.set(false);
            },
            error: (e) => {
                this.carregando.set(false);
                this.notify.erro(e, 'Falha ao carregar métricas');
            }
        });
    }
}
