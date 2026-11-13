import { CONTATOS } from './site.config';

export interface Canal {
    id: 'whatsapp' | 'email' | 'linkedin' | 'github' | 'instagram';
    rotulo: string;
    valor: string;
    icone: string;
    href: string;
}

export function linkWhatsapp(mensagem = ''): string {
    const texto = mensagem ? `?text=${encodeURIComponent(mensagem)}` : '';
    return `https://wa.me/${CONTATOS.whatsapp}${texto}`;
}

export function linkEmail(assunto = '', corpo = ''): string {
    const params = new URLSearchParams();
    if (assunto) params.set('subject', assunto);
    if (corpo) params.set('body', corpo);
    const qs = params.toString().replace(/\+/g, '%20');
    return `mailto:${CONTATOS.email}${qs ? '?' + qs : ''}`;
}

/** Formata 5589994129256 → +55 (89) 99412-9256 */
export function telefoneFormatado(): string {
    const d = CONTATOS.whatsapp.replace(/\D/g, '');
    const m = d.match(/^(\d{2})(\d{2})(\d{4,5})(\d{4})$/);
    return m ? `+${m[1]} (${m[2]}) ${m[3]}-${m[4]}` : d;
}

function usuario(url: string): string {
    return url.replace(/\/+$/, '').split('/').pop() ?? url;
}

/** Canais configurados (os vazios ficam de fora). */
export function canais(): Canal[] {
    const lista: Canal[] = [];
    if (CONTATOS.whatsapp) lista.push({ id: 'whatsapp', rotulo: 'WhatsApp', valor: telefoneFormatado(), icone: 'pi pi-whatsapp', href: linkWhatsapp('Olá, Adail! Vim pelo site do ChirpStack na OCI Always Free e gostaria de conversar sobre LoRaWAN.') });
    if (CONTATOS.email) lista.push({ id: 'email', rotulo: 'E-mail', valor: CONTATOS.email, icone: 'pi pi-envelope', href: linkEmail('Contato pelo site') });
    if (CONTATOS.linkedin) lista.push({ id: 'linkedin', rotulo: 'LinkedIn', valor: 'in/' + usuario(CONTATOS.linkedin), icone: 'pi pi-linkedin', href: CONTATOS.linkedin });
    if (CONTATOS.github) lista.push({ id: 'github', rotulo: 'GitHub', valor: usuario(CONTATOS.github), icone: 'pi pi-github', href: CONTATOS.github });
    if (CONTATOS.instagram) lista.push({ id: 'instagram', rotulo: 'Instagram', valor: '@' + usuario(CONTATOS.instagram), icone: 'pi pi-instagram', href: CONTATOS.instagram });
    return lista;
}
