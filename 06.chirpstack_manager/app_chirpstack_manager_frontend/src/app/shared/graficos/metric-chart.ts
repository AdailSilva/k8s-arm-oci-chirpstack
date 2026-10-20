import { Component, computed, inject, input } from '@angular/core';
import { ChartModule } from 'primeng/chart';
import { Metric } from '@/app/core/http/models';
import { LayoutService } from '@/app/layout/service/layout.service';

const CORES = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16', '#f97316', '#64748b'];

/**
 * Gráfico de uma métrica do ChirpStack (timestamps + datasets).
 */
@Component({
    selector: 'app-metric-chart',
    standalone: true,
    imports: [ChartModule],
    template: `
        <div class="card h-full mb-0!">
            <div class="flex items-center justify-between mb-4">
                <span class="font-semibold">{{ title() || metric()?.name }}</span>
                @if (total() !== null) {
                    <span class="text-surface-500 text-sm">Total: <b class="text-surface-900 dark:text-surface-0">{{ total() }}</b></span>
                }
            </div>
            @if (vazio()) {
                <div class="h-56 flex flex-col items-center justify-center text-surface-400 gap-2">
                    <i class="pi pi-chart-line text-3xl!"></i>
                    <span>Sem dados no período</span>
                </div>
            } @else {
                <p-chart [type]="tipo()" [data]="dados()" [options]="opcoes()" height="14rem" />
            }
        </div>
    `
})
export class MetricChart {
    metric = input<Metric | null | undefined>(null);
    title = input<string>('');
    type = input<'line' | 'bar' | 'auto'>('auto');
    stacked = input<boolean>(false);
    showTotal = input<boolean>(false);

    private layout = inject(LayoutService);

    tipo = computed(() => {
        const t = this.type();
        if (t !== 'auto') {
            return t;
        }
        return this.metric()?.kind === 'COUNTER' || (this.metric()?.datasets?.length ?? 0) > 1 ? 'bar' : 'line';
    });

    vazio = computed(() => {
        const m = this.metric();
        return !m || !m.timestamps?.length || !m.datasets?.some((d) => d.data?.some((v) => v !== 0));
    });

    total = computed(() => {
        if (!this.showTotal()) {
            return null;
        }
        const m = this.metric();
        if (!m) {
            return 0;
        }
        return Math.round(m.datasets.reduce((s, d) => s + d.data.reduce((a, b) => a + (b || 0), 0), 0) * 100) / 100;
    });

    dados = computed(() => {
        const m = this.metric();
        if (!m) {
            return { labels: [], datasets: [] };
        }
        const diario = this.intervalo(m.timestamps) >= 86_400_000;
        const labels = m.timestamps.map((t) => {
            const d = new Date(t);
            return diario ? d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }) : d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        });
        const linha = this.tipo() === 'line';
        return {
            labels,
            datasets: m.datasets.map((ds, i) => {
                const cor = CORES[i % CORES.length];
                return {
                    label: ds.label || m.name,
                    data: ds.data,
                    borderColor: cor,
                    backgroundColor: linha ? cor + '22' : cor + 'cc',
                    fill: linha && m.datasets.length === 1,
                    tension: 0.35,
                    pointRadius: 0,
                    borderWidth: 2,
                    borderRadius: linha ? 0 : 4,
                    maxBarThickness: 28
                };
            })
        };
    });

    opcoes = computed(() => {
        const escuro = this.layout.isDarkTheme();
        const texto = escuro ? '#a1a1aa' : '#71717a';
        const grade = escuro ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)';
        const multi = (this.metric()?.datasets?.length ?? 0) > 1;
        return {
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: { legend: { display: multi, position: 'bottom', labels: { color: texto, boxWidth: 12, usePointStyle: true } } },
            scales: {
                x: { stacked: this.stacked(), ticks: { color: texto, maxRotation: 0, autoSkipPadding: 12 }, grid: { display: false } },
                y: { stacked: this.stacked(), ticks: { color: texto }, grid: { color: grade }, beginAtZero: this.metric()?.kind !== 'GAUGE' }
            }
        };
    });

    private intervalo(ts: string[]): number {
        return ts.length > 1 ? new Date(ts[1]).getTime() - new Date(ts[0]).getTime() : 0;
    }
}
