import { Component, inject } from '@angular/core';
import { SurfaceLine } from '@/app/shared/surface-line';
import { SectionHeader } from '@/app/shared/section-header';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { NavService } from '@/app/layout/nav.service';
import { CLUSTER, REPOSITORIO } from '@/app/core/site.config';

@Component({
    selector: 'infraestrutura-page',
    standalone: true,
    imports: [SurfaceLine, SectionHeader, RevealDirective],
    template: `
        <section class="relative overflow-hidden pt-36 md:pt-48 pb-10">
            <div class="absolute inset-x-0 top-0 h-[600px] bg-grid pointer-events-none"></div>
            <surface-line class="top-16 -left-36 2xl:left-0 md:w-[36vw]" />
            <surface-line class="top-16 -right-36 2xl:right-0 md:w-[36vw] scale-x-[-1]" />
            <div class="landing-container relative text-center">
                <div reveal class="w-fit mx-auto mb-6 rounded-full border bg-surface-0/80 dark:bg-surface-900/80 backdrop-blur px-4 py-1.5 flex items-center gap-2 text-sm">
                    <span class="relative flex w-2 h-2"><span class="absolute inset-0 rounded-full bg-emerald-400 ping-soft"></span><span class="relative w-2 h-2 rounded-full bg-emerald-500"></span></span>
                    <span class="font-mono text-surface-600 dark:text-surface-300">{{ c.regiao }}</span>
                </div>
                <h1 reveal [revealDelay]="80" class="text-4xl md:text-6xl font-medium leading-[115%]! tracking-tight max-w-4xl mx-auto">Kubernetes ARM64 na <span class="text-gradient">OCI Always Free</span></h1>
                <p reveal [revealDelay]="160" class="mt-6 text-base md:text-xl text-surface-500 max-w-3xl mx-auto leading-7 md:leading-8">
                    Cluster kubeadm provisionado do zero com Terraform/OpenTofu: compartimento, rede, Network Load Balancer, instâncias Ampere A1, bootstrap do Kubernetes e aplicações de scaffold — sem nenhum custo.
                </p>
            </div>
        </section>

        <section class="landing-container">
            <div class="rounded-[2rem] border p-2 bg-surface-50 dark:bg-surface-950">
                <div class="grid grid-cols-2 lg:grid-cols-4 rounded-3xl bg-surface-0 dark:bg-surface-900 shadow-stroke overflow-hidden">
                    @for (s of resumo; track s.rotulo; let i = $index) {
                        <div reveal [revealDelay]="i * 80" class="p-6 md:p-8" [class.border-l]="i % 2 === 1 || i > 1" [class.lg:border-l]="i > 0" [class.border-t]="i > 1" [class.lg:border-t-0]="i > 1">
                            <i [class]="s.icone" class="text-primary-500"></i>
                            <div class="mt-3 text-3xl md:text-4xl font-medium tracking-tight">{{ s.valor }}</div>
                            <div class="mt-1 text-sm text-surface-500">{{ s.rotulo }}</div>
                        </div>
                    }
                </div>
            </div>
        </section>

        <section class="landing-container pt-20 md:pt-28">
            <section-header selo="Arquitetura" icone="pi pi-sitemap" subtitulo="Um control plane e três workers VM.Standard.A1.Flex atrás de um Network Load Balancer com IP público reservado.">Como o cluster é montado</section-header>

            <div class="mt-12 grid lg:grid-cols-5 gap-5">
                <div reveal class="lg:col-span-2 p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                    <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                        <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-server text-primary-500"></i>Nós</h3>
                        <ul class="mt-5 space-y-3">
                            @for (n of c.nosDetalhe; track n.nome) {
                                <li class="flex items-center gap-3 rounded-2xl border p-3">
                                    <span class="w-10 h-10 rounded-xl bg-surface-100 dark:bg-surface-800 flex items-center justify-center"><i class="pi pi-server"></i></span>
                                    <span class="flex-1 leading-tight">
                                        <span class="block font-mono text-sm">{{ n.nome }}</span>
                                        <span class="block text-xs text-surface-500">{{ n.papel }}</span>
                                    </span>
                                    <span class="text-[11px] rounded-full px-2 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300">ARM64</span>
                                </li>
                            }
                        </ul>
                        <h4 class="mt-6 text-sm font-semibold uppercase tracking-wider text-surface-400">Network Load Balancer</h4>
                        <ul class="mt-3 space-y-1.5 text-sm">
                            @for (p of c.portasNlb; track p.porta) {
                                <li class="flex items-center justify-between gap-3 border-b border-dashed border-surface-200 dark:border-surface-700 pb-1.5">
                                    <span class="font-mono text-xs">{{ p.porta }}</span>
                                    <span class="text-surface-500 text-xs text-right">{{ p.uso }} → {{ p.destino }}</span>
                                </li>
                            }
                        </ul>
                    </div>
                </div>
                <div reveal [revealDelay]="100" class="lg:col-span-3 p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                    <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                        <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-th-large text-primary-500"></i>Componentes</h3>
                        <div class="mt-5 grid sm:grid-cols-2 gap-3">
                            @for (k of c.componentes; track k.nome) {
                                <div class="flex items-start gap-3 rounded-2xl border p-3">
                                    <span class="shrink-0 w-9 h-9 rounded-lg bg-primary-500/10 text-primary-600 dark:text-primary-300 flex items-center justify-center"><i [class]="k.icone" class="text-sm!"></i></span>
                                    <span class="leading-tight">
                                        <span class="block text-xs text-surface-500">{{ k.nome }}</span>
                                        <span class="block font-medium text-sm mt-0.5">{{ k.valor }}</span>
                                    </span>
                                </div>
                            }
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <section class="landing-container pt-20 md:pt-28">
            <section-header selo="Terraform / OpenTofu" icone="pi pi-code" subtitulo="Módulos executados em sequência por um único apply (recomendado: -parallelism=1).">Infraestrutura como código</section-header>
            <div class="mt-12 grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
                @for (m of c.modulos; track m.nome; let i = $index) {
                    <div reveal [revealDelay]="(i % 3) * 80" class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                        <div class="h-full p-5 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke flex items-start gap-4">
                            <span class="shrink-0 w-9 h-9 rounded-lg bg-surface-100 dark:bg-surface-800 flex items-center justify-center font-mono text-sm">{{ i + 1 }}</span>
                            <span class="leading-tight">
                                <span class="block font-mono text-sm">{{ m.nome }}</span>
                                <span class="block text-sm text-surface-500 mt-1">{{ m.papel }}</span>
                            </span>
                        </div>
                    </div>
                }
            </div>
        </section>

        <section class="landing-container pt-20 md:pt-28">
            <section-header selo="CI/CD" icone="pi pi-sync" subtitulo="GitHub Actions com runner self-hosted ARM64 no próprio cluster: cada alteração numa pasta de aplicação gera uma nova versão e atualiza o cluster.">Do commit ao cluster</section-header>
            <ol class="mt-12 grid md:grid-cols-5 gap-4 relative">
                <div class="hidden md:block absolute top-8 left-[10%] right-[10%] h-px bg-gradient-to-r from-transparent via-primary-500/40 to-transparent"></div>
                @for (p of c.pipeline; track p.titulo; let i = $index) {
                    <li reveal [revealDelay]="i * 100" class="relative flex md:flex-col items-center md:text-center gap-4 md:gap-0">
                        <span class="relative z-10 shrink-0 w-16 h-16 rounded-2xl border bg-surface-0 dark:bg-surface-900 shadow-stroke flex items-center justify-center"><i [class]="p.icone" class="text-primary-500 text-xl!"></i></span>
                        <span class="md:mt-4">
                            <span class="block font-medium">{{ p.titulo }}</span>
                            <span class="block text-sm text-surface-500 mt-1">{{ p.descricao }}</span>
                        </span>
                    </li>
                }
            </ol>

            <div reveal class="mt-16 text-center">
                <p class="text-surface-500">Tudo isso está documentado, comando por comando, no README.</p>
                <a [href]="repo.readme" target="_blank" rel="noopener" class="mt-4 landing-button-primary rounded-xl! px-6! py-3! inline-flex items-center gap-2"><i class="pi pi-book"></i> Ler o README</a>
            </div>
        </section>
    `
})
export class Infraestrutura {
    readonly nav = inject(NavService);
    readonly c = CLUSTER;
    readonly repo = REPOSITORIO;
    readonly resumo = [
        { valor: String(CLUSTER.nos), rotulo: 'nós ARM64 (1 control plane + 3 workers)', icone: 'pi pi-server' },
        { valor: String(CLUSTER.vcpus), rotulo: 'OCPUs Ampere A1', icone: 'pi pi-microchip' },
        { valor: `${CLUSTER.memoriaGb} GB`, rotulo: 'de memória no cluster', icone: 'pi pi-database' },
        { valor: CLUSTER.kubernetes, rotulo: 'versão do Kubernetes', icone: 'pi pi-box' }
    ];
}
