import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { PerfilAcesso } from '@/app/core/api/models';
import { AuthService } from './auth.service';

/** Exige usuário autenticado. */
export const authGuard: CanActivateFn = (_route, state) => {
    const auth = inject(AuthService);
    if (auth.autenticado()) {
        return true;
    }
    return inject(Router).createUrlTree(['/auth/login'], { queryParams: { returnUrl: state.url } });
};

/** Exige um dos perfis em {@code data.perfis} da rota. */
export const perfilGuard: CanActivateFn = (route) => {
    const auth = inject(AuthService);
    const perfis = (route.data?.['perfis'] ?? []) as PerfilAcesso[];
    if (perfis.length === 0 || auth.hasRole(...perfis)) {
        return true;
    }
    return inject(Router).createUrlTree(['/auth/access-denied']);
};

/** Impede abrir o login já autenticado. */
export const anonimoGuard: CanActivateFn = () => {
    const auth = inject(AuthService);
    return auth.autenticado() ? inject(Router).createUrlTree(['/']) : true;
};
