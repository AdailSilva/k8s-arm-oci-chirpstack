import { BackupJob, StatusJob } from '@/app/core/http/models';

export function tamanho(bytes?: number | null): string {
    if (bytes === null || bytes === undefined) {
        return '—';
    }
    if (bytes < 1024) {
        return `${bytes} B`;
    }
    const u = ['KB', 'MB', 'GB', 'TB'];
    let v = bytes;
    let i = -1;
    while (v >= 1024 && i < u.length - 1) {
        v /= 1024;
        i++;
    }
    return `${v.toLocaleString('pt-BR', { maximumFractionDigits: 1 })} ${u[i]}`;
}

export function corStatus(s: StatusJob | string | undefined): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (s) {
        case 'SUCESSO':
            return 'success';
        case 'PARCIAL':
        case 'IGNORADO':
            return 'warn';
        case 'ERRO':
            return 'danger';
        case 'EXECUTANDO':
        case 'PENDENTE':
            return 'info';
        default:
            return 'secondary';
    }
}

export const ROTULO_STATUS: Record<string, string> = {
    PENDENTE: 'Na fila',
    EXECUTANDO: 'Executando',
    SUCESSO: 'Concluído',
    PARCIAL: 'Parcial',
    ERRO: 'Erro',
    IGNORADO: 'Ignorado'
};

export const ROTULO_ORIGEM: Record<string, string> = {
    MANUAL: 'Manual',
    AGENDADO: 'Agendado',
    EXECUTAR_AGORA: 'Executar agora'
};

export function duracaoJob(j: BackupJob): string {
    if (!j.iniciadoEm) {
        return '—';
    }
    const fim = j.finalizadoEm ? Date.parse(j.finalizadoEm) : Date.now();
    const s = Math.max(0, Math.round((fim - Date.parse(j.iniciadoEm)) / 1000));
    return s < 60 ? `${s} s` : `${Math.floor(s / 60)} min ${s % 60} s`;
}

export const DIAS_SEMANA = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
