import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@/environments/environment';
import { FalhaLogin, ListResponse, PoliticaSessao, ResumoVisitantes, SessaoInfo, SessaoVisitante, UsuarioSistema, VisitanteUsuario } from '../../core/http/models';

export interface FiltroAcessos {
    usuarioId?: number | null;
    busca?: string;
    situacao?: '' | 'ABERTA' | 'ENCERRADA';
    de?: Date | null;
    ate?: Date | null;
}

/**
 * Visitantes (monitoramento e controle de acesso) e política de sessão (logoff). Somente ADMIN,
 * exceto {@link atividade} e {@link sessaoAtual}, usados por qualquer usuário logado.
 */
@Injectable({ providedIn: 'root' })
export class VisitantesService {
    private http = inject(HttpClient);
    private base = `${environment.apiUrl}/visitantes`;
    private sessao = `${environment.apiUrl}/sessao`;

    resumo(dias = 14): Observable<ResumoVisitantes> {
        return this.http.get<ResumoVisitantes>(`${this.base}/resumo`, { params: { dias } });
    }
    sessoesAbertas(): Observable<SessaoVisitante[]> {
        return this.http.get<SessaoVisitante[]>(`${this.base}/sessoes`);
    }
    porUsuario(): Observable<VisitanteUsuario[]> {
        return this.http.get<VisitanteUsuario[]>(`${this.base}/usuarios`);
    }
    acessos(f: FiltroAcessos, pagina: number, tamanho: number): Observable<ListResponse<SessaoVisitante>> {
        let params = new HttpParams().set('pagina', pagina).set('tamanho', tamanho);
        if (f.usuarioId) params = params.set('usuarioId', f.usuarioId);
        if (f.busca) params = params.set('busca', f.busca);
        if (f.situacao) params = params.set('situacao', f.situacao);
        if (f.de) params = params.set('de', f.de.toISOString());
        if (f.ate) params = params.set('ate', f.ate.toISOString());
        return this.http.get<ListResponse<SessaoVisitante>>(`${this.base}/acessos`, { params });
    }
    falhas(): Observable<FalhaLogin[]> {
        return this.http.get<FalhaLogin[]>(`${this.base}/falhas`);
    }
    encerrarSessao(id: string): Observable<void> {
        return this.http.post<void>(`${this.base}/sessoes/${id}/encerrar`, {});
    }
    encerrarSessoesDoUsuario(usuarioId: number): Observable<{ encerradas: number }> {
        return this.http.post<{ encerradas: number }>(`${this.base}/usuarios/${usuarioId}/encerrar-sessoes`, {});
    }
    encerrarTodas(): Observable<{ encerradas: number }> {
        return this.http.post<{ encerradas: number }>(`${this.base}/encerrar-todas`, {});
    }
    bloquear(usuarioId: number, permanente: boolean, ate: Date | null, motivo: string): Observable<UsuarioSistema> {
        return this.http.post<UsuarioSistema>(`${this.base}/usuarios/${usuarioId}/bloqueio`, { permanente, ate: ate?.toISOString() ?? null, motivo });
    }
    desbloquear(usuarioId: number): Observable<void> {
        return this.http.delete<void>(`${this.base}/usuarios/${usuarioId}/bloqueio`);
    }

    // ── Sessão / política de logoff ─────────────────────────────────────────

    politica(): Observable<PoliticaSessao> {
        return this.http.get<PoliticaSessao>(`${this.sessao}/politica`);
    }
    salvarPolitica(p: PoliticaSessao): Observable<PoliticaSessao> {
        return this.http.put<PoliticaSessao>(`${this.sessao}/politica`, p);
    }
    sessaoAtual(): Observable<SessaoInfo> {
        return this.http.get<SessaoInfo>(this.sessao);
    }
    atividade(ativo: boolean): Observable<SessaoInfo> {
        return this.http.post<SessaoInfo>(`${this.sessao}/atividade`, { ativo });
    }
}
