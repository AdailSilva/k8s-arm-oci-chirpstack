import { Component, inject } from '@angular/core';
import { SectionHeader } from '@/app/shared/section-header';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { LorawanFlow } from '@/app/shared/lorawan-flow';
import { NavService } from '@/app/layout/nav.service';
import { VERSOES } from '@/app/core/site.config';

/** Fluxo ponta a ponta + cartões das duas versões. */
@Component({
    selector: 'home-versions',
    standalone: true,
    imports: [SectionHeader, RevealDirective, LorawanFlow],
    template: `
        <section id="arquitetura" class="relative pt-24 md:pt-36">
            <div class="landing-container">
                <section-header selo="Arquitetura" icone="pi pi-sitemap" subtitulo="Do rádio ao dado na aplicação: o mesmo caminho serve às duas versões, cada uma no seu namespace e com portas próprias.">
                    Uma rede LoRaWAN inteira<br class="hidden md:block" />
                    dentro do cluster
                </section-header>

                <div reveal class="mt-14 p-2 rounded-[2rem] bg-surface-50 dark:bg-surface-950 border">
                    <div class="rounded-3xl bg-surface-0/60 dark:bg-surface-900/60 p-4 md:p-8">
                        <lorawan-flow />
                        <p class="mt-6 text-center text-xs text-surface-500"><span class="inline-block w-2 h-2 rounded-full bg-emerald-500 mr-1.5"></span>uplink <span class="inline-block w-2 h-2 rounded-full bg-amber-500 ml-4 mr-1.5"></span>downlink</p>
                    </div>
                </div>

                <div class="mt-6 grid lg:grid-cols-2 gap-5">
                    @for (v of versoes; track v.id; let i = $index) {
                        <div reveal [revealDelay]="i * 100" class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                            <div class="h-full flex flex-col p-6 md:p-8 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                                <div class="flex items-start justify-between gap-4">
                                    <div>
                                        <span class="text-xs font-mono rounded-md px-2 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300">ns/{{ v.namespace }}</span>
                                        <h3 class="mt-3 text-2xl md:text-3xl font-medium">{{ v.nome }}</h3>
                                        <p class="mt-1 text-surface-500">{{ v.resumo }}</p>
                                    </div>
                                    <span class="shrink-0 w-14 h-14 rounded-2xl flex items-center justify-center text-lg font-semibold" [class]="v.id === 'v4' ? 'bg-primary-500 text-white' : 'bg-primary-500/10 text-primary-600 dark:text-primary-300'">{{ v.id }}</span>
                                </div>
                                <p class="mt-5 text-sm font-mono text-surface-600 dark:text-surface-300 rounded-xl border px-3 py-2 bg-surface-50 dark:bg-surface-950">{{ v.arquitetura }}</p>
                                <ul class="mt-5 space-y-2.5 flex-1">
                                    @for (d of v.destaques; track d.texto) {
                                        <li class="flex items-start gap-3 text-sm"><i [class]="d.icone" class="text-primary-500 mt-0.5 text-sm!"></i><span>{{ d.texto }}</span></li>
                                    }
                                </ul>
                                <a [href]="v.rota" (click)="nav.ir(v.rota, $event)" class="mt-7 landing-button-secondary rounded-xl! inline-flex items-center justify-center gap-2">
                                    Detalhes da {{ v.id }} <i class="pi pi-arrow-right text-sm!"></i>
                                </a>
                            </div>
                        </div>
                    }
                </div>
            </div>
        </section>
    `
})
export class HomeVersions {
    readonly nav = inject(NavService);
    readonly versoes = VERSOES;
}
