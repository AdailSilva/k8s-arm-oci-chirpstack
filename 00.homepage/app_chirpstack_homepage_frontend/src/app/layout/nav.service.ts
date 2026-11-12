import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';

export interface ItemNav {
    rotulo: string;
    /** Âncora da home (ex.: 'solucoes') ou rota absoluta (ex.: '/infraestrutura'). */
    destino: string;
}

export const ITENS_NAV: ItemNav[] = [
    { rotulo: 'Arquitetura', destino: 'arquitetura' },
    { rotulo: 'v3 × v4', destino: 'comparativo' },
    { rotulo: 'LoRaWAN', destino: 'lorawan' },
    { rotulo: 'MQTT', destino: 'mqtt' },
    { rotulo: 'ChirpStack v3', destino: '/v3' },
    { rotulo: 'ChirpStack v4', destino: '/v4' },
    { rotulo: 'Infraestrutura', destino: '/infraestrutura' }
];

@Injectable({ providedIn: 'root' })
export class NavService {
    private readonly router = inject(Router);

    href(destino: string): string {
        return destino.startsWith('/') ? destino : `/#${destino}`;
    }

    /** Navega para uma âncora da home (rolando suavemente) ou para uma rota. */
    ir(destino: string, evento?: Event): void {
        evento?.preventDefault();

        if (destino.startsWith('/')) {
            this.router.navigateByUrl(destino);
            return;
        }

        const naHome = this.router.url.split('#')[0].split('?')[0] === '/';
        if (naHome) {
            const alvo = document.getElementById(destino);
            if (alvo) {
                alvo.scrollIntoView({ behavior: 'smooth', block: 'start' });
                history.replaceState(null, '', `/#${destino}`);
                return;
            }
        }
        this.router.navigate(['/'], { fragment: destino });
    }

    topo(evento?: Event): void {
        evento?.preventDefault();
        if (this.router.url.split('#')[0] === '/') {
            window.scrollTo({ top: 0, behavior: 'smooth' });
            history.replaceState(null, '', '/');
        } else {
            this.router.navigateByUrl('/');
        }
    }
}
