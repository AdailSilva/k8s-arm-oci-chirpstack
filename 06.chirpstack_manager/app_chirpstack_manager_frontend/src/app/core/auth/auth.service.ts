import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom, Observable, of, throwError } from 'rxjs';
import { catchError, finalize, map, shareReplay, tap } from 'rxjs/operators';
import { environment } from '@/environments/environment';
import { MotivoEncerramento, PerfilAcesso, SessaoInfo, UsuarioSistema } from '@/app/core/api/models';

interface TokenResponse {
    accessToken: string;
    tokenType: string;
    expiresIn: number;
    usuario: UsuarioSistema;
    sessao?: SessaoInfo;
}

/** Cabeçalho com que a API avisa que a sessão acabou DE VEZ (renovar não adianta). */
export const HEADER_SESSAO = 'X-Sessao-Status';
export const HEADER_MOTIVO = 'X-Sessao-Motivo';

/** A resposta 401 diz que a sessão foi encerrada (pelo ADMIN, por inatividade, restauração...)? */
export function sessaoEncerradaPeloServidor(e: unknown): boolean {
    if (!(e instanceof HttpErrorResponse) || e.status !== 401) {
        return false;
    }
    return e.headers?.get(HEADER_SESSAO) === 'ENCERRADA' || (e.error as { erro?: string } | null)?.erro === 'SESSAO_ENCERRADA';
}

export function motivoDoErro(e: unknown): MotivoEncerramento {
    if (e instanceof HttpErrorResponse) {
        const m = e.headers?.get(HEADER_MOTIVO) || (e.error as { motivo?: string } | null)?.motivo;
        if (m) {
            return m as MotivoEncerramento;
        }
    }
    return 'INVALIDA';
}

/** Mensagens da tela de login para cada motivo de encerramento. */
export const MENSAGENS_ENCERRAMENTO: Record<string, string> = {
    INATIVIDADE: 'Sua sessão foi encerrada por inatividade.',
    EXPIRADA: 'Sua sessão atingiu o tempo máximo permitido. Entre novamente.',
    ENCERRADA_ADMIN: 'Sua sessão foi encerrada por um administrador.',
    LIMITE_SESSOES: 'Sua sessão foi encerrada porque você entrou em outro dispositivo.',
    SENHA_ALTERADA: 'Sua senha foi alterada. Entre novamente com a nova senha.',
    USUARIO_DESATIVADO: 'Seu usuário foi desativado. Procure um administrador.',
    USUARIO_BLOQUEADO: 'Seu acesso foi bloqueado por um administrador.',
    USUARIO_EXCLUIDO: 'Seu usuário foi removido do sistema.',
    REUSO_TOKEN: 'Sua sessão foi encerrada por segurança. Entre novamente.',
    RESTAURACAO_BACKUP: 'O banco de dados foi restaurado a partir de um backup. Entre novamente.',
    INVALIDA: 'Sua sessão não é mais válida. Entre novamente.',
    LOGOUT: 'Você saiu do sistema.'
};

const CANAL = 'csm-sessao';

