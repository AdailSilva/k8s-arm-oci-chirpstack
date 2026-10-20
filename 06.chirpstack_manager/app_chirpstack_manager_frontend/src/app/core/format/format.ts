import { Int64 } from '@/app/core/http/models';

/** Converte Int64 (texto ou número) em número. */
export function num(v: Int64 | null | undefined, padrao = 0): number {
    if (v === null || v === undefined || v === '') {
        return padrao;
    }
    const n = typeof v === 'number' ? v : Number(v);
    return Number.isFinite(n) ? n : padrao;
}

/** Hex aleatório com {@code bytes} bytes (usa crypto.getRandomValues). */
export function hexAleatorio(bytes: number): string {
    const arr = new Uint8Array(bytes);
    crypto.getRandomValues(arr);
    return Array.from(arr, (b) => b.toString(16).padStart(2, '0')).join('');
}

export function isHex(v: string | null | undefined, bytes: number): boolean {
    return !!v && new RegExp(`^[0-9a-fA-F]{${bytes * 2}}$`).test(v);
}

/** "há 5 min", "há 2 h", "há 3 d" ou "nunca". */
export function tempoRelativo(iso?: string | null): string {
    if (!iso) {
        return 'nunca';
    }
    const t = new Date(iso).getTime();
    if (!Number.isFinite(t) || t <= 0) {
        return 'nunca';
    }
    const s = Math.round((Date.now() - t) / 1000);
    if (s < 60) {
        return 'agora';
    }
    if (s < 3600) {
        return `há ${Math.floor(s / 60)} min`;
    }
    if (s < 86400) {
        return `há ${Math.floor(s / 3600)} h`;
    }
    return `há ${Math.floor(s / 86400)} d`;
}

export function dataHora(iso?: string | null): string {
    if (!iso) {
        return '—';
    }
    const d = new Date(iso);
    return Number.isFinite(d.getTime()) ? d.toLocaleString('pt-BR') : '—';
}

/** Base64 → hexadecimal (payloads de downlink). */
export function base64ParaHex(b64?: string | null): string {
    if (!b64) {
        return '';
    }
    try {
        const bin = atob(b64);
        return Array.from(bin, (c) => c.charCodeAt(0).toString(16).padStart(2, '0')).join('');
    } catch {
        return '';
    }
}

/** Hexadecimal → base64. Lança erro se o texto não for hex válido. */
export function hexParaBase64(hex: string): string {
    const limpo = hex.replace(/\s+/g, '');
    if (limpo.length % 2 !== 0 || !/^[0-9a-fA-F]*$/.test(limpo)) {
        throw new Error('Hexadecimal inválido.');
    }
    let bin = '';
    for (let i = 0; i < limpo.length; i += 2) {
        bin += String.fromCharCode(parseInt(limpo.substring(i, i + 2), 16));
    }
    return btoa(bin);
}

export function textoParaBase64(texto: string): string {
    const bytes = new TextEncoder().encode(texto);
    let bin = '';
    bytes.forEach((b) => (bin += String.fromCharCode(b)));
    return btoa(bin);
}

/** Baixa um texto como arquivo. */
export function baixarArquivo(nome: string, conteudo: string, tipo = 'text/plain'): void {
    const blob = new Blob([conteudo], { type: tipo });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = nome;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 500);
}
