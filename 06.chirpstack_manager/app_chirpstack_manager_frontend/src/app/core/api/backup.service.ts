import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@/environments/environment';
import { AgendamentoBackup, ArquivoBackup, BackupJob, BackupVisaoGeral, GoogleDriveConfig, ResultadoEnvioDrive } from './models';

export interface GoogleDriveForm {
    clientId?: string;
    clientSecret?: string;
    pastaNome?: string;
    enviarManuais?: boolean;
    retencaoDias?: number;
    manterMinimo?: number;
}

/**
 * Backup e restauração do banco do painel, backup automático e Google Drive (somente ADMIN).
 */
@Injectable({ providedIn: 'root' })
export class BackupService {
    private http = inject(HttpClient);
    private base = `${environment.apiUrl}/backup`;

    visaoGeral(): Observable<BackupVisaoGeral> {
        return this.http.get<BackupVisaoGeral>(this.base);
    }
    arquivos(): Observable<ArquivoBackup[]> {
        return this.http.get<ArquivoBackup[]>(`${this.base}/arquivos`);
    }
    baixar(a: ArquivoBackup): Observable<Blob> {
        const params = new HttpParams().set('pasta', a.pasta).set('nome', a.nome);
        return this.http.get(`${this.base}/arquivos/download`, { params, responseType: 'blob' });
    }
    excluir(a: ArquivoBackup): Observable<void> {
        const params = new HttpParams().set('pasta', a.pasta).set('nome', a.nome);
        return this.http.delete<void>(`${this.base}/arquivos`, { params });
    }
    executar(formatos: string[], enviarDrive: boolean): Observable<BackupJob> {
        return this.http.post<BackupJob>(`${this.base}/executar`, { formatos, enviarDrive });
    }
    restaurarUpload(arquivo: File, backupSeguranca: boolean): Observable<BackupJob> {
        const form = new FormData();
        form.append('arquivo', arquivo, arquivo.name);
        return this.http.post<BackupJob>(`${this.base}/restaurar`, form, { params: { backupSeguranca } });
    }
    restaurarDoServidor(a: ArquivoBackup, backupSeguranca: boolean): Observable<BackupJob> {
        return this.http.post<BackupJob>(`${this.base}/restaurar/servidor`, { pasta: a.pasta, nome: a.nome, backupSeguranca });
    }
    job(id: string): Observable<BackupJob> {
        return this.http.get<BackupJob>(`${this.base}/jobs/${id}`);
    }
    historico(limite = 50, agendados = false): Observable<BackupJob[]> {
        return this.http.get<BackupJob[]>(`${this.base}/jobs`, { params: { limite, agendados } });
    }

    agendamento(): Observable<AgendamentoBackup> {
        return this.http.get<AgendamentoBackup>(`${this.base}/agendamento`);
    }
    salvarAgendamento(a: AgendamentoBackup): Observable<AgendamentoBackup> {
        return this.http.put<AgendamentoBackup>(`${this.base}/agendamento`, a);
    }
    executarAgora(): Observable<BackupJob> {
        return this.http.post<BackupJob>(`${this.base}/agendamento/executar-agora`, {});
    }

    drive(): Observable<GoogleDriveConfig> {
        return this.http.get<GoogleDriveConfig>(`${this.base}/google-drive`);
    }
    salvarDrive(f: GoogleDriveForm): Observable<GoogleDriveConfig> {
        return this.http.put<GoogleDriveConfig>(`${this.base}/google-drive`, f);
    }
    autorizarDrive(): Observable<{ url: string }> {
        return this.http.post<{ url: string }>(`${this.base}/google-drive/autorizar`, {});
    }
    desconectarDrive(): Observable<GoogleDriveConfig> {
        return this.http.delete<GoogleDriveConfig>(`${this.base}/google-drive/conexao`);
    }
    testarDrive(): Observable<ResultadoEnvioDrive> {
        return this.http.post<ResultadoEnvioDrive>(`${this.base}/google-drive/testar`, {});
    }
}
