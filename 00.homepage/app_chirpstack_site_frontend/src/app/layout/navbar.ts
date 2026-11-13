import { Component, ElementRef, inject, signal, viewChild } from '@angular/core';
import { TooltipModule } from 'primeng/tooltip';
import { SiteLogo } from '@/app/shared/logo';
import { ThemeService } from '@/app/core/theme.service';
import { REPOSITORIO } from '@/app/core/site.config';
import { ITENS_NAV, NavService } from './nav.service';

@Component({
    selector: '[navbar]',
    standalone: true,
    imports: [SiteLogo, TooltipModule],
    host: {
        '(document:click)': 'fecharAoClicarFora($event)',
        '(window:scroll)': 'aoRolar()'
    },
    template: `
        <!-- Desktop -->
        <div class="lg:block hidden fixed top-5 left-1/2 -translate-x-1/2 z-50 w-[min(1184px,calc(100%-2rem))]">
            <div class="rounded-full border p-1.5 transition-all duration-300" [class]="rolou() ? 'bg-surface-50/80 dark:bg-surface-950/80 backdrop-blur-md' : 'bg-surface-50 dark:bg-surface-950'">
                <nav class="rounded-full flex items-center justify-between gap-4 pl-4 pr-2 py-1.5 bg-surface-0 dark:bg-surface-900 shadow-[0px_10px_6px_0px_rgba(44,54,87,0.02),0px_4px_4px_0px_rgba(44,54,87,0.03),0px_1px_2px_0px_rgba(44,54,87,0.04)]">
                    <a href="/" (click)="nav.topo($event)" aria-label="Início"><site-logo [comTexto]="true" [tamanho]="32" /></a>
                    <div class="flex items-center gap-1">
                        @for (item of itens; track item.destino) {
                            <a [href]="nav.href(item.destino)" (click)="nav.ir(item.destino, $event)" [class]="linkClass">{{ item.rotulo }}</a>
                        }
                    </div>
                    <div class="flex items-center gap-2">
                        <button
                            type="button"
                            (click)="tema.alternar()"
                            [pTooltip]="tema.escuro() ? 'Tema claro' : 'Tema escuro'"
                            tooltipPosition="bottom"
                            [attr.aria-label]="tema.escuro() ? 'Ativar tema claro' : 'Ativar tema escuro'"
                            class="w-10 h-10 rounded-full flex items-center justify-center hover:bg-surface-100 dark:hover:bg-surface-800 transition-colors cursor-pointer"
                        >
                            <i [class]="tema.escuro() ? 'pi pi-sun' : 'pi pi-moon'"></i>
                        </button>
                        <a [href]="repo.url" target="_blank" rel="noopener" class="landing-button-primary inline-flex items-center gap-2">
                            <i class="pi pi-github"></i> Repositório
                        </a>
                    </div>
                </nav>
            </div>
        </div>

        <!-- Mobile / tablet -->
        <div
            #mobile
            class="lg:hidden fixed top-4 left-1/2 -translate-x-1/2 z-50 w-[calc(100%-1.5rem)] transition-[max-width] duration-300"
            [class.max-w-[24rem]]="menuAberto()"
            [class.max-w-[22rem]]="!menuAberto()"
        >
            <div class="rounded-[2.25rem] border p-1.5" [class]="rolou() || menuAberto() ? 'bg-surface-50/90 dark:bg-surface-950/90 backdrop-blur-md' : 'bg-surface-50 dark:bg-surface-950'">
                <nav class="w-full rounded-[1.9rem] px-4 py-3 bg-surface-0 dark:bg-surface-900 shadow-[0px_4px_4px_0px_rgba(44,54,87,0.03),0px_1px_2px_0px_rgba(44,54,87,0.04)]">
                    <div class="flex items-center justify-between gap-3">
                        <a href="/" (click)="nav.topo($event); menuAberto.set(false)" aria-label="Início"><site-logo [comTexto]="true" [tamanho]="30" /></a>
                        <div class="flex items-center gap-1">
                            <button type="button" (click)="tema.alternar()" [attr.aria-label]="tema.escuro() ? 'Ativar tema claro' : 'Ativar tema escuro'" class="w-9 h-9 rounded-full flex items-center justify-center hover:bg-surface-100 dark:hover:bg-surface-800">
                                <i [class]="tema.escuro() ? 'pi pi-sun' : 'pi pi-moon'"></i>
                            </button>
                            <button type="button" (click)="alternarMenu($event)" [attr.aria-expanded]="menuAberto()" aria-label="Abrir menu" class="w-9 h-9 flex items-center justify-center rounded-full hover:bg-surface-100 dark:hover:bg-surface-800">
                                <i [class]="menuAberto() ? 'pi pi-times' : 'pi pi-bars'"></i>
                            </button>
                        </div>
                    </div>
                    <div class="transition-[max-height,opacity] duration-300 overflow-hidden" [class]="menuAberto() ? 'max-h-[30rem] opacity-100' : 'max-h-0 opacity-0 pointer-events-none'">
                        <div class="pt-4 pb-1 flex flex-col gap-1">
                            @for (item of itens; track item.destino) {
                                <a [href]="nav.href(item.destino)" (click)="nav.ir(item.destino, $event); menuAberto.set(false)" class="px-3 py-2.5 rounded-xl text-surface-600 dark:text-surface-300 hover:bg-surface-100 dark:hover:bg-surface-800 font-medium">
                                    {{ item.rotulo }}
                                </a>
                            }
                            <a [href]="repo.url" target="_blank" rel="noopener" class="landing-button-primary text-center mt-2 inline-flex items-center justify-center gap-2"><i class="pi pi-github"></i> Repositório no GitHub</a>
                        </div>
                    </div>
                </nav>
            </div>
        </div>
    `
})
export class Navbar {
    readonly nav = inject(NavService);
    readonly tema = inject(ThemeService);

    readonly itens = ITENS_NAV;
    readonly repo = REPOSITORIO;
    readonly menuAberto = signal(false);
    readonly rolou = signal(false);

    private readonly mobile = viewChild<ElementRef<HTMLElement>>('mobile');

    readonly linkClass = 'px-3 py-2 rounded-full text-surface-500 hover:text-surface-950 dark:hover:text-surface-0 hover:bg-surface-100/70 dark:hover:bg-surface-800/70 transition-all font-medium cursor-pointer';

    alternarMenu(evento: Event): void {
        evento.stopPropagation();
        this.menuAberto.update((v) => !v);
    }

    fecharAoClicarFora(evento: Event): void {
        const el = this.mobile()?.nativeElement;
        if (el && !el.contains(evento.target as Node)) {
            this.menuAberto.set(false);
        }
    }

    aoRolar(): void {
        this.rolou.set(window.scrollY > 24);
    }
}
