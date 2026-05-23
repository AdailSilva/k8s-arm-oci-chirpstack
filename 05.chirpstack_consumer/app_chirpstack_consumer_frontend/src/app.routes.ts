import { Routes } from '@angular/router';
import { AppLayout } from '@/app/layout/components/app.layout';
import { LandingLayout } from '@/app/layout/components/app.landinglayout';
import { AuthLayout } from '@/app/layout/components/app.authlayout';

export const appRoutes: Routes = [
    {
        path: '',
        component: AppLayout,
        children: [
            {
                path: '',
                redirectTo: '/dashboard/e-commerce',
                pathMatch: 'full'
            },
            {
                path: 'dashboard/e-commerce',
                loadComponent: () => import('@/app/pages/dashboards/ecommerce/ecommercedashboard').then((c) => c.EcommerceDashboard),
                data: { breadcrumb: ['E-Commerce', 'Overview'] }
            },
            {
                path: 'dashboard/banking',
                loadComponent: () => import('@/app/pages/dashboards/banking/bankingdashboard').then((c) => c.BankingDashboard),
                data: { breadcrumb: ['Banking', 'Overview'] }
            },
            {
                path: 'dashboard/marketing',
                loadComponent: () => import('@/app/pages/dashboards/marketing/marketingdashboard').then((c) => c.MarketingDashboard),
                data: { breadcrumb: ['Marketing', 'Overview'] }
            },
            {
                path: 'uikit',
                data: { breadcrumb: 'UI Kit' },
                loadChildren: () => import('@/app/pages/uikit/uikit.routes')
            },
            {
                path: 'documentation',
                data: { breadcrumb: 'Documentation' },
                loadComponent: () => import('@/app/pages/documentation/documentation').then((c) => c.Documentation)
            },
            {
                path: 'pages',
                loadChildren: () => import('@/app/pages/pages.routes'),
                data: { breadcrumb: 'Pages' }
            },
            {
                path: 'apps',
                loadChildren: () => import('@/app/apps/apps.routes'),
                data: { breadcrumb: 'Apps' }
            },
            {
                path: 'blocks',
                data: { breadcrumb: 'Free Blocks' },
                loadChildren: () => import('@/app/pages/blocks/blocks.routes')
            },
            {
                path: 'ecommerce',
                loadChildren: () => import('@/app/pages/ecommerce/ecommerce.routes'),
                data: { breadcrumb: 'E-Commerce' }
            },
            {
                path: 'profile',
                loadChildren: () => import('@/app/pages/usermanagement/usermanagement.routes')
            }
        ]
    },
    {
        path: 'landing',
        component: LandingLayout,
        children: [
            {
                path: '',
                loadComponent: () => import('@/app/pages/landing/home/home').then((c) => c.Home)
            },
            {
                path: 'features',
                loadComponent: () => import('@/app/pages/landing/features/features').then((c) => c.Features)
            },
            {
                path: 'pricing',
                loadComponent: () => import('@/app/pages/landing/pricing/pricing').then((c) => c.Pricing)
            },
            {
                path: 'contact',
                loadComponent: () => import('@/app/pages/landing/contact/contact').then((c) => c.Contact)
            },
            {
                path: 'login',
                redirectTo: 'auth/login',
                pathMatch: 'full'
            },
            {
                path: 'register',
                redirectTo: 'auth/register',
                pathMatch: 'full'
            }
        ]
    },
    {
        path: 'auth',
        component: AuthLayout,
        children: [
            {
                path: 'login',
                loadComponent: () => import('@/app/pages/auth/login').then((c) => c.Login)
            },
            {
                path: 'register',
                loadComponent: () => import('@/app/pages/auth/register').then((c) => c.Register)
            },
            {
                path: 'verification',
                loadComponent: () => import('@/app/pages/auth/verification').then((c) => c.Verification)
            },
            {
                path: 'forgot-password',
                loadComponent: () => import('@/app/pages/auth/forgotpassword').then((c) => c.ForgotPassword)
            },
            {
                path: 'new-password',
                loadComponent: () => import('@/app/pages/auth/newpassword').then((c) => c.NewPassword)
            },
            {
                path: 'lock-screen',
                loadComponent: () => import('@/app/pages/auth/lockscreen').then((c) => c.LockScreen)
            },
            {
                path: 'access-denied',
                loadComponent: () => import('@/app/pages/auth/accessdenied').then((c) => c.AccessDenied)
            },
            {
                path: 'oops',
                loadComponent: () => import('@/app/pages/auth/oops').then((c) => c.Oops)
            },
            { path: 'notfound', loadComponent: () => import('@/app/pages/notfound/notfound').then((c) => c.Notfound) }
        ]
    },
    { path: '**', redirectTo: 'auth/notfound' }
];
