import { Component, signal } from '@angular/core';
import { SectionHeader } from '@/app/shared/section-header';
import { RevealDirective } from '@/app/shared/reveal.directive';
import { CLASSES, EXEMPLO_DOWNLINK_V3, EXEMPLO_DOWNLINK_V4, SUB_BANDAS, TOPICOS_MQTT } from '@/app/core/site.config';

/** Plano AU915, classes de dispositivos e downlinks via MQTT. */
@Component({
    selector: 'home-lorawan',
    standalone: true,
    imports: [SectionHeader, RevealDirective],
    template: `
        <section id="lorawan" class="relative pt-24 md:pt-36">
            <div class="landing-container">
                <section-header selo="LoRaWAN no Brasil" icone="pi pi-wifi" subtitulo="Plano regional AU915 (915–928 MHz, regulamentado pela ANATEL): 72 canais de uplink em 8 sub-bandas. Gateways e dispositivos deste projeto usam a sub-banda 1.">
                    AU915, sub-bandas<br class="hidden md:block" />
                    e classes de dispositivos
                </section-header>

                <div class="mt-12 grid lg:grid-cols-5 gap-5">
                    <!-- sub-bandas -->
                    <div reveal class="lg:col-span-3 p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                        <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                            <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-chart-bar text-primary-500"></i>Sub-bandas de uplink</h3>
                            <p class="mt-1 text-sm text-surface-500">Cada sub-banda: 8 canais BW125 (SF7–SF12) + 1 canal BW500 (SF8, usado no JOIN).</p>
                            <div class="mt-6 grid grid-cols-8 gap-1.5 items-end h-36">
                                @for (b of subBandas; track b.id; let i = $index) {
                                    <div class="flex flex-col items-center gap-2 h-full justify-end">
                                        <div class="w-full rounded-t-lg grow-bar" [style.animation-delay]="i * 60 + 'ms'" [style.height]="b.usada ? '100%' : '42%'" [class]="b.usada ? 'bg-gradient-to-t from-primary-600 to-primary-400 shadow-[0_0_24px_-4px_var(--p-primary-500)]' : 'bg-surface-200 dark:bg-surface-700'"></div>
                                        <span class="text-[10px] font-mono" [class]="b.usada ? 'text-primary-600 dark:text-primary-300 font-semibold' : 'text-surface-400'">{{ i }}</span>
                                    </div>
                                }
                            </div>
                            <div class="mt-6 rounded-2xl border border-primary-500/30 bg-primary-500/5 p-4 grid sm:grid-cols-3 gap-3 text-sm">
                                <div><span class="block text-xs text-surface-500">Sub-banda</span><span class="font-mono font-medium">{{ usada.id }}</span></div>
                                <div><span class="block text-xs text-surface-500">Canais</span><span class="font-mono font-medium">{{ usada.canais }} + {{ usada.bw500 }}</span></div>
                                <div><span class="block text-xs text-surface-500">Frequências BW125</span><span class="font-mono font-medium">{{ usada.faixa }} MHz</span></div>
                            </div>
                            <ul class="mt-5 space-y-2 text-sm text-surface-600 dark:text-surface-300">
                                <li class="flex gap-2"><i class="pi pi-angle-right text-primary-500 mt-1 text-xs!"></i><span>v3: <code class="font-mono text-xs">enabled_uplink_channels = [8 … 15, 65]</code> no Network Server</span></li>
                                <li class="flex gap-2"><i class="pi pi-angle-right text-primary-500 mt-1 text-xs!"></i><span>v4: arquivo de região <code class="font-mono text-xs">region_au915_1.toml</code></span></li>
                                <li class="flex gap-2"><i class="pi pi-angle-right text-primary-500 mt-1 text-xs!"></i><span>Downlink: 8 canais BW500 de 923.3 a 924.7 MHz (RX1/RX2)</span></li>
                            </ul>
                        </div>
                    </div>

                    <!-- classes -->
                    <div reveal [revealDelay]="100" class="lg:col-span-2 p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                        <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                            <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-mobile text-primary-500"></i>Classes A, B e C</h3>
                            <ul class="mt-5 space-y-3">
                                @for (c of classes; track c.id) {
                                    <li class="rounded-2xl border p-4">
                                        <div class="flex items-center gap-3">
                                            <span class="w-10 h-10 rounded-xl bg-primary-500/10 text-primary-600 dark:text-primary-300 flex items-center justify-center font-semibold">{{ c.id }}</span>
                                            <span class="flex-1 leading-tight">
                                                <span class="block font-medium">Class {{ c.id }} · {{ c.nome }}</span>
                                                <span class="block text-xs text-surface-500">{{ c.alimentacao }}</span>
                                            </span>
                                            <span class="flex gap-0.5" [attr.aria-label]="'Consumo ' + c.energia + ' de 3'">
                                                @for (n of [1, 2, 3]; track n) {
                                                    <i class="pi pi-bolt text-xs!" [class]="n <= c.energia ? 'text-amber-500' : 'text-surface-300 dark:text-surface-700'"></i>
                                                }
                                            </span>
                                        </div>
                                        <p class="mt-3 text-sm text-surface-600 dark:text-surface-300">{{ c.recepcao }}</p>
                                        <p class="mt-1 text-xs text-surface-500">Latência de downlink: {{ c.latencia }}</p>
                                    </li>
                                }
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <section id="mqtt" class="relative pt-24 md:pt-36">
            <div class="landing-container">
                <section-header selo="MQTT" icone="pi pi-megaphone" subtitulo="Uplinks chegam publicados no broker; downlinks são enfileirados publicando em command/down. Na v4 tudo passa por TLS.">Integração por tópicos MQTT</section-header>

                <div class="mt-12 grid lg:grid-cols-2 gap-5">
                    <div reveal class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                        <div class="h-full p-6 rounded-2xl bg-surface-0 dark:bg-surface-900 shadow-stroke">
                            <h3 class="font-medium text-lg flex items-center gap-2"><i class="pi pi-list text-primary-500"></i>Tópicos de aplicação</h3>
                            <ul class="mt-5 space-y-2.5">
                                @for (t of topicos; track t.topico) {
                                    <li class="flex items-start gap-3 rounded-xl border p-3">
                                        <span class="shrink-0 w-7 h-7 rounded-lg flex items-center justify-center" [class]="t.direcao === 'down' ? 'bg-amber-500/15 text-amber-600 dark:text-amber-300' : 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-300'">
                                            <i [class]="t.direcao === 'down' ? 'pi pi-arrow-down' : 'pi pi-arrow-up'" class="text-xs!"></i>
                                        </span>
                                        <span class="min-w-0 leading-tight">
                                            <span class="block font-mono text-xs break-all">{{ t.topico }}</span>
                                            <span class="block text-xs text-surface-500 mt-1">{{ t.descricao }}</span>
                                        </span>
                                    </li>
                                }
                            </ul>
                            <p class="mt-4 text-xs text-surface-500 leading-5">Na v4 o ID da aplicação é um UUID. Class A só recebe o downlink na janela RX1/RX2 após o próximo uplink.</p>
                        </div>
                    </div>

                    <div reveal [revealDelay]="100" class="p-2 rounded-3xl bg-surface-50 dark:bg-surface-950 border">
                        <div class="h-full flex flex-col rounded-2xl overflow-hidden bg-[#0b1020] text-surface-0">
                            <div class="flex items-center gap-1 p-2 border-b border-white/10">
                                @for (a of abas; track a) {
                                    <button type="button" (click)="aba.set(a)" class="px-3 py-1.5 rounded-lg text-sm font-mono transition-colors cursor-pointer" [class]="aba() === a ? 'bg-white/10 text-white' : 'text-surface-400 hover:text-white'">
                                        {{ a === 'v3' ? 'v3 · :1888' : 'v4 · TLS :8883' }}
                                    </button>
                                }
                                <span class="ml-auto pr-2 text-[11px] text-surface-400">downlink</span>
                            </div>
                            <pre class="flex-1 p-5 text-[12px] md:text-[13px] leading-6 font-mono overflow-x-auto text-teal-200 m-0"><code>{{ aba() === 'v3' ? exemploV3 : exemploV4 }}</code></pre>
                            <div class="px-5 pb-5 text-xs text-surface-400 leading-5">
                                <code class="text-surface-200">data</code> é o payload em Base64 (o ChirpStack cifra). <code class="text-surface-200">fPort</code> &gt; 0. Use <code class="text-surface-200">confirmed: true</code> para receber ACK.
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `
})
export class HomeLorawan {
    readonly subBandas = SUB_BANDAS;
    readonly usada = SUB_BANDAS.find((b) => b.usada)!;
    readonly classes = CLASSES;
    readonly topicos = TOPICOS_MQTT;
    readonly abas = ['v3', 'v4'] as const;
    readonly aba = signal<'v3' | 'v4'>('v4');
    readonly exemploV3 = EXEMPLO_DOWNLINK_V3;
    readonly exemploV4 = EXEMPLO_DOWNLINK_V4;
}
