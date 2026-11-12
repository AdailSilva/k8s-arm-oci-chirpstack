import { Component, inject } from '@angular/core';
import { SiteLogo } from '@/app/shared/logo';
import { SurfaceLine } from '@/app/shared/surface-line';
import { PERFIL, REPOSITORIO } from '@/app/core/site.config';
import { canais } from '@/app/core/contato.util';
import { ITENS_NAV, NavService } from './nav.service';

@Component({
    selector: '[footer]',
    standalone: true,
    imports: [SiteLogo, SurfaceLine],
    template: `
        <div class="relative pt-16 pb-10 overflow-hidden">
            <surface-line class="top-28 -left-72 2xl:-left-40 md:w-[48vw]" />
            <surface-line class="top-28 -right-72 2xl:-right-40 md:w-[48vw] scale-x-[-1]" />
            <div class="landing-container">
                <div class="rounded-[2rem] border p-2 bg-surface-50 dark:bg-surface-950">
                    <div class="rounded-3xl bg-surface-0 dark:bg-surface-900 shadow-stroke p-8 md:p-10">
                        <div class="flex flex-col lg:flex-row gap-10 lg:items-start justify-between">
                            <div class="max-w-sm">
                                <site-logo [comTexto]="true" [tamanho]="38" />
                                <p class="mt-4 text-surface-500 leading-6">ChirpStack v3 e v4 em Kubernetes ARM64 na Oracle Cloud, usando somente recursos Always Free — infraestrutura como código, documentada de ponta a ponta.</p>
                                <a [href]="repo.url" target="_blank" rel="noopener" class="mt-3 text-sm text-surface-500 hover:text-primary-600 dark:hover:text-primary-300 flex items-center gap-2"><i class="pi pi-github text-sm!"></i>AdailSilva/{{ repo.nome }}</a>
                                <p class="mt-2 text-sm text-surface-500 flex items-center gap-2"><i class="pi pi-map-marker text-sm!"></i>{{ perfil.nomeCompleto }} · {{ perfil.cidade }}</p>
                            </div>
                            <div class="grid grid-cols-2 gap-10 sm:gap-16">
                                <div>
                                    <h4 class="text-sm font-semibold uppercase tracking-wider text-surface-400">Navegação</h4>
                                    <ul class="mt-4 space-y-2.5">
                                        @for (item of itens; track item.destino) {
                                            <li>
                                                <a [href]="nav.href(item.destino)" (click)="nav.ir(item.destino, $event)" class="text-surface-600 dark:text-surface-300 hover:text-primary-600 dark:hover:text-primary-300 transition-colors">{{ item.rotulo }}</a>
                                            </li>
                                        }
                                        <li><a href="/#contato" (click)="nav.ir('contato', $event)" class="text-surface-600 dark:text-surface-300 hover:text-primary-600 dark:hover:text-primary-300 transition-colors">Contato</a></li>
                                        <li><a href="https://k8s.adailsilva.com.br" target="_blank" rel="noopener" class="text-surface-600 dark:text-surface-300 hover:text-primary-600 dark:hover:text-primary-300 transition-colors">Site do autor</a></li>
                                    </ul>
                                </div>
                                <div>
                                    <h4 class="text-sm font-semibold uppercase tracking-wider text-surface-400">Contato</h4>
                                    <ul class="mt-4 space-y-2.5">
                                        @for (c of canais; track c.id) {
                                            <li>
                                                <a [href]="c.href" target="_blank" rel="noopener" class="inline-flex items-center gap-2 text-surface-600 dark:text-surface-300 hover:text-primary-600 dark:hover:text-primary-300 transition-colors">
                                                    <i [class]="c.icone" class="text-sm!"></i>{{ c.rotulo }}
                                                </a>
                                            </li>
                                        }
                                    </ul>
                                </div>
                            </div>
                        </div>
                        <div class="mt-10 pt-6 border-t flex flex-col sm:flex-row gap-3 items-center justify-between text-sm text-surface-500">
                            <span>&copy; {{ ano }} {{ perfil.nomeCompleto }} · Licença {{ repo.licenca }} · ChirpStack é um projeto open-source independente.</span>
                            <a href="/infraestrutura" (click)="nav.ir('/infraestrutura', $event)" class="inline-flex items-center gap-2 hover:text-primary-600 dark:hover:text-primary-300">
                                <span class="relative flex w-2 h-2"><span class="absolute inset-0 rounded-full bg-emerald-400 ping-soft"></span><span class="relative w-2 h-2 rounded-full bg-emerald-500"></span></span>
                                Rodando no próprio cluster Always Free
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `
})
export class Footer {
    readonly nav = inject(NavService);
    readonly itens = ITENS_NAV;
    readonly canais = canais();
    readonly perfil = PERFIL;
    readonly repo = REPOSITORIO;
    readonly ano = new Date().getFullYear();
}
