import { Directive, ElementRef, OnDestroy, OnInit, inject, input } from '@angular/core';

/**
 * Animação de entrada ao rolar a página.
 * Uso: <div reveal [revealDelay]="120">…</div>
 */
@Directive({
    selector: '[reveal]',
    standalone: true,
    host: { class: 'reveal' }
})
export class RevealDirective implements OnInit, OnDestroy {
    revealDelay = input<number>(0);

    private readonly el = inject(ElementRef<HTMLElement>);
    private observer?: IntersectionObserver;

    ngOnInit(): void {
        const elemento = this.el.nativeElement as HTMLElement;
        elemento.style.setProperty('--reveal-delay', `${this.revealDelay()}ms`);

        if (typeof IntersectionObserver === 'undefined') {
            elemento.classList.add('revealed');
            return;
        }

        this.observer = new IntersectionObserver(
            (entradas) => {
                for (const entrada of entradas) {
                    if (entrada.isIntersecting) {
                        elemento.classList.add('revealed');
                        this.observer?.disconnect();
                    }
                }
            },
            { threshold: 0.12, rootMargin: '0px 0px -40px 0px' }
        );
        this.observer.observe(elemento);
    }

    ngOnDestroy(): void {
        this.observer?.disconnect();
    }
}
