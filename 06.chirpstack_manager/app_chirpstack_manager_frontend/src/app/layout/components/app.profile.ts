import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { RippleModule } from 'primeng/ripple';
import { AuthService } from '@/app/core/auth/auth.service';

/** Menu do usuário (topo direito). */
@Component({
    selector: '[app-profile]',
    standalone: true,
    imports: [CommonModule, RouterModule, RippleModule],
    template: `
        <div class="px-3 py-2 border-b border-surface-200 dark:border-surface-800 mb-1">
            <div class="font-medium truncate">{{ auth.usuario()?.nome }}</div>
            <div class="text-sm text-surface-500 truncate">{{ auth.usuario()?.email }}</div>
        </div>
        <a pRipple routerLink="/meu-perfil" [class]="buttonClass">
            <i class="pi pi-user"></i>
            <span>Meu perfil</span>
        </a>
        @if (auth.isAdmin()) {
            <a pRipple routerLink="/sistema/usuarios" [class]="buttonClass">
                <i class="pi pi-users"></i>
                <span>Usuários do painel</span>
            </a>
        }
        <button pRipple [class]="buttonClass" (click)="auth.logout()">
            <i class="pi pi-sign-out"></i>
            <span>Sair</span>
        </button>
    `,
    host: {
        class: 'block z-30 p-2 space-y-1 rounded-2xl bg-surface-0 dark:bg-surface-950 shadow-[0px_129.205px_36.493px_0px_rgba(44,54,87,0.00),_0px_82.849px_33.534px_0px_rgba(44,54,87,0.01),_0px_46.356px_27.616px_0px_rgba(44,54,87,0.03),_0px_20.712px_20.712px_0px_rgba(44,54,87,0.05),_0px_4.932px_11.836px_0px_rgba(44,54,87,0.06)] dark:shadow-stroke'
    }
})
export class AppProfile {
    auth = inject(AuthService);

    readonly buttonClass = 'w-full px-3 py-2 rounded-lg flex items-center gap-2 font-medium text-surface-500 hover:text-surface-950 dark:hover:text-surface-0 hover:bg-surface-100 dark:hover:bg-surface-800 transition-colors duration-150 cursor-pointer no-underline';
}
