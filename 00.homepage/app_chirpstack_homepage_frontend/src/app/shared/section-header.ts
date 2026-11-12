import { Component, input } from '@angular/core';
import { RevealDirective } from './reveal.directive';

/** Cabeçalho padrão das seções (selo + título + subtítulo). O título aceita <br /> via conteúdo projetado. */
@Component({
    selector: 'section-header',
    standalone: true,
    imports: [RevealDirective],
    template: `
        <div reveal class="text-center mx-auto max-w-3xl">
            <span class="inline-flex items-center gap-2 rounded-full border px-3 py-1 text-sm text-surface-600 dark:text-surface-300 bg-surface-0 dark:bg-surface-900">
                <i [class]="icone()" class="text-primary-500 text-sm!"></i>
                {{ selo() }}
            </span>
            <h2 class="mt-5 text-3xl md:text-5xl font-medium leading-[125%]!">
                <ng-content />
            </h2>
            @if (subtitulo()) {
                <p class="mt-5 text-base md:text-lg text-surface-500 max-w-md md:max-w-2xl mx-auto leading-7">{{ subtitulo() }}</p>
            }
        </div>
    `
})
export class SectionHeader {
    selo = input.required<string>();
    icone = input<string>('pi pi-sparkles');
    subtitulo = input<string>('');
}
