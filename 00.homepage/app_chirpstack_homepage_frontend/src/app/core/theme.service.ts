import { Injectable, signal } from '@angular/core';

const CHAVE = 'site-tema';

/**
 * Tema claro/escuro.
 * Padrão: segue o sistema operacional. Se o visitante escolher manualmente, a escolha é lembrada.
 */
@Injectable({ providedIn: 'root' })
export class ThemeService {
    readonly escuro = signal<boolean>(document.documentElement.classList.contains('app-dark'));

    private readonly midia = window.matchMedia('(prefers-color-scheme: dark)');

    constructor() {
        this.midia.addEventListener('change', (e) => {
            if (!this.escolhaSalva()) {
                this.aplicar(e.matches);
            }
        });
    }

    alternar(): void {
        const novo = !this.escuro();
        try {
            localStorage.setItem(CHAVE, novo ? 'escuro' : 'claro');
        } catch {
            /* navegação privada: apenas não lembra */
        }
        this.aplicar(novo);
    }

    private escolhaSalva(): string | null {
        try {
            return localStorage.getItem(CHAVE);
        } catch {
            return null;
        }
    }

    private aplicar(escuro: boolean): void {
        const executar = () => {
            document.documentElement.classList.toggle('app-dark', escuro);
            this.escuro.set(escuro);
        };
        const doc = document as Document & { startViewTransition?: (cb: () => void) => unknown };
        if (doc.startViewTransition && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            doc.startViewTransition(executar);
        } else {
            executar();
        }
    }
}
