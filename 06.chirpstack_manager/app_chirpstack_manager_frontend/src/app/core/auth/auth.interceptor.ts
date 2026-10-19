import { HttpErrorResponse, HttpInterceptorFn, HttpRequest } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { AuthService, motivoDoErro, sessaoEncerradaPeloServidor } from './auth.service';

/**
 * Rotas sem access token. O logout vai sem ele de propósito: o token pode já ter vencido e o
 * servidor identifica a sessão pelo cookie de renovação.
 */
const SEM_TOKEN = ['/auth/login', '/auth/refresh', '/auth/logout'];

function comToken(req: HttpRequest<unknown>, token: string | null): HttpRequest<unknown> {
    return token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req;
}

/**
 * Anexa o access token e, se a API responder 401, renova uma vez e repete a requisição.
 * Se o 401 disser que a sessão foi ENCERRADA (pelo administrador, inatividade, restauração...),
 * não tenta renovar: leva direto ao login com o motivo.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
    const auth = inject(AuthService);
    if (!req.url.startsWith('/api/') || SEM_TOKEN.some((p) => req.url.endsWith(p))) {
        return next(req);
    }
    return next(comToken(req, auth.accessToken())).pipe(
        catchError((err: unknown) => {
            if (sessaoEncerradaPeloServidor(err)) {
                auth.sessaoEncerrada(motivoDoErro(err));
                return throwError(() => err);
            }
            if (err instanceof HttpErrorResponse && err.status === 401) {
                return auth.renovar().pipe(
                    switchMap((token) => next(comToken(req, token))),
                    catchError((e) => {
                        if (sessaoEncerradaPeloServidor(e)) {
                            auth.sessaoEncerrada(motivoDoErro(e));
                        } else {
                            auth.sessaoExpirada();
                        }
                        return throwError(() => e);
                    })
                );
            }
            return throwError(() => err);
        })
    );
};
