import { Component, inject, input } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { TooltipModule } from 'primeng/tooltip';
import { NotifyService } from '@/app/core/util/notify.service';

@Component({
    selector: 'app-copy-button',
    standalone: true,
    imports: [ButtonModule, TooltipModule],
    template: `<p-button icon="pi pi-copy" [text]="true" [rounded]="true" size="small" severity="secondary" pTooltip="Copiar" tooltipPosition="top" (onClick)="copiar()" [disabled]="!value()" />`
})
export class CopyButton {
    value = input<string | null | undefined>('');
    private notify = inject(NotifyService);

    copiar(): void {
        const v = this.value();
        if (!v) {
            return;
        }
        navigator.clipboard.writeText(v).then(
            () => this.notify.sucesso('Copiado para a área de transferência.'),
            () => this.notify.aviso('O navegador não permitiu copiar.')
        );
    }
}
