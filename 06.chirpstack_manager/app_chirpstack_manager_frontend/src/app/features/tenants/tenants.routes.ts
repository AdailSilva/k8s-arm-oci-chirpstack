import { Routes } from '@angular/router';

export default [
    { path: '', loadComponent: () => import('./tenant-list').then((c) => c.TenantList), data: { title: 'Tenants', breadcrumb: 'Tenants' } },
    { path: ':id', loadComponent: () => import('./tenant-detail').then((c) => c.TenantDetail), data: { title: 'Tenant', breadcrumb: ['Tenants', 'Detalhe'] } }
] satisfies Routes;
