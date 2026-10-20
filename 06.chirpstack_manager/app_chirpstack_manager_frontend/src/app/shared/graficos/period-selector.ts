import { Component, model, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { SelectButtonModule } from 'primeng/selectbutton';
import { Aggregation } from '@/app/core/http/models';

export interface Periodo {
    label: string;
    value: string;
    horas: number;
    agregacao: Aggregation;
}

export const PERIODOS: Periodo[] = [
    { label: '24 h', value: '24h', horas: 24, agregacao: 'HOUR' },
    { label: '7 dias', value: '7d', horas: 24 * 7, agregacao: 'DAY' },
    { label: '31 dias', value: '31d', horas: 24 * 31, agregacao: 'DAY' },
    { label: '12 meses', value: '12m', horas: 24 * 365, agregacao: 'MONTH' }
];

/** Seletor de período das métricas. */
@Component({
    selector: 'app-period-selector',
    standalone: true,
    imports: [FormsModule, SelectButtonModule],
    template: `<p-selectbutton [options]="periodos" optionLabel="label" optionValue="value" [ngModel]="value()" (ngModelChange)="mudar($event)" [allowEmpty]="false" size="small" />`
})
export class PeriodSelector {
    value = model<string>('24h');
    changed = output<Periodo>();
    periodos = PERIODOS;

    mudar(v: string): void {
        this.value.set(v);
        this.changed.emit(PERIODOS.find((p) => p.value === v)!);
    }
}

export function intervaloDe(p: Periodo): { start: Date; end: Date } {
    const end = new Date();
    const start = new Date(end.getTime() - p.horas * 3600_000);
    return { start, end };
}
