import { Routes } from '@angular/router';
import { AppLayout } from '@/app/layout/components/app.layout';
import { AuthLayout } from '@/app/layout/components/app.authlayout';
import { anonimoGuard, authGuard, perfilGuard } from '@/app/core/auth/auth.guards';
import { perfisRoutes, templatesRoutes } from '@/app/pages/perfis-dispositivo/device-profiles.routes';

const ADMIN = { perfis: ['ADMIN'] };

export const appRoutes: Routes = [
    {
        path: '',
        component: AppLayout,
        canActivate: [authGuard],
        children: [
            { path: '', redirectTo: 'painel', pathMatch: 'full' },
            {
                path: 'painel',
                loadComponent: () => import('@/app/pages/dashboard/dashboard').then((c) => c.Dashboard),
                data: { title: 'Painel', breadcrumb: ['Visão geral', 'Painel'] }
            },
            { path: 'aplicacoes', loadChildren: () => import('@/app/pages/aplicacoes/applications.routes') },
            { path: 'gateways', loadChildren: () => import('@/app/pages/gateways/gateways.routes') },
            {
                path: 'relay-gateways',
                loadComponent: () => import('@/app/pages/relay-gateways/relay-gateway-list').then((c) => c.RelayGatewayList),
                data: { title: 'Relay gateways', breadcrumb: 'Relay gateways' }
            },
            {
                path: 'multicast',
                loadComponent: () => import('@/app/pages/multicast/multicast-list').then((c) => c.MulticastList),
                data: { title: 'Grupos multicast', breadcrumb: 'Grupos multicast' }
            },
            { path: 'perfis-dispositivo', children: perfisRoutes },
            { path: 'templates-perfil', children: templatesRoutes },
            {
                path: 'catalogo-dispositivos',
                loadComponent: () => import('@/app/pages/catalogo/catalogo-dispositivos').then((c) => c.CatalogoDispositivos),
                data: { title: 'Catálogo de dispositivos', breadcrumb: 'Catálogo de dispositivos' }
            },
            {
                path: 'tenants',
                canActivate: [perfilGuard],
                data: ADMIN,
                loadChildren: () => import('@/app/pages/tenants/tenants.routes')
            },
            {
                path: 'usuarios-chirpstack',
                canActivate: [perfilGuard],
                loadComponent: () => import('@/app/pages/usuarios-chirpstack/cs-user-list').then((c) => c.CsUserList),
                data: { ...ADMIN, title: 'Usuários do ChirpStack', breadcrumb: ['ChirpStack', 'Usuários'] }
            },
            {
                path: 'sistema/usuarios',
                canActivate: [perfilGuard],
                loadComponent: () => import('@/app/pages/usuarios/usuarios').then((c) => c.Usuarios),
                data: { ...ADMIN, title: 'Usuários do painel', breadcrumb: ['Sistema', 'Usuários'] }
            },
            {
                path: 'sistema/visitantes',
                canActivate: [perfilGuard],
                loadComponent: () => import('@/app/pages/visitantes/visitantes').then((c) => c.Visitantes),
                data: { ...ADMIN, title: 'Visitantes', breadcrumb: ['Sistema', 'Visitantes'] }
            },
            {
                path: 'sistema/controle-sessao',
                canActivate: [perfilGuard],
                loadComponent: () => import('@/app/pages/controle-sessao/controle-sessao').then((c) => c.ControleSessao),
                data: { ...ADMIN, title: 'Controle de sessão', breadcrumb: ['Sistema', 'Controle de sessão'] }
            },
            {
                path: 'sistema/backup',
                canActivate: [perfilGuard],
                loadComponent: () => import('@/app/pages/backup/backup').then((c) => c.Backup),
                data: { ...ADMIN, title: 'Backup & Restauração', breadcrumb: ['Sistema', 'Backup & Restauração'] }
            },
            {
                path: 'sistema/auditoria',
                canActivate: [perfilGuard],
                loadComponent: () => import('@/app/pages/auditoria/auditoria').then((c) => c.Auditoria),
                data: { ...ADMIN, title: 'Auditoria', breadcrumb: ['Sistema', 'Auditoria'] }
            },
            {
                path: 'meu-perfil',
                loadComponent: () => import('@/app/pages/minha-conta/meu-perfil').then((c) => c.MeuPerfil),
                data: { title: 'Meu perfil', breadcrumb: ['Sistema', 'Meu perfil'] }
            }
        ]
    },
    {
        path: 'auth',
        component: AuthLayout,
        children: [
            { path: '', redirectTo: 'login', pathMatch: 'full' },
            { path: 'login', canActivate: [anonimoGuard], loadComponent: () => import('@/app/pages/auth/login').then((c) => c.Login) },
            { path: 'access-denied', loadComponent: () => import('@/app/pages/auth/acesso-negado').then((c) => c.AccessDenied) },
            { path: 'notfound', loadComponent: () => import('@/app/pages/auth/nao-encontrado').then((c) => c.Notfound) }
        ]
    },
    { path: '**', redirectTo: 'auth/notfound' }
];
