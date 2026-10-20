import { Routes } from '@angular/router';
import { perfilGuard } from '@/app/core/auth/auth.guards';

export default [
    { path: '', loadComponent: () => import('./gateway-list').then((c) => c.GatewayList), data: { title: 'Gateways', breadcrumb: 'Gateways' } },
    {
        path: 'novo',
        canActivate: [perfilGuard],
        loadComponent: () => import('./gateway-form').then((c) => c.GatewayForm),
        data: { perfis: ['ADMIN', 'OPERADOR'], title: 'Novo gateway', breadcrumb: ['Gateways', 'Novo'] }
    },
    { path: ':id', loadComponent: () => import('./gateway-detail').then((c) => c.GatewayDetail), data: { title: 'Gateway', breadcrumb: ['Gateways', 'Gateway'] } },
    {
        path: ':id/editar',
        canActivate: [perfilGuard],
        loadComponent: () => import('./gateway-form').then((c) => c.GatewayForm),
        data: { perfis: ['ADMIN', 'OPERADOR'], title: 'Editar gateway', breadcrumb: ['Gateways', 'Editar'] }
    }
] satisfies Routes;
