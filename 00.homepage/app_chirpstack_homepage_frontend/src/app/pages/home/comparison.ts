import { Component } from '@angular/core';
import { SectionHeader } from '@/app/shared/section-header';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { COMPARATIVO, SERVICOS_REDE, SERVICOS_WEB } from '@/app/core/site.config';

/** Comparativo v3 × v4 e mapa de serviços expostos. */
@Component({
    selector: 'home-comparison',
    standalone: true,
    imports: [SectionHeader, RevealDirective],
    template: `
        <section id="comparativo" class="relative pt-24 md:pt-36">
            <div class="landing-container">
                <section-header selo="v3 × v4" icone="pi pi-arrows-h" subtitulo="As duas versões convivem no mesmo cluster. Veja o que muda de uma para a outra.">Comparativo das versões</section-header>

                <div reveal class="mt-12 p-2 rounded-[2rem] bg-surface-50 dark:bg-surface-950 border">
                    <div class="rounded-3xl bg-surface-0 dark:bg-surface-900 shadow-stroke overflow-x-auto">
                        <table class="w-full text-sm min-w-[620px]">
                            <thead>
                                <tr class="text-left">
                                    <th class="p-4 md:p-5 font-medium text-surface-500 w-[28%]">Aspecto</th>
                                    <th class="p-4 md:p-5 font-medium"><span class="inline-flex items-center gap-2"><span class="w-7 h-7 rounded-lg bg-primary-500/10 text-primary-600 dark:text-primary-300 flex items-center justify-center text-xs font-semibold">v3</span>ChirpStack v3</span></th>
                                    <th class="p-4 md:p-5 font-medium"><span class="inline-flex items-center gap-2"><span class="w-7 h-7 rounded-lg bg-primary-500 text-white flex items-center justify-center text-xs font-semibold">v4</span>ChirpStack v4</span></th>
                                </tr>
                            </thead>
                            <tbody>
                                @for (l of linhas; track l.aspecto) {
                                    <tr class="border-t">
                                        <td class="p-4 md:px-5 text-surface-500">{{ l.aspecto }}</td>
                                        <td class="p-4 md:px-5">{{ l.v3 }}</td>
                                        <td class="p-4 md:px-5 font-medium">{{ l.v4 }}</td>
                                    </tr>
                                }
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>

        <section id="servicos" class="relative pt-24 md:pt-36">
            <div class="landing-container">
                <section-header selo="Mapa de serviços" icone="pi pi-map" subtitulo="Tudo o que o cluster expõe: interfaces web com HTTPS e portas de rede que chegam pelo Network Load Balancer.">Onde acessar cada serviço</section-header>

                <div class="mt-12 grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
                    @for (s of web; track s.endereco; let i = $index) {
                        <a reveal [revealDelay]="i * 70" [href]="'https://' + s.endereco" target="_blank" rel="noopener" class="group block p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                            <div class="h-full p-5 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke transition-transform duration-300 group-hover:-translate-y-1">
                                <div class="flex items-center justify-between">
                                    <span class="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-300 flex items-center justify-center"><i class="pi pi-lock"></i></span>
                                    <i class="pi pi-arrow-up-right text-surface-400 group-hover:text-primary-500 transition-colors"></i>
                                </div>
                                <div class="mt-5 font-medium">{{ s.nome }}</div>
                                <div class="mt-1 text-xs font-mono text-surface-500 break-all">{{ s.endereco }}</div>
                                <div class="mt-3 flex flex-wrap gap-1.5">
                                    <span class="text-[11px] font-mono rounded-md px-2 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300">ns/{{ s.namespace }}</span>
                                    <span class="text-[11px] rounded-md px-2 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300">{{ s.observacao }}</span>
                                </div>
                            </div>
                        </a>
                    }
                </div>

                <div reveal class="mt-6 p-2 rounded-[2rem] bg-surface-50 dark:bg-surface-950 border">
                    <div class="rounded-3xl bg-surface-950 text-surface-0 p-6 md:p-8 overflow-x-auto">
                        <h3 class="font-medium flex items-center gap-2"><i class="pi pi-server text-primary-300"></i>Portas de rede · IP público reservado do NLB</h3>
                        <table class="mt-5 w-full text-sm min-w-[560px]">
                            <tbody>
                                @for (s of rede; track s.endereco) {
                                    <tr class="border-t border-white/10">
                                        <td class="py-3 pr-4">{{ s.nome }}</td>
                                        <td class="py-3 pr-4 font-mono text-teal-300">{{ s.endereco }}</td>
                                        <td class="py-3 pr-4"><span class="text-[11px] rounded-md px-2 py-0.5 bg-white/10">{{ s.protocolo }}</span></td>
                                        <td class="py-3 text-surface-400">{{ s.observacao }}</td>
                                    </tr>
                                }
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    `
})
export class HomeComparison {
    readonly linhas = COMPARATIVO;
    readonly web = SERVICOS_WEB;
    readonly rede = SERVICOS_REDE;
}
