import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, inject, LOCALE_ID, provideAppInitializer, provideZonelessChangeDetection } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localePt from '@angular/common/locales/pt';
import { provideRouter, withComponentInputBinding, withInMemoryScrolling } from '@angular/router';
import Aura from '@primeuix/themes/aura';
import { definePreset } from '@primeuix/themes';
import { providePrimeNG } from 'primeng/config';
import { ConfirmationService, MessageService } from 'primeng/api';
import { appRoutes } from './app.routes';
import { authInterceptor } from '@/app/core/auth/auth.interceptor';
import { AuthService } from '@/app/core/auth/auth.service';
import { PRIMENG_PT_BR } from '@/app/core/util/primeng-pt-br';

registerLocaleData(localePt);

const MyPreset = definePreset(Aura, {
    semantic: {
        select: {
            borderRadius: '{border.radius.lg}',
            height: '2rem'
        },
        primary: {
            50: '{blue.50}',
            100: '{blue.100}',
            200: '{blue.200}',
            300: '{blue.300}',
            400: '{blue.400}',
            500: '{blue.500}',
            600: '{blue.600}',
            700: '{blue.700}',
            800: '{blue.800}',
            900: '{blue.900}',
            950: '{blue.950}'
        }
    }
});

export const appConfig: ApplicationConfig = {
    providers: [
        provideRouter(appRoutes, withInMemoryScrolling({ anchorScrolling: 'enabled', scrollPositionRestoration: 'enabled' }), withComponentInputBinding()),
        provideHttpClient(withFetch(), withInterceptors([authInterceptor])),
        provideZonelessChangeDetection(),
        providePrimeNG({ theme: { preset: MyPreset, options: { darkModeSelector: '.app-dark' } }, translation: PRIMENG_PT_BR }),
        { provide: LOCALE_ID, useValue: 'pt-BR' },
        MessageService,
        ConfirmationService,
        // Recupera a sessão (cookie de refresh) antes da primeira navegação.
        provideAppInitializer(() => inject(AuthService).restaurar())
    ]
};
