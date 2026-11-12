import { Component } from '@angular/core';
import { AnimatedBorder } from '@/app/shared/animated-border';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { PERFIL, REPOSITORIO } from '@/app/core/site.config';
import { canais } from '@/app/core/contato.util';

@Component({
    selector: 'home-contact',
    standalone: true,
    imports: [AnimatedBorder, RevealDirective],
    template: `
        <section id="contato" class="relative pt-24 md:pt-36 pb-8">
            <div class="landing-container">
                <div reveal class="relative">
                    <animated-border [count]="5" />
                    <div class="relative overflow-hidden rounded-3xl bg-surface-0 dark:bg-surface-950 shadow-stroke">
                        <div class="grid lg:grid-cols-5">
                            <div class="lg:col-span-2 relative p-8 md:p-12 bg-surface-950 text-surface-0 overflow-hidden">
                                <div class="absolute inset-0 opacity-50 [background-image:radial-gradient(circle_at_0%_0%,var(--p-primary-600),transparent_50%),radial-gradient(circle_at_100%_100%,#0284c7,transparent_45%)]"></div>
                                <div class="relative">
                                    <h2 class="text-3xl md:text-5xl font-medium leading-[120%]">Monte a sua rede LoRaWAN</h2>
                                    <p class="mt-5 text-surface-300 leading-7">Clone o repositório e siga o README: infraestrutura, DNS, FSS, ChirpStack v3 e v4, gateways, MQTT e troubleshooting — tudo documentado.</p>
                                    <a [href]="repo.url" target="_blank" rel="noopener" class="mt-8 inline-flex items-center gap-2 rounded-full bg-white text-surface-950 px-5 py-2.5 font-medium hover:bg-surface-200 transition-colors">
                                        <i class="pi pi-github"></i> AdailSilva/{{ repo.nome }}
                                    </a>
                                </div>
                            </div>
                            <div class="lg:col-span-3 p-8 md:p-12">
                                <h3 class="text-2xl font-medium">Precisa de ajuda com o seu projeto?</h3>
                                <p class="mt-3 text-surface-500 leading-7">Implantação do ChirpStack, configuração de gateways, firmware de nós ou integração com seus sistemas: fale direto com {{ perfil.nome }}.</p>
                                <ul class="mt-8 grid sm:grid-cols-2 gap-3">
                                    @for (c of canais; track c.id) {
                                        <li>
                                            <a [href]="c.href" target="_blank" rel="noopener" class="group flex items-center gap-3 rounded-2xl border hover:border-primary-500/50 transition-colors p-3">
                                                <span class="w-10 h-10 rounded-xl bg-primary-500/10 text-primary-600 dark:text-primary-300 flex items-center justify-center"><i [class]="c.icone"></i></span>
                                                <span class="flex-1 min-w-0 leading-tight">
                                                    <span class="block text-xs text-surface-500">{{ c.rotulo }}</span>
                                                    <span class="block font-medium truncate">{{ c.valor }}</span>
                                                </span>
                                                <i class="pi pi-arrow-up-right text-sm! text-surface-400 group-hover:text-primary-500 transition-colors"></i>
                                            </a>
                                        </li>
                                    }
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `
})
export class HomeContact {
    readonly canais = canais();
    readonly repo = REPOSITORIO;
    readonly perfil = PERFIL;
}
