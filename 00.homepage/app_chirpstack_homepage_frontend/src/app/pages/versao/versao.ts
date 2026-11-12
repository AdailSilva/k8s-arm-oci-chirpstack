import { Component, computed, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';
import { SurfaceLine } from '@/app/shared/surface-line';
import { SectionHeader } from '@/app/shared/section-header';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { NavService } from '@/app/layout/nav.service';
import { REPOSITORIO, VERSOES, Versao } from '@/app/core/site.config';

/** Página de detalhe de uma versão (/v3 ou /v4). A versão vem do `data.versao` da rota. */
@Component({
    selector: 'versao-page',
    standalone: true,
    imports: [SurfaceLine, SectionHeader, RevealDirective],
    template: `
        @let v = versao();
        <section class="relative overflow-hidden pt-36 md:pt-48 pb-10">
            <div class="absolute inset-x-0 top-0 h-[600px] bg-grid pointer-events-none"></div>
            <surface-line class="top-16 -left-36 2xl:left-0 md:w-[36vw]" />
            <surface-line class="top-16 -right-36 2xl:right-0 md:w-[36vw] scale-x-[-1]" />
            <div class="landing-container relative text-center">
                <div reveal class="w-fit mx-auto mb-6 rounded-full border bg-surface-0/80 dark:bg-surface-900/80 backdrop-blur px-4 py-1.5 flex items-center gap-2 text-sm">
                    <span class="relative flex w-2 h-2"><span class="absolute inset-0 rounded-full bg-emerald-400 ping-soft"></span><span class="relative w-2 h-2 rounded-full bg-emerald-500"></span></span>
                    <span class="font-mono text-surface-600 dark:text-surface-300">ns/{{ v.namespace }}</span>
                </div>
                <h1 reveal [revealDelay]="80" class="text-4xl md:text-6xl font-medium leading-[115%]! tracking-tight max-w-4xl mx-auto"><span class="text-gradient">{{ v.nome }}</span> na OCI Always Free</h1>
                <p reveal [revealDelay]="160" class="mt-6 text-base md:text-xl text-surface-500 max-w-3xl mx-auto leading-7 md:leading-8">{{ v.descricao }}</p>
                <div reveal [revealDelay]="220" class="mt-8 flex flex-col sm:flex-row gap-3 justify-center">
                    <a [href]="repo.url + '/tree/master/' + v.pasta" target="_blank" rel="noopener" class="landing-button-primary rounded-xl! px-6! py-3! inline-flex items-center justify-center gap-2"><i class="pi pi-github"></i> Pasta {{ v.pasta }}</a>
                    <a [href]="outra().rota" (click)="nav.ir(outra().rota, $event)" class="landing-button-secondary rounded-xl! px-6! py-3! inline-flex items-center justify-center gap-2">Ver {{ outra().nome }} <i class="pi pi-arrow-right text-sm!"></i></a>
                </div>
            </div>
        </section>

        <!-- componentes -->
        <section class="landing-container pt-10">
            <section-header selo="Componentes" icone="pi pi-th-large" [subtitulo]="v.arquitetura">O que roda no namespace</section-header>
            <div class="mt-12 grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
                @for (c of v.componentes; track c.nome; let i = $index) {
                    <div reveal [revealDelay]="(i % 4) * 70" class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                        <div class="h-full p-5 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                            <span class="w-10 h-10 rounded-xl bg-primary-500/10 text-primary-600 dark:text-primary-300 flex items-center justify-center"><i [class]="c.icone"></i></span>
                            <div class="mt-4 font-medium">{{ c.nome }}</div>
                            <div class="mt-1 text-xs font-mono text-surface-500 break-all">{{ c.imagem }}</div>
                            <p class="mt-3 text-sm text-surface-600 dark:text-surface-300">{{ c.papel }}</p>
                            <span class="mt-3 inline-flex text-[11px] font-mono rounded-md px-2 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300">{{ c.portas }}</span>
                        </div>
                    </div>
                }
            </div>
        </section>

        <!-- acesso + deploy -->
        <section class="landing-container pt-20 md:pt-28">
            <div class="grid lg:grid-cols-2 gap-5">
                <div reveal class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                    <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                        <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-sign-in text-primary-500"></i>Acesso</h3>
                        <ul class="mt-5 space-y-3">
                            @for (a of v.acessos; track a.rotulo) {
                                <li class="rounded-2xl border p-4">
                                    <div class="text-xs text-surface-500">{{ a.rotulo }}</div>
                                    @if (a.link) {
                                        <a [href]="'https://' + a.endereco" target="_blank" rel="noopener" class="mt-1 font-mono text-sm text-primary-600 dark:text-primary-300 break-all inline-flex items-center gap-1.5 hover:underline">{{ a.endereco }} <i class="pi pi-arrow-up-right text-[10px]!"></i></a>
                                    } @else {
                                        <div class="mt-1 font-mono text-sm break-all">{{ a.endereco }}</div>
                                    }
                                    <div class="mt-1 text-xs text-surface-500">{{ a.observacao }}</div>
                                </li>
                            }
                        </ul>
                        <p class="mt-5 text-sm text-surface-500 flex items-center gap-2"><i class="pi pi-database text-sm!"></i>Armazenamento: {{ v.armazenamento }}</p>
                    </div>
                </div>

                <div reveal [revealDelay]="100" class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                    <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                        <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-play text-primary-500"></i>Implantação na ordem certa</h3>
                        <p class="mt-1 text-sm text-surface-500">Manifests em <code class="font-mono text-xs">{{ v.pasta }}/kubernetes/</code> — ou tudo de uma vez com o script.</p>
                        <ol class="mt-5 relative border-l border-surface-200 dark:border-surface-700 ml-3 space-y-4">
                            @for (p of v.passos; track p.titulo; let i = $index) {
                                <li class="pl-6 relative">
                                    <span class="absolute -left-3 top-0 w-6 h-6 rounded-full bg-primary-500 text-white text-[11px] font-semibold flex items-center justify-center">{{ i + 1 }}</span>
                                    <span class="font-medium text-sm">{{ p.titulo }}</span>
                                    <span class="ml-2 text-[11px] font-mono rounded-md px-1.5 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-500">{{ p.arquivos }}</span>
                                </li>
                            }
                        </ol>
                        <div class="mt-6 rounded-xl bg-[#0b1020] text-teal-200 font-mono text-[12px] p-4 overflow-x-auto">
                            <div class="whitespace-nowrap">cd {{ v.pasta }}/00.UsefulScripts/</div>
                            <div class="whitespace-nowrap">bash {{ v.scripts[0] }}</div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- recursos -->
        <section class="landing-container pt-20 md:pt-28">
            <section-header selo="Kubernetes" icone="pi pi-box" subtitulo="Principais recursos criados pelos manifests desta versão.">Recursos do namespace {{ v.namespace }}</section-header>
            <div reveal class="mt-12 p-2 rounded-[2rem] bg-surface-50 dark:bg-surface-950 border">
                <div class="rounded-3xl bg-surface-0 dark:bg-surface-900 shadow-stroke overflow-x-auto">
                    <table class="w-full text-sm min-w-[620px]">
                        <thead>
                            <tr class="text-left text-surface-500">
                                <th class="p-4 md:p-5 font-medium">Kind</th>
                                <th class="p-4 md:p-5 font-medium">Nome</th>
                                <th class="p-4 md:p-5 font-medium">Detalhe</th>
                            </tr>
                        </thead>
                        <tbody>
                            @for (r of v.recursos; track r.nome) {
                                <tr class="border-t">
                                    <td class="p-4 md:px-5"><span class="text-[11px] rounded-md px-2 py-0.5 bg-primary-500/10 text-primary-700 dark:text-primary-300">{{ r.kind }}</span></td>
                                    <td class="p-4 md:px-5 font-mono text-xs break-all">{{ r.nome }}</td>
                                    <td class="p-4 md:px-5 text-surface-500">{{ r.detalhe }}</td>
                                </tr>
                            }
                        </tbody>
                    </table>
                </div>
            </div>

            <div reveal class="mt-6 grid sm:grid-cols-2 lg:grid-cols-4 gap-3">
                @for (s of v.scripts; track s) {
                    <div class="rounded-2xl border p-4 flex items-center gap-3">
                        <i class="pi pi-file text-primary-500"></i>
                        <span class="font-mono text-xs break-all">{{ s }}</span>
                    </div>
                }
            </div>
        </section>
    `
})
export class VersaoPage {
    readonly nav = inject(NavService);
    readonly repo = REPOSITORIO;

    private readonly id = toSignal(inject(ActivatedRoute).data.pipe(map((d) => (d['versao'] as Versao['id']) ?? 'v4')), { initialValue: 'v4' as Versao['id'] });

    readonly versao = computed(() => VERSOES.find((v) => v.id === this.id()) ?? VERSOES[1]);
    readonly outra = computed(() => VERSOES.find((v) => v.id !== this.id()) ?? VERSOES[0]);
}