/**
 * Sessão do usuário.
 * - O access token (JWT curto) fica só em memória: nunca em localStorage.
 * - O refresh token é um cookie HttpOnly que o JavaScript não lê; serve para restaurar a sessão
 *   ao recarregar a página e para renovar o access token antes de expirar.
 * - Logoff em uma aba vale para todas (BroadcastChannel).
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
    private http = inject(HttpClient);
    private router = inject(Router);
    private base = `${environment.apiUrl}/auth`;

    private token = signal<string | null>(null);
    private renovacao$: Observable<string> | null = null;
    private timer: ReturnType<typeof setTimeout> | null = null;
    private canal: BroadcastChannel | null = null;

    readonly usuario = signal<UsuarioSistema | null>(null);
    /** Sessão atual (política de logoff); alimenta o monitor de inatividade. */
    readonly sessao = signal<SessaoInfo | null>(null);
    /** Motivo do último encerramento, mostrado na tela de login. */
    readonly ultimoMotivo = signal<MotivoEncerramento | null>(null);
    readonly autenticado = computed(() => this.usuario() !== null);
    readonly perfil = computed<PerfilAcesso | null>(() => this.usuario()?.perfil ?? null);
    readonly isAdmin = computed(() => this.perfil() === 'ADMIN');
    /** ADMIN e OPERADOR podem criar, alterar e excluir recursos de rede. */
    readonly podeEscrever = computed(() => this.perfil() === 'ADMIN' || this.perfil() === 'OPERADOR');

    constructor() {
        if (typeof BroadcastChannel !== 'undefined') {
            this.canal = new BroadcastChannel(CANAL);
            this.canal.onmessage = (ev: MessageEvent<{ tipo: string; motivo?: MotivoEncerramento }>) => {
                if (ev.data?.tipo === 'logout' && this.autenticado()) {
                    this.limpar();
                    this.irParaLogin(ev.data.motivo && ev.data.motivo !== 'LOGOUT' ? ev.data.motivo : null);
                }
            };
        }
    }

    accessToken(): string | null {
        return this.token();
    }

    hasRole(...perfis: PerfilAcesso[]): boolean {
        const p = this.perfil();
        return p !== null && perfis.includes(p);
    }

    login(email: string, senha: string): Observable<UsuarioSistema> {
        return this.http.post<TokenResponse>(`${this.base}/login`, { email, senha }).pipe(
            map((r) => {
                this.ultimoMotivo.set(null);
                return this.aplicar(r);
            })
        );
    }

    /** Chamado na inicialização do app: tenta recuperar a sessão pelo cookie. */
    restaurar(): Promise<void> {
        return firstValueFrom(
            this.renovar().pipe(
                map(() => undefined),
                catchError(() => of(undefined))
            )
        );
    }

    /** Renova o access token. Chamadas simultâneas compartilham a mesma requisição. */
    renovar(): Observable<string> {
        if (!this.renovacao$) {
            this.renovacao$ = this.http.post<TokenResponse>(`${this.base}/refresh`, {}).pipe(
                map((r) => {
                    this.aplicar(r);
                    return r.accessToken;
                }),
                catchError((e) => {
                    if (sessaoEncerradaPeloServidor(e)) {
                        this.ultimoMotivo.set(motivoDoErro(e));
                    }
                    this.limpar();
                    return throwError(() => e);
                }),
                finalize(() => (this.renovacao$ = null)),
                shareReplay(1)
            );
        }
        return this.renovacao$;
    }

    atualizarUsuario(u: UsuarioSistema): void {
        this.usuario.set(u);
    }

    atualizarSessao(s: SessaoInfo): void {
        this.sessao.set(s);
    }

    /**
     * Sai do sistema. {@code INATIVIDADE} = o monitor encerrou por falta de uso (fica registrado no
     * histórico de visitantes). Vai sem o access token: ele pode já ter vencido, e o servidor
     * identifica a sessão pelo cookie de renovação.
     */
    logout(motivo: 'LOGOUT' | 'INATIVIDADE' | 'EXPIRADA' = 'LOGOUT'): void {
        this.http
            .post(`${this.base}/logout`, { motivo: motivo === 'INATIVIDADE' ? 'INATIVIDADE' : 'LOGOUT' })
            .pipe(catchError(() => of(null)))
            .subscribe(() => {
                this.avisarOutrasAbas(motivo);
                this.limpar();
                this.irParaLogin(motivo === 'LOGOUT' ? null : motivo);
            });
    }

    /** A API recusou o token porque a sessão foi encerrada: vai direto ao login, sem tentar renovar. */
    sessaoEncerrada(motivo: MotivoEncerramento): void {
        if (this.autenticado()) {
            this.avisarOutrasAbas(motivo);
        }
        this.limpar();
        this.ultimoMotivo.set(motivo);
        // Várias requisições podem ser recusadas ao mesmo tempo: só a primeira navega.
        if (!this.router.url.startsWith('/auth/')) {
            this.irParaLogin(motivo);
        }
    }

    /** Sessão perdida (refresh recusado): volta ao login guardando a página atual. */
    sessaoExpirada(): void {
        const atual = this.router.url;
        const motivo = this.ultimoMotivo();
        this.limpar();
        if (!atual.startsWith('/auth/')) {
            this.router.navigate(['/auth/login'], { queryParams: motivo ? { motivo } : { returnUrl: atual, expirada: 1 } });
        }
    }

    me(): Observable<UsuarioSistema> {
        return this.http.get<UsuarioSistema>(`${this.base}/me`).pipe(tap((u) => this.usuario.set(u)));
    }

    atualizarNome(nome: string): Observable<UsuarioSistema> {
        return this.http.put<UsuarioSistema>(`${this.base}/me`, { nome }).pipe(tap((u) => this.usuario.set(u)));
    }

    trocarSenha(senhaAtual: string, novaSenha: string): Observable<void> {
        return this.http.post<void>(`${this.base}/me/senha`, { senhaAtual, novaSenha });
    }

    private aplicar(r: TokenResponse): UsuarioSistema {
        this.token.set(r.accessToken);
        this.usuario.set(r.usuario);
        this.sessao.set(r.sessao ?? null);
        this.agendarRenovacao(r.expiresIn);
        return r.usuario;
    }

    /** Renova 60 s antes de expirar, para o usuário não perder a sessão enquanto trabalha. */
    private agendarRenovacao(expiresIn: number): void {
        if (this.timer) {
            clearTimeout(this.timer);
        }
        const ms = Math.max((expiresIn - 60) * 1000, 15_000);
        this.timer = setTimeout(() => this.renovar().subscribe({ error: () => this.sessaoExpirada() }), ms);
    }

    private irParaLogin(motivo: MotivoEncerramento | 'LOGOUT' | null): void {
        const m = motivo && motivo !== 'LOGOUT' ? (motivo as MotivoEncerramento) : null;
        this.ultimoMotivo.set(m);
        this.router.navigate(['/auth/login'], { queryParams: m ? { motivo: m } : {} });
    }

    private avisarOutrasAbas(motivo: string): void {
        try {
            this.canal?.postMessage({ tipo: 'logout', motivo });
        } catch {
            // canal indisponível
        }
    }

    private limpar(): void {
        if (this.timer) {
            clearTimeout(this.timer);
            this.timer = null;
        }
        this.token.set(null);
        this.usuario.set(null);
        this.sessao.set(null);
    }
}
