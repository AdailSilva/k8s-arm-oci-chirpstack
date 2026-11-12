import { Component, input } from '@angular/core';
import { CAMADAS_REDE } from '@/app/core/site.config';

/**
 * Diagrama animado da rede LoRaWAN ponta a ponta:
 * end-devices → gateway → NLB da OCI → ChirpStack (Kubernetes) → aplicações.
 * Pontos verdes = uplink (dados subindo); pontos âmbar = downlink (comandos descendo).
 */
@Component({
    selector: 'lorawan-flow',
    standalone: true,
    template: `
        <div class="flex flex-col lg:flex-row items-stretch lg:items-center gap-0" [class.compacto]="compacto()">
            @for (c of camadas; track c.id; let i = $index; let ultimo = $last) {
                <div class="relative z-10 lg:flex-1 lg:max-w-[230px] rounded-2xl border bg-surface-0 dark:bg-surface-900 shadow-stroke p-4" [class.lg:p-5]="!compacto()">
                    <div class="flex items-center gap-3">
                        <span class="relative shrink-0 w-11 h-11 rounded-xl flex items-center justify-center" [class]="c.id === 'chirpstack' ? 'bg-emerald-500 text-white' : 'bg-primary-500/10 text-primary-600 dark:text-primary-300'">
                            <i [class]="c.icone"></i>
                            @if (c.id === 'chirpstack') {
                                <span class="absolute inset-0 rounded-xl border-2 border-emerald-400 ping-soft"></span>
                            }
                        </span>
                        <span class="leading-tight min-w-0">
                            <span class="block font-medium">{{ c.titulo }}</span>
                            <span class="block text-xs text-surface-500 truncate">{{ c.subtitulo }}</span>
                        </span>
                    </div>
                    @if (!compacto()) {
                        <p class="mt-3 text-sm text-surface-500 leading-5">{{ c.descricao }}</p>
                    }
                    <div class="mt-3 flex flex-wrap gap-1.5">
                        @for (t of c.tags; track t) {
                            <span class="text-[11px] rounded-md px-2 py-0.5 bg-surface-100 dark:bg-surface-800 text-surface-600 dark:text-surface-300">{{ t }}</span>
                        }
                    </div>
                </div>
                @if (!ultimo && c.enlace) {
                    <div class="conector relative shrink-0 self-center lg:self-auto lg:flex-1 lg:min-w-[64px] h-14 lg:h-auto w-px lg:w-auto flex items-center justify-center">
                        <span class="trilho absolute bg-gradient-to-b lg:bg-gradient-to-r from-primary-500/20 via-primary-500/60 to-primary-500/20"></span>
                        <span class="pacote up" [style.animation-delay]="i * 0.45 + 's'"></span>
                        <span class="pacote up" [style.animation-delay]="i * 0.45 + 1.1 + 's'"></span>
                        <span class="pacote down" [style.animation-delay]="i * 0.3 + 0.6 + 's'"></span>
                        <span class="rotulo relative z-10 whitespace-nowrap text-[10px] font-mono rounded-full border bg-surface-0 dark:bg-surface-900 px-2 py-0.5 text-surface-500">{{ c.enlace }}</span>
                    </div>
                }
            }
        </div>
    `,
    styles: [
        `
            :host {
                display: block;
            }
            .trilho {
                left: 50%;
                top: 0;
                bottom: 0;
                width: 2px;
                transform: translateX(-50%);
            }
            .rotulo {
                transform: translateX(14px);
            }
            .pacote {
                position: absolute;
                left: 50%;
                width: 8px;
                height: 8px;
                margin-left: -4px;
                border-radius: 9999px;
                opacity: 0;
            }
            .pacote.up {
                background: #10b981;
                box-shadow: 0 0 10px #10b981;
                animation: desce 2.2s linear infinite;
            }
            .pacote.down {
                background: #f59e0b;
                box-shadow: 0 0 10px #f59e0b;
                animation: sobe 3.3s linear infinite;
            }
            @keyframes desce {
                0% { top: 0; opacity: 0; }
                15% { opacity: 1; }
                85% { opacity: 1; }
                100% { top: calc(100% - 8px); opacity: 0; }
            }
            @keyframes sobe {
                0% { top: calc(100% - 8px); opacity: 0; }
                15% { opacity: 0.9; }
                85% { opacity: 0.9; }
                100% { top: 0; opacity: 0; }
            }
            @media (min-width: 992px) {
                .trilho {
                    top: 50%;
                    bottom: auto;
                    left: 0;
                    right: 0;
                    width: auto;
                    height: 2px;
                    transform: translateY(-50%);
                }
                .rotulo {
                    transform: translateY(-18px);
                }
                .pacote {
                    top: 50%;
                    left: auto;
                    margin-left: 0;
                    margin-top: -4px;
                }
                .pacote.up {
                    animation-name: direita;
                }
                .pacote.down {
                    animation-name: esquerda;
                }
                @keyframes direita {
                    0% { left: 0; opacity: 0; }
                    15% { opacity: 1; }
                    85% { opacity: 1; }
                    100% { left: calc(100% - 8px); opacity: 0; }
                }
                @keyframes esquerda {
                    0% { left: calc(100% - 8px); opacity: 0; }
                    15% { opacity: 0.9; }
                    85% { opacity: 0.9; }
                    100% { left: 0; opacity: 0; }
                }
            }
            @media (prefers-reduced-motion: reduce) {
                .pacote {
                    display: none;
                }
            }
        `
    ]
})
export class LorawanFlow {
    /** Versão enxuta (sem descrição) para a chamada da home. */
    compacto = input<boolean>(false);
    readonly camadas = CAMADAS_REDE;
}
