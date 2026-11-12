import { Routes } from '@angular/router';
import { SiteLayout } from '@/app/layout/site-layout';

export const appRoutes: Routes = [
    {
        path: '',
        component: SiteLayout,
        children: [
            {
                path: '',
                title: 'ChirpStack v3 e v4 em Kubernetes na OCI Always Free',
                loadComponent: () => import('@/app/pages/home/home').then((c) => c.Home)
            },
            {
                path: 'v3',
                title: 'ChirpStack v3 · Network Server + Application Server em Kubernetes',
                data: { versao: 'v3' },
                loadComponent: () => import('@/app/pages/versao/versao').then((c) => c.VersaoPage)
            },
            {
                path: 'v4',
                title: 'ChirpStack v4 · servidor unificado com MQTT TLS em Kubernetes',
                data: { versao: 'v4' },
                loadComponent: () => import('@/app/pages/versao/versao').then((c) => c.VersaoPage)
            },
            {
                path: 'infraestrutura',
                title: 'Infraestrutura · Kubernetes ARM64 na OCI Always Free',
                loadComponent: () => import('@/app/pages/infraestrutura/infraestrutura').then((c) => c.Infraestrutura)
            }
        ]
    },
    { path: '**', redirectTo: '' }
];
