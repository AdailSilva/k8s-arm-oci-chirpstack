import { Component } from '@angular/core';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { NUMEROS } from '@/app/core/site.config';

@Component({
    selector: 'home-numbers',
    standalone: true,
    imports: [RevealDirective],
    template: `
        <section class="landing-container py-10">
            <div class="rounded-[2rem] border p-2 bg-surface-50 dark:bg-surface-950">
                <div class="grid grid-cols-2 lg:grid-cols-4 rounded-3xl bg-surface-0 dark:bg-surface-900 shadow-stroke overflow-hidden">
                    @for (n of numeros; track n.rotulo; let i = $index) {
                        <div reveal [revealDelay]="i * 90" class="p-5 md:p-8 border-surface-200 dark:border-surface-800" [class.border-l]="i % 2 === 1 || i > 1" [class.lg:border-l]="i > 0" [class.border-t]="i > 1" [class.lg:border-t-0]="i > 1">
                            <div class="text-3xl md:text-5xl font-medium tracking-tight text-gradient w-fit">{{ n.valor }}</div>
                            <div class="mt-2 font-medium">{{ n.rotulo }}</div>
                            <p class="mt-1 text-sm text-surface-500 leading-5">{{ n.detalhe }}</p>
                        </div>
                    }
                </div>
            </div>
        </section>
    `
})
export class HomeNumbers {
    readonly numeros = NUMEROS;
}
