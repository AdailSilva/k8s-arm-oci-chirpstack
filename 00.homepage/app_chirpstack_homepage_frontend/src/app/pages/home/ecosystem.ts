import { Component, inject } from '@angular/core';
import { SectionHeader } from '@/app/shared/section-header';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { NavService } from '@/app/layout/nav.service';
import { APLICACOES, CLUSTER } from '@/app/core/site.config';

/** Aplicações do repositório (Manager e Consumer) + chamada para a infraestrutura. */
@Component({
    selector: 'home-ecosystem',
    standalone: true,
    imports: [SectionHeader, RevealDirective],
    template: `
        <section id="aplicacoes" class="relative pt-24 md:pt-36">
            <div class="landing-container">
                <section-header selo="Ecossistema" icone="pi pi-th-large" subtitulo="Além dos servidores de rede, o repositório traz aplicações próprias que usam o ChirpStack.">Aplicações em cima do ChirpStack</section-header>

                <div class="mt-12 grid lg:grid-cols-2 gap-5">
                    @for (a of aplicacoes; track a.nome; let i = $index) {
                        <div reveal [revealDelay]="i * 100" class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                            <div class="h-full flex flex-col p-6 md:p-8 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                                <div class="flex items-center gap-3">
                                    <span class="w-12 h-12 rounded-2xl bg-primary-500/10 text-primary-600 dark:text-primary-300 flex items-center justify-center"><i [class]="a.icone" class="text-xl!"></i></span>
                                    <span class="leading-tight">
                                        <span class="block text-xl font-medium">{{ a.nome }}</span>
                                        <span class="block text-xs font-mono text-surface-500 mt-1">{{ a.pasta }}/</span>
                                    </span>
                                </div>
                                <p class="mt-5 text-surface-600 dark:text-surface-300 leading-7 flex-1">{{ a.descricao }}</p>
                                <div class="mt-5 flex flex-wrap gap-2">
                                    @for (s of a.stack; track s) {
                                        <span class="text-xs rounded-lg border px-2.5 py-1 text-surface-600 dark:text-surface-300">{{ s }}</span>
                                    }
                                </div>
                                <a [href]="a.url" target="_blank" rel="noopener" class="mt-6 text-sm font-medium text-primary-600 dark:text-primary-300 inline-flex items-center gap-2 hover:gap-3 transition-all">Abrir <i class="pi pi-arrow-up-right text-xs!"></i></a>
                            </div>
                        </div>
                    }
                </div>

                <div reveal class="mt-6 relative overflow-hidden rounded-[2rem] border p-2 bg-surface-50 dark:bg-surface-950">
                    <div class="relative overflow-hidden rounded-3xl p-8 md:p-12 bg-surface-950 text-surface-0">
                        <div class="absolute inset-0 opacity-40 [background-image:radial-gradient(circle_at_85%_20%,var(--p-primary-600),transparent_45%),radial-gradient(circle_at_10%_90%,#0284c7,transparent_40%)]"></div>
                        <div class="relative grid lg:grid-cols-2 gap-10 items-center">
                            <div>
                                <span class="inline-flex items-center gap-2 rounded-full border border-white/15 px-3 py-1 text-sm text-surface-300">
                                    <span class="relative flex w-2 h-2"><span class="absolute inset-0 rounded-full bg-emerald-400 ping-soft"></span><span class="relative w-2 h-2 rounded-full bg-emerald-500"></span></span>
                                    {{ cluster.regiao }}
                                </span>
                                <h3 class="mt-5 text-3xl md:text-4xl font-medium leading-tight">4 OCPUs e 24 GB de RAM, exatamente no limite Always Free</h3>
                                <p class="mt-4 text-surface-300 leading-7">Kubernetes {{ cluster.kubernetes }} com kubeadm em {{ cluster.nos }} nós {{ cluster.arquitetura }}, Network Load Balancer com IP reservado, OCI File Storage para os bancos e tudo descrito em Terraform/OpenTofu.</p>
                                <a href="/infraestrutura" (click)="nav.ir('/infraestrutura', $event)" class="mt-7 inline-flex items-center gap-2 rounded-full bg-white text-surface-950 px-5 py-2.5 font-medium hover:bg-surface-200 transition-colors">
                                    Ver a infraestrutura <i class="pi pi-arrow-right text-sm!"></i>
                                </a>
                            </div>
                            <div class="grid grid-cols-2 gap-3">
                                @for (n of cluster.nosDetalhe; track n.nome) {
                                    <div class="rounded-2xl border border-white/10 bg-white/5 backdrop-blur p-4">
                                        <div class="flex items-center justify-between">
                                            <i class="pi pi-server text-surface-300"></i>
                                            <span class="text-[11px] rounded-full px-2 py-0.5 bg-white/10 text-surface-300">A1.Flex</span>
                                        </div>
                                        <div class="mt-4 font-mono text-sm">{{ n.nome }}</div>
                                        <div class="text-xs text-surface-400 mt-0.5">{{ n.papel }}</div>
                                    </div>
                                }
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `
})
export class HomeEcosystem {
    readonly nav = inject(NavService);
    readonly aplicacoes = APLICACOES;
    readonly cluster = CLUSTER;
}
