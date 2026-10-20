import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@/environments/environment';
import { ListResponse, PerfilAcesso, RegistroAuditoria, UsuarioSistema } from './models';

export interface UsuarioSistemaForm {
    nome: string;
    email: string;
    perfil: PerfilAcesso;
    ativo: boolean;
    senha?: string;
    novaSenha?: string;
}

/**
 * Usuários do painel e auditoria (recursos do próprio backend, não do ChirpStack).
 */
@Injectable({ providedIn: 'root' })
export class SistemaService {
    private http = inject(HttpClient);
    private base = environment.apiUrl;

    listarUsuarios(busca: string, pagina: number, tamanho: number): Observable<ListResponse<UsuarioSistema>> {
        const params = new HttpParams().set('busca', busca ?? '').set('pagina', pagina).set('tamanho', tamanho);
        return this.http.get<ListResponse<UsuarioSistema>>(`${this.base}/usuarios`, { params });
    }
    criarUsuario(u: UsuarioSistemaForm): Observable<UsuarioSistema> {
        return this.http.post<UsuarioSistema>(`${this.base}/usuarios`, u);
    }
    atualizarUsuario(id: number, u: UsuarioSistemaForm): Observable<UsuarioSistema> {
        return this.http.put<UsuarioSistema>(`${this.base}/usuarios/${id}`, u);
    }
    desbloquearUsuario(id: number): Observable<void> {
        return this.http.post<void>(`${this.base}/usuarios/${id}/desbloquear`, {});
    }
    excluirUsuario(id: number): Observable<void> {
        return this.http.delete<void>(`${this.base}/usuarios/${id}`);
    }

    listarAuditoria(busca: string, acao: string, pagina: number, tamanho: number): Observable<ListResponse<RegistroAuditoria>> {
        const params = new HttpParams().set('busca', busca ?? '').set('acao', acao ?? '').set('pagina', pagina).set('tamanho', tamanho);
        return this.http.get<ListResponse<RegistroAuditoria>>(`${this.base}/auditoria`, { params });
    }
}
