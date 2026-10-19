/** "2 h 15 min", "8 min", "45 s". */
export function duracao(seg: number | null | undefined): string {
    if (seg === null || seg === undefined || seg < 0) {
        return '—';
    }
    if (seg < 60) {
        return `${seg} s`;
    }
    const d = Math.floor(seg / 86400);
    const h = Math.floor((seg % 86400) / 3600);
    const m = Math.floor((seg % 3600) / 60);
    if (d > 0) {
        return `${d} d ${h} h`;
    }
    return h > 0 ? `${h} h ${m} min` : `${m} min`;
}

export function corMotivo(m?: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (m) {
        case 'LOGOUT':
            return 'secondary';
        case 'INATIVIDADE':
        case 'EXPIRADA':
        case 'LIMITE_SESSOES':
            return 'warn';
        case 'ENCERRADA_ADMIN':
        case 'USUARIO_BLOQUEADO':
        case 'USUARIO_DESATIVADO':
        case 'USUARIO_EXCLUIDO':
        case 'REUSO_TOKEN':
            return 'danger';
        default:
            return 'info';
    }
}
