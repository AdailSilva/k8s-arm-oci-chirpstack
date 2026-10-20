import { Routes } from '@angular/router';
import { perfilGuard } from '@/app/core/auth/auth.guards';

const ESCRITA = { perfis: ['ADMIN', 'OPERADOR'] };

export default [
    { path: '', loadComponent: () => import('./application-list').then((c) => c.ApplicationList), data: { title: 'Aplicações', breadcrumb: 'Aplicações' } },
    { path: ':id', loadComponent: () => import('./application-detail').then((c) => c.ApplicationDetail), data: { title: 'Aplicação', breadcrumb: ['Aplicações', 'Aplicação'] } },
    {
        path: ':applicationId/dispositivos/novo',
        canActivate: [perfilGuard],
        loadComponent: () => import('@/app/pages/dispositivos/device-form').then((c) => c.DeviceForm),
        data: { ...ESCRITA, title: 'Novo dispositivo', breadcrumb: ['Aplicações', 'Dispositivos', 'Novo'] }
    },
    {
        path: ':applicationId/dispositivos/:devEui',
        loadComponent: () => import('@/app/pages/dispositivos/device-detail').then((c) => c.DeviceDetail),
        data: { title: 'Dispositivo', breadcrumb: ['Aplicações', 'Dispositivos', 'Dispositivo'] }
    },
    {
        path: ':applicationId/dispositivos/:devEui/editar',
        canActivate: [perfilGuard],
        loadComponent: () => import('@/app/pages/dispositivos/device-form').then((c) => c.DeviceForm),
        data: { ...ESCRITA, title: 'Editar dispositivo', breadcrumb: ['Aplicações', 'Dispositivos', 'Editar'] }
    },
    {
        path: ':applicationId/multicast/novo',
        canActivate: [perfilGuard],
        loadComponent: () => import('@/app/pages/multicast/multicast-form').then((c) => c.MulticastForm),
        data: { ...ESCRITA, title: 'Novo grupo multicast', breadcrumb: ['Aplicações', 'Multicast', 'Novo'] }
    },
    {
        path: ':applicationId/multicast/:id',
        loadComponent: () => import('@/app/pages/multicast/multicast-detail').then((c) => c.MulticastDetail),
        data: { title: 'Grupo multicast', breadcrumb: ['Aplicações', 'Multicast', 'Grupo'] }
    },
    {
        path: ':applicationId/multicast/:id/editar',
        canActivate: [perfilGuard],
        loadComponent: () => import('@/app/pages/multicast/multicast-form').then((c) => c.MulticastForm),
        data: { ...ESCRITA, title: 'Editar grupo multicast', breadcrumb: ['Aplicações', 'Multicast', 'Editar'] }
    }
] satisfies Routes;
