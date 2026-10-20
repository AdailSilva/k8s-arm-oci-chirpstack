import { Component, input } from '@angular/core';

/**
 * Cabeçalho padrão das telas: ícone, título, subtítulo e área de ações à direita.
 */
@Component({
    selector: 'app-page-header',
    standalone: true,
    template: `
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
            <div class="flex items-center gap-4 min-w-0">
                @if (icon()) {
                    <div class="w-12 h-12 shrink-0 rounded-2xl bg-primary-50 dark:bg-primary-900/40 text-primary flex items-center justify-center">
                        <i [class]="icon() + ' text-xl!'"></i>
                    </div>
                }
                <div class="min-w-0">
                    <h1 class="text-2xl font-semibold m-0 truncate">{{ title() }}</h1>
                    @if (subtitle()) {
                        <p class="text-surface-500 m-0 mt-1 truncate">{{ subtitle() }}</p>
                    }
                </div>
            </div>
            <div class="flex flex-wrap items-center gap-2">
                <ng-content />
            </div>
        </div>
    `
})
export class PageHeader {
    title = input.required<string>();
    subtitle = input<string>('');
    icon = input<string>('');
}
