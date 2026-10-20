import { Routes } from '@angular/router';
import { perfilGuard } from '@/app/core/auth/auth.guards';

export const perfisRoutes: Routes = [
    { path: '', loadComponent: () => import('./device-profile-list').then((c) => c.DeviceProfileList), data: { modo: 'perfil', title: 'Perfis de dispositivo', breadcrumb: 'Perfis de dispositivo' } },
    {
        path: 'novo',
        canActivate: [perfilGuard],
        loadComponent: () => import('./device-profile-form').then((c) => c.DeviceProfileForm),
        data: { modo: 'perfil', perfis: ['ADMIN', 'OPERADOR'], title: 'Novo perfil de dispositivo', breadcrumb: ['Perfis de dispositivo', 'Novo'] }
    },
    { path: ':id', loadComponent: () => import('./device-profile-form').then((c) => c.DeviceProfileForm), data: { modo: 'perfil', title: 'Perfil de dispositivo', breadcrumb: ['Perfis de dispositivo', 'Perfil'] } }
];

export const templatesRoutes: Routes = [
    { path: '', loadComponent: () => import('./device-profile-list').then((c) => c.DeviceProfileList), data: { modo: 'template', title: 'Templates de perfil', breadcrumb: 'Templates de perfil' } },
    {
        path: 'novo',
        canActivate: [perfilGuard],
        loadComponent: () => import('./device-profile-form').then((c) => c.DeviceProfileForm),
        data: { modo: 'template', perfis: ['ADMIN'], title: 'Novo template', breadcrumb: ['Templates de perfil', 'Novo'] }
    },
    { path: ':id', loadComponent: () => import('./device-profile-form').then((c) => c.DeviceProfileForm), data: { modo: 'template', title: 'Template de perfil', breadcrumb: ['Templates de perfil', 'Template'] } }
];
