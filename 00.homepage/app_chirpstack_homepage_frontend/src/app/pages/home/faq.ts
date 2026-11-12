import { Component } from '@angular/core';
import { AccordionModule } from 'primeng/accordion';
import { SurfaceLine } from '@/app/shared/surface-line';
import { SectionHeader } from '@/app/shared/section-header';
import { PERGUNTAS } from '@/app/core/site.config';

@Component({
    selector: 'home-faq',
    standalone: true,
    imports: [AccordionModule, SurfaceLine, SectionHeader],
    template: `
        <section id="perguntas" class="relative pt-24 md:pt-36">
            <surface-line class="top-[420px] -left-72 2xl:-left-32 md:w-[48vw]" />
            <surface-line class="top-[420px] -right-72 2xl:-right-32 md:w-[48vw] scale-x-[-1]" />
            <div class="landing-container max-w-3xl!">
                <section-header selo="Dúvidas frequentes" icone="pi pi-question-circle" subtitulo="Mais respostas na seção Troubleshooting do README do repositório.">Perguntas frequentes</section-header>
                <p-accordion value="0" class="mt-12 flex flex-col gap-4">
                    @for (p of perguntas; track p.pergunta; let i = $index) {
                        <p-accordion-panel [value]="i.toString()" class="rounded-[2.25rem] bg-surface-50 dark:bg-surface-950 border p-2">
                            <div class="px-6 py-5 bg-surface-0 dark:bg-surface-900 rounded-[2rem] shadow-stroke">
                                <p-accordion-header class="group flex items-center justify-between w-full gap-4 text-left">
                                    <h3 class="text-base md:text-lg font-medium text-surface-900 dark:text-surface-0 group-hover:opacity-75 transition-opacity duration-150">{{ p.pergunta }}</h3>
                                </p-accordion-header>
                                <p-accordion-content>
                                    <p class="m-0 text-surface-500 pt-3 leading-7">{{ p.resposta }}</p>
                                </p-accordion-content>
                            </div>
                        </p-accordion-panel>
                    }
                </p-accordion>
            </div>
        </section>
    `
})
export class HomeFaq {
    readonly perguntas = PERGUNTAS;
}
