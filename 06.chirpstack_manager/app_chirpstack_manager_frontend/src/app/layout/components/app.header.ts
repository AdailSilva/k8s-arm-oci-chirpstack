import { Component, computed, inject, OnInit } from '@angular/core';
import { Router, NavigationEnd, ActivatedRoute, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { filter, map } from 'rxjs/operators';
import { toSignal } from '@angular/core/rxjs-interop';
import { StyleClassModule } from 'primeng/styleclass';
import { ButtonModule } from 'primeng/button';
import { SelectModule } from 'primeng/select';
import { TooltipModule } from 'primeng/tooltip';
import { LayoutService } from '@/app/layout/service/layout.service';
import { AuthService } from '@/app/core/auth/auth.service';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { environment } from '@/environments/environment';
import { AppProfile } from './app.profile';
import { SessaoChip } from './app.sessao';

/**
 * Barra superior: título da página, seletor de tenant, tema e menu do usuário.
 */
@Component({
    selector: '[app-header]',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, StyleClassModule, ButtonModule, SelectModule, TooltipModule, AppProfile, SessaoChip],
    template: `
        <div class="topbar-left">
            @if (showMenuButton()) {
                <button type="button" (click)="layoutService.toggleMenu()" class="menu-button">
                    <i class="pi pi-bars"></i>
                </button>
                <span class="topbar-separator"></span>
            }
            <div class="page-title">
                {{ pageTitle() }}
            </div>
            @if (perfil.rotulo) {
                <span class="ml-3 px-2.5 py-1 rounded-md text-xs font-semibold uppercase tracking-wide" [class]="perfil.classe" [pTooltip]="'Perfil ' + perfil.nome + ' (frontend :' + perfil.porta + ')'" tooltipPosition="bottom">{{ perfil.rotulo }}</span>
            }
        </div>

        <div class="topbar-right">
            <div class="flex items-center gap-2">
                <span class="hidden lg:inline text-surface-500 text-sm"><i class="pi pi-building mr-1"></i>Tenant</span>
                <p-select
                    [options]="ctx.tenants()"
                    optionLabel="name"
                    optionValue="id"
                    [ngModel]="ctx.tenantId()"
                    (ngModelChange)="ctx.selecionar($event)"
                    [filter]="ctx.tenants().length > 6"
                    filterBy="name"
                    placeholder="Selecione o tenant"
                    [loading]="ctx.carregando()"
                    emptyMessage="Nenhum tenant"
                    styleClass="w-48 md:w-64"
                    appendTo="body"
                />
            </div>

            <div class="topbar-actions">
                <button type="button" (click)="layoutService.toggleMenu()" class="menu-button menu-button-mobile">
                    <i class="pi pi-bars"></i>
                </button>

                <app-sessao-chip />

                <p-button [icon]="layoutService.isDarkTheme() ? 'pi pi-sun' : 'pi pi-moon'" severity="secondary" [outlined]="true" (onClick)="alternarTema()" pTooltip="Tema claro/escuro" tooltipPosition="bottom" />

                <button type="button" (click)="layoutService.toggleConfigSidebar()" class="app-config-button" pTooltip="Aparência" tooltipPosition="bottom">
                    <i class="pi pi-palette"></i>
                </button>

                <div class="relative">
                    <a pStyleClass="@next" enterFromClass="hidden" enterActiveClass="p-anchored-overlay-enter-active" leaveActiveClass="p-anchored-overlay-leave-active" leaveToClass="hidden" [hideOnOutsideClick]="true" class="flex items-center gap-2 cursor-pointer">
                        <span class="w-9 h-9 rounded-lg bg-primary text-primary-contrast flex items-center justify-center font-semibold">{{ iniciais() }}</span>
                        <span class="hidden xl:flex flex-col leading-tight">
                            <span class="font-medium text-sm">{{ auth.usuario()?.nome }}</span>
                            <span class="text-xs text-surface-500">{{ perfilLabel() }}</span>
                        </span>
                    </a>
                    <div class="absolute hidden top-full right-0 mt-2 z-20">
                        <div app-profile class="w-64"></div>
                    </div>
                </div>
            </div>
        </div>
    `
})
export class AppHeader implements OnInit {
    /** Selo do perfil: aparece em desenvolvimento e homologação para não confundir com a produção. */
    readonly perfil = (
        {
            development: { nome: 'development', rotulo: 'Desenvolvimento', porta: 4201, classe: 'bg-sky-100 text-sky-700 dark:bg-sky-900/40 dark:text-sky-300' },
            staging: { nome: 'staging', rotulo: 'Homologação', porta: 4202, classe: 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300' },
            production: { nome: 'production', rotulo: '', porta: 4203, classe: '' }
        } as const
    )[environment.perfil];

    layoutService = inject(LayoutService);
    auth = inject(AuthService);
    ctx = inject(TenantContextService);
    private router = inject(Router);
    private activatedRoute = inject(ActivatedRoute);

    showMenuButton = computed(() => {
        const menuMode = this.layoutService.layoutConfig().menuMode;
        return menuMode === 'overlay' || menuMode === 'static';
    });

    iniciais = computed(() => {
        const nome = this.auth.usuario()?.nome ?? '?';
        const partes = nome.trim().split(/\s+/);
        return ((partes[0]?.[0] ?? '') + (partes.length > 1 ? partes[partes.length - 1][0] : '')).toUpperCase();
    });

    perfilLabel = computed(() => ({ ADMIN: 'Administrador', OPERADOR: 'Operador', VISUALIZADOR: 'Visualizador' })[this.auth.perfil() ?? 'VISUALIZADOR']);

    private pageTitle$ = this.router.events.pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        map(() => {
            let route = this.activatedRoute;
            while (route.firstChild) {
                route = route.firstChild;
            }
            return route.snapshot.data['title'] || 'ChirpStack Manager';
        })
    );

    pageTitle = toSignal(this.pageTitle$, { initialValue: 'ChirpStack Manager' });

    ngOnInit(): void {
        if (this.ctx.tenants().length === 0) {
            this.ctx.carregar();
        }
    }

    alternarTema(): void {
        this.layoutService.layoutConfig.update((c) => ({ ...c, darkTheme: !c.darkTheme }));
    }
}
