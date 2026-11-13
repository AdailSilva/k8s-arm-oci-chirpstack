import { Component, OnDestroy, OnInit, signal } from '@angular/core';

interface LinhaPod {
    ns: 'chirpstack-v3' | 'chirpstack-v4';
    nome: string;
    no: string;
}

/**
 * Ilustração do hero: terminal com `kubectl get pods` dos dois namespaces
 * e um painel de uplinks chegando pelo Gateway Bridge. Dados ilustrativos.
 */
@Component({
    selector: 'cluster-console',
    standalone: true,
    template: `
        <div class="grid lg:grid-cols-5 gap-2 md:gap-3">
            <!-- terminal -->
            <div class="lg:col-span-3 rounded-2xl overflow-hidden border border-surface-800 bg-[#0b1020] text-[12px] md:text-[13px] font-mono text-left">
                <div class="flex items-center gap-2 px-4 py-2.5 border-b border-white/10 bg-white/5">
                    <span class="w-3 h-3 rounded-full bg-red-400/80"></span>
                    <span class="w-3 h-3 rounded-full bg-amber-400/80"></span>
                    <span class="w-3 h-3 rounded-full bg-emerald-400/80"></span>
                    <span class="ml-3 text-surface-400 truncate">ubuntu&#64;leader: ~</span>
                </div>
                <div class="p-4 md:p-5 overflow-x-auto">
                    <div class="text-emerald-300 whitespace-nowrap">$ kubectl get pods -A -l 'app.kubernetes.io/part-of in (chirpstack)' -o wide</div>
                    <div class="mt-2 text-surface-500 whitespace-nowrap">NAMESPACE&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NAME&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;STATUS&nbsp;&nbsp;&nbsp;NODE</div>
                    @for (p of pods; track p.nome; let i = $index) {
                        <div class="whitespace-nowrap flex gap-0 linha" [style.animation-delay]="i * 0.12 + 's'">
                            <span class="shrink-0 inline-block w-[15ch]" [class]="p.ns === 'chirpstack-v3' ? 'text-sky-300' : 'text-teal-300'">{{ p.ns }}</span>
                            <span class="shrink-0 inline-block w-[46ch] text-surface-200">{{ p.nome }}</span>
                            <span class="shrink-0 inline-block w-[9ch] text-emerald-400">Running</span>
                            <span class="shrink-0 text-surface-400">{{ p.no }}</span>
                        </div>
                    }
                    <div class="mt-2 text-emerald-300">$ <span class="cursor">▍</span></div>
                </div>
            </div>

            <!-- uplinks -->
            <div class="lg:col-span-2 rounded-2xl border bg-surface-0 dark:bg-surface-900 p-4 md:p-5 text-left">
                <div class="flex items-center justify-between">
                    <span class="font-medium flex items-center gap-2"><i class="pi pi-wave-pulse text-primary-500"></i>Uplinks · AU915 sub-banda 1</span>
                    <span class="text-[11px] rounded-full px-2 py-0.5 bg-emerald-500/10 text-emerald-700 dark:text-emerald-300">ao vivo</span>
                </div>
                <ul class="mt-4 space-y-2">
                    @for (u of uplinks(); track u.id) {
                        <li class="rounded-xl border p-2.5 flex items-center gap-3 entrada">
                            <span class="w-8 h-8 shrink-0 rounded-lg flex items-center justify-center text-xs font-semibold" [class]="u.versao === 'v4' ? 'bg-teal-500/15 text-teal-700 dark:text-teal-300' : 'bg-sky-500/15 text-sky-700 dark:text-sky-300'">{{ u.versao }}</span>
                            <span class="min-w-0 flex-1 leading-tight">
                                <span class="block font-mono text-xs truncate">{{ u.eui }}</span>
                                <span class="block text-[11px] text-surface-500">{{ u.freq }} MHz · SF{{ u.sf }} · fCnt {{ u.fcnt }}</span>
                            </span>
                            <span class="text-[11px] font-mono text-surface-500">{{ u.rssi }} dBm</span>
                        </li>
                    }
                </ul>
                <p class="mt-3 text-[11px] text-surface-400">Gateway Bridge → MQTT → ChirpStack</p>
            </div>
        </div>
    `,
    styles: [
        `
            .linha {
                opacity: 0;
                animation: aparece 0.4s ease-out forwards;
            }
            .entrada {
                animation: aparece 0.45s ease-out;
            }
            .cursor {
                animation: pisca 1s steps(1) infinite;
            }
            @keyframes aparece {
                from {
                    opacity: 0;
                    transform: translateY(4px);
                }
                to {
                    opacity: 1;
                    transform: none;
                }
            }
            @keyframes pisca {
                50% {
                    opacity: 0;
                }
            }
            @media (prefers-reduced-motion: reduce) {
                .linha,
                .entrada,
                .cursor {
                    animation: none;
                    opacity: 1;
                }
            }
        `
    ]
})
export class ClusterConsole implements OnInit, OnDestroy {
    readonly pods: LinhaPod[] = [
        { ns: 'chirpstack-v3', nome: 'chirpstack-v3-gateway-bridge-deployment', no: 'worker-0' },
        { ns: 'chirpstack-v3', nome: 'chirpstack-v3-network-server-deployment', no: 'worker-1' },
        { ns: 'chirpstack-v3', nome: 'chirpstack-v3-application-server-deployment', no: 'worker-2' },
        { ns: 'chirpstack-v3', nome: 'chirpstack-v3-mosquitto-deployment', no: 'worker-1' },
        { ns: 'chirpstack-v4', nome: 'chirpstack-v4-gateway-bridge-deployment', no: 'worker-2' },
        { ns: 'chirpstack-v4', nome: 'chirpstack-v4-mosquitto-deployment', no: 'worker-0' },
        { ns: 'chirpstack-v4', nome: 'chirpstack-v4-deployment', no: 'worker-1' },
        { ns: 'chirpstack-v4', nome: 'chirpstack-v4-rest-api-deployment', no: 'worker-2' },
        { ns: 'chirpstack-v4', nome: 'chirpstack-v4-postgresql-deployment', no: 'worker-0' }
    ];

    private readonly freqs = ['916.8', '917.0', '917.2', '917.4', '917.6', '917.8', '918.0', '918.2'];
    private seq = 0;
    private timer?: ReturnType<typeof setInterval>;

    readonly uplinks = signal(Array.from({ length: 4 }, () => this.novo()));

    ngOnInit(): void {
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            return;
        }
        this.timer = setInterval(() => this.uplinks.update((l) => [this.novo(), ...l].slice(0, 4)), 2600);
    }

    ngOnDestroy(): void {
        clearInterval(this.timer);
    }

    private novo() {
        const n = ++this.seq;
        const hex = () => Math.floor(Math.random() * 256).toString(16).padStart(2, '0');
        return {
            id: n,
            versao: n % 3 === 0 ? 'v3' : 'v4',
            eui: `70b3d57ed0${hex()}${hex()}${hex()}`,
            freq: this.freqs[n % this.freqs.length],
            sf: 7 + (n % 4),
            fcnt: 1200 + n * 3,
            rssi: -(62 + ((n * 7) % 48))
        };
    }
}
