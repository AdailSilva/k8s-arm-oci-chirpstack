import { Component, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '@/app/core/auth/auth.service';
import { AppMenuitem } from './app.menuitem';

/**
 * Menu lateral. Itens administrativos só aparecem para o perfil ADMIN
 * (o backend também bloqueia, isto é apenas para não mostrar o que não pode ser usado).
 */
@Component({
    selector: '[app-menu]',
    standalone: true,
    imports: [CommonModule, AppMenuitem, RouterModule],
    template: `<ul class="layout-menu">
        @for (item of model(); track $index) {
            @if (item.visible !== false) {
                @if (!item.separator) {
                    <li app-menuitem [item]="item" [root]="true"></li>
                } @else {
                    <li class="menu-separator"></li>
                }
            }
        }
    </ul> `
})
export class AppMenu {
    private auth = inject(AuthService);

    model = computed<any[]>(() => {
        const admin = this.auth.isAdmin();
        return [
            {
                label: 'Visão geral',
                icon: 'pi pi-home',
                path: '/painel',
                items: [{ label: 'Painel', icon: 'pi pi-fw pi-chart-bar', routerLink: ['/painel'] }]
            },
            { separator: true },
            {
                label: 'Rede LoRaWAN',
                icon: 'pi pi-sitemap',
                path: '/rede',
                items: [
                    { label: 'Aplicações', icon: 'pi pi-fw pi-th-large', routerLink: ['/aplicacoes'] },
                    { label: 'Grupos multicast', icon: 'pi pi-fw pi-sitemap', routerLink: ['/multicast'] },
                    { label: 'Gateways', icon: 'pi pi-fw pi-wifi', routerLink: ['/gateways'] },
                    { label: 'Relay gateways', icon: 'pi pi-fw pi-share-alt', routerLink: ['/relay-gateways'] },
                    { label: 'Perfis de dispositivo', icon: 'pi pi-fw pi-id-card', routerLink: ['/perfis-dispositivo'] },
                    { label: 'Templates de perfil', icon: 'pi pi-fw pi-copy', routerLink: ['/templates-perfil'] },
                    { label: 'Catálogo de dispositivos', icon: 'pi pi-fw pi-box', routerLink: ['/catalogo-dispositivos'] }
                ]
            },
            { separator: true },
            {
                label: 'ChirpStack',
                icon: 'pi pi-server',
                path: '/chirpstack',
                visible: admin,
                items: [
                    { label: 'Tenants', icon: 'pi pi-fw pi-building', routerLink: ['/tenants'] },
                    { label: 'Usuários do ChirpStack', icon: 'pi pi-fw pi-users', routerLink: ['/usuarios-chirpstack'] }
                ]
            },
            { separator: true, visible: admin },
            {
                label: 'Sistema',
                icon: 'pi pi-cog',
                path: '/sistema',
                items: [
                    { label: 'Usuários do painel', icon: 'pi pi-fw pi-user-edit', routerLink: ['/sistema/usuarios'], visible: admin },
                    { label: 'Visitantes', icon: 'pi pi-fw pi-users', routerLink: ['/sistema/visitantes'], visible: admin },
                    { label: 'Controle de sessão', icon: 'pi pi-fw pi-stopwatch', routerLink: ['/sistema/controle-sessao'], visible: admin },
                    { label: 'Backup & Restauração', icon: 'pi pi-fw pi-database', routerLink: ['/sistema/backup'], visible: admin },
                    { label: 'Auditoria', icon: 'pi pi-fw pi-history', routerLink: ['/sistema/auditoria'], visible: admin },
                    { label: 'Meu perfil', icon: 'pi pi-fw pi-user', routerLink: ['/meu-perfil'] }
                ]
            }
        ];
    });
}
