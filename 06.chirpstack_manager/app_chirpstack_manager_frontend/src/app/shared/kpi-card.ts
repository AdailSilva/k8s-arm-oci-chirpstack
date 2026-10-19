import { Component, input } from '@angular/core';

/** Cartão de indicador do painel. */
@Component({
    selector: 'app-kpi-card',
    standalone: true,
    template: `
        <div class="card mb-0! h-full flex items-start justify-between gap-4">
            <div>
                <div class="text-surface-500 font-medium">{{ label() }}</div>
                <div class="text-3xl font-semibold mt-2">{{ value() }}</div>
                @if (detail()) {
                    <div class="text-sm mt-2" [class]="detailClass()">{{ detail() }}</div>
                }
            </div>
            <div class="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0" [class]="iconBg()">
                <i [class]="icon() + ' text-xl!'"></i>
            </div>
        </div>
    `
})
export class KpiCard {
    label = input.required<string>();
    value = input<string | number>('—');
    detail = input<string>('');
    detailClass = input<string>('text-surface-500');
    icon = input<string>('pi pi-chart-bar');
    iconBg = input<string>('bg-primary-50 text-primary dark:bg-primary-900/40');
}
