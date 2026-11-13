import { Component, inject } from '@angular/core';
import { SurfaceLine } from '@/app/shared/surface-line';
import { AnimatedBorder } from '@/app/shared/animated-border';
import { ClusterConsole } from '@/app/shared/cluster-console';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { NavService } from '@/app/layout/nav.service';
import { FAIXA_TECNOLOGIAS, REPOSITORIO } from '@/app/core/site.config';

@Component({
    selector: 'home-hero',
    standalone: true,
    imports: [SurfaceLine, AnimatedBorder, ClusterConsole, RevealDirective],
    template: `
        <section class="relative overflow-hidden pt-36 md:pt-48 pb-16">
            <div class="absolute inset-x-0 top-0 h-[720px] bg-grid pointer-events-none"></div>
            <div class="absolute left-1/2 -translate-x-1/2 top-24 w-[720px] h-[420px] hero-glow pointer-events-none opacity-70"></div>
            <surface-line class="top-16 -left-36 2xl:left-0 md:w-[36vw]" />
            <surface-line class="top-16 -right-36 2xl:right-0 md:w-[36vw] scale-x-[-1]" />
            <surface-line class="top-[410px] -left-36 2xl:left-0 md:w-[48vw] scale-y-[0.5]" />
            <surface-line class="top-[410px] -right-36 2xl:right-0 md:w-[48vw] scale-y-[0.5] scale-x-[-1]" />

            <div class="landing-container relative">
                <div reveal class="w-fit mx-auto mb-6 rounded-full border bg-surface-0/80 dark:bg-surface-900/80 backdrop-blur pl-2 pr-4 py-1.5 flex items-center gap-2.5 text-sm">
                    <span class="whitespace-nowrap flex items-center gap-1.5 rounded-full bg-emerald-500/10 text-emerald-700 dark:text-emerald-300 px-2.5 py-0.5 font-medium">
                        <span class="relative flex w-2 h-2"><span class="absolute inset-0 rounded-full bg-emerald-400 ping-soft"></span><span class="relative w-2 h-2 rounded-full bg-emerald-500"></span></span>
                        Custo zero
                    </span>
                    <span class="text-surface-500 whitespace-nowrap"><span class="hidden sm:inline">Oracle Cloud · </span>Always Free · ARM64</span>
                </div>

                <h1 reveal [revealDelay]="80" class="text-4xl sm:text-5xl md:text-7xl font-medium text-center mx-auto leading-[115%]! tracking-tight max-w-5xl">
                    <span class="text-gradient">ChirpStack v3 e v4</span> em Kubernetes, sem pagar nada pela nuvem
                </h1>
                <p reveal [revealDelay]="160" class="mt-6 text-center mx-auto text-base md:text-xl text-surface-500 max-w-md md:max-w-3xl leading-7 md:leading-8">
                    Um servidor de rede LoRaWAN completo — gateways, MQTT, PostgreSQL, Redis, HTTPS e backups — num cluster de 4 nós Ampere A1 provisionado com Terraform/OpenTofu e documentado passo a passo.
                </p>
                <div reveal [revealDelay]="240" class="flex flex-col sm:flex-row items-center justify-center gap-3.5 mt-9">
                    <a [href]="repo.url" target="_blank" rel="noopener" class="landing-button-primary rounded-xl! px-6! py-3! inline-flex items-center gap-2 w-full sm:w-auto justify-center">
                        <i class="pi pi-github"></i> Ver o repositório
                    </a>
                    <a href="/#arquitetura" (click)="nav.ir('arquitetura', $event)" class="landing-button-secondary rounded-xl! px-6! py-3! inline-flex items-center gap-2 w-full sm:w-auto justify-center">
                        Como funciona <i class="pi pi-arrow-down text-sm!"></i>
                    </a>
                </div>
                <ul reveal [revealDelay]="300" class="mt-7 flex flex-wrap justify-center gap-x-6 gap-y-2 text-sm text-surface-500">
                    @for (t of garantias; track t) {
                        <li class="flex items-center gap-2"><i class="pi pi-check-circle text-primary-500 text-sm!"></i>{{ t }}</li>
                    }
                </ul>

                <div reveal [revealDelay]="360" class="relative mt-16 md:mt-20 px-1 md:px-6">
                    <div class="relative rounded-3xl bg-surface-50 dark:bg-surface-950 p-2 md:p-3 border">
                        <animated-border />
                        <cluster-console />
                    </div>

                    <div class="hidden 2xl:flex absolute -left-24 top-14 items-center gap-3 rounded-2xl border bg-surface-0/95 dark:bg-surface-900/95 backdrop-blur px-4 py-3 shadow-stroke animate-[float_6s_ease-in-out_infinite]">
                        <span class="w-9 h-9 rounded-xl bg-emerald-500/15 text-emerald-600 dark:text-emerald-300 flex items-center justify-center"><i class="pi pi-lock"></i></span>
                        <span class="text-sm leading-tight"><span class="font-medium block">MQTT com TLS</span><span class="text-xs text-surface-500">v4 · porta 8883</span></span>
                    </div>
                    <div class="hidden 2xl:flex absolute -right-24 -bottom-5 items-center gap-3 rounded-2xl border bg-surface-0/95 dark:bg-surface-900/95 backdrop-blur px-4 py-3 shadow-stroke animate-[float_7s_ease-in-out_infinite_1s]">
                        <span class="w-9 h-9 rounded-xl bg-primary-500/15 text-primary-600 dark:text-primary-300 flex items-center justify-center"><i class="pi pi-database"></i></span>
                        <span class="text-sm leading-tight"><span class="font-medium block">Dados no OCI FSS</span><span class="text-xs text-surface-500">PostgreSQL e Redis persistentes</span></span>
                    </div>
                    <p class="text-center text-xs text-surface-400 mt-4">Ilustração · nomes dos Deployments reais, dados de rádio fictícios</p>
                </div>
            </div>

            <div class="marquee relative mt-14 overflow-hidden [mask-image:linear-gradient(to_right,transparent,#000_12%,#000_88%,transparent)]">
                <div class="marquee-track flex w-max gap-3">
                    @for (t of faixa; track $index) {
                        <span class="whitespace-nowrap rounded-full border px-4 py-2 text-sm text-surface-600 dark:text-surface-300 bg-surface-0 dark:bg-surface-900">{{ t }}</span>
                    }
                </div>
            </div>
        </section>
    `
})
export class HomeHero {
    readonly nav = inject(NavService);
    readonly repo = REPOSITORIO;
    readonly garantias = ['Infraestrutura como código', 'v3 e v4 lado a lado', "HTTPS automático com Let's Encrypt"];
    readonly faixa = [...FAIXA_TECNOLOGIAS, ...FAIXA_TECNOLOGIAS];
}
