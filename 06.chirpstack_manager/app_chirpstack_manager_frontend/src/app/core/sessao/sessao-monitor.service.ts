import { computed, effect, inject, Injectable, signal, untracked } from '@angular/core';
import { SessaoInfo } from '@/app/core/http/models';
import { VisitantesService } from '@/app/pages/visitantes/visitantes.service';
import { AuthService } from '../auth/auth.service';

/** Intervalo do sinal de presença/atividade enviado ao servidor. */
const SINAL_MS = 60_000;
/** Chave usada para as abas abertas compartilharem a última interação. */
const CHAVE_ATIVIDADE = 'csm.atividade';
const EVENTOS: (keyof DocumentEventMap)[] = ['mousemove', 'mousedown', 'keydown', 'wheel', 'scroll', 'touchstart'];

/**
 * Controle de logoff no navegador.
 *
 * - Conta a inatividade a partir da última interação (teclado, mouse, toque) em QUALQUER aba aberta.
 * - Mostra o aviso {@code avisoSegundos} antes do fim; sem resposta, faz o logoff com o motivo
 *   INATIVIDADE (registrado no histórico de visitantes).
 * - Avisa também quando a sessão se aproxima do tempo máximo desde o login.
 * - A cada minuto envia o sinal de presença (on-line no monitor do administrador) com a informação
 *   se houve interação, e recebe de volta a política vigente.
 *
 * O servidor confere as mesmas regras ao renovar o token; o navegador só antecipa o aviso.
 */
@Injectable({ providedIn: 'root' })
export class SessaoMonitorService {
    private auth = inject(AuthService);
    private api = inject(VisitantesService);

    private ultimaAtividade = Date.now();
    private houveAtividade = false;
    private ultimaGravacao = 0;
    /** Diferença entre o relógio do servidor e o do computador (ms). */
    private desvio = 0;
    private tick: ReturnType<typeof setInterval> | null = null;
    private sinal: ReturnType<typeof setInterval> | null = null;
    private ligado = false;
    private encerrando = false;

    private readonly agora = signal(Date.now());

    /** Segundos até o logoff por inatividade (null = controle desligado). */
    readonly restanteInatividade = computed<number | null>(() => {
        const s = this.auth.sessao();
        if (!s || s.inatividadeSegundos <= 0) {
            return null;
        }
        this.agora();
        return Math.max(0, Math.ceil(s.inatividadeSegundos - (Date.now() - this.ultimaAtividade) / 1000));
    });

    /** Segundos até o fim absoluto da sessão. */
    readonly restanteMaximo = computed<number | null>(() => {
        const s = this.auth.sessao();
        if (!s) {
            return null;
        }
        return Math.max(0, Math.ceil((Date.parse(s.expiraEm) - (this.agora() + this.desvio)) / 1000));
    });

    readonly avisoInatividade = computed(() => {
        const r = this.restanteInatividade();
        const s = this.auth.sessao();
        return r !== null && s !== null && r <= s.avisoSegundos;
    });

    readonly avisoMaximo = computed(() => {
        const r = this.restanteMaximo();
        const s = this.auth.sessao();
        return r !== null && s !== null && r <= Math.max(s.avisoSegundos, 300) && !this.avisoInatividade();
    });

    /** O usuário já fechou o aviso de tempo máximo (aparece de novo só no último minuto). */
    readonly avisoMaximoDispensado = signal(false);

    constructor() {
        effect(() => {
            const s = this.auth.sessao();
            untracked(() => (s ? this.ligar(s) : this.desligar()));
        });
    }

    /** "Continuar conectado": conta como interação e avisa o servidor na hora. */
    continuar(): void {
        this.registrar(true);
        this.enviarSinal();
    }

    sairAgora(): void {
        this.auth.logout();
    }

    formatar(seg: number | null): string {
        if (seg === null) {
            return '--:--';
        }
        const h = Math.floor(seg / 3600);
        const m = Math.floor((seg % 3600) / 60);
        const s = seg % 60;
        const p = (n: number) => String(n).padStart(2, '0');
        return h > 0 ? `${h}:${p(m)}:${p(s)}` : `${p(m)}:${p(s)}`;
    }

    // ── Internos ─────────────────────────────────────────────────────────────

    private ligar(s: SessaoInfo): void {
        this.desvio = Date.parse(s.agora) - Date.now();
        if (this.ligado) {
            return;
        }
        this.ligado = true;
        this.encerrando = false;
        this.ultimaAtividade = Date.now();
        this.avisoMaximoDispensado.set(false);
        EVENTOS.forEach((e) => document.addEventListener(e, this.aoInteragir, { passive: true, capture: true }));
        window.addEventListener('storage', this.aoMudarOutraAba);
        this.tick = setInterval(() => this.verificar(), 1000);
        this.sinal = setInterval(() => this.enviarSinal(), SINAL_MS);
    }

    private desligar(): void {
        if (!this.ligado) {
            return;
        }
        this.ligado = false;
        EVENTOS.forEach((e) => document.removeEventListener(e, this.aoInteragir, { capture: true }));
        window.removeEventListener('storage', this.aoMudarOutraAba);
        if (this.tick) {
            clearInterval(this.tick);
        }
        if (this.sinal) {
            clearInterval(this.sinal);
        }
        this.tick = this.sinal = null;
    }

    /** Interação nesta aba. Durante o aviso, só o botão "Continuar conectado" conta. */
    private aoInteragir = (): void => {
        if (this.avisoInatividade()) {
            return;
        }
        this.registrar(false);
    };

    /** Interação em outra aba (mesmo navegador). */
    private aoMudarOutraAba = (e: StorageEvent): void => {
        if (e.key === CHAVE_ATIVIDADE && e.newValue) {
            const t = Number(e.newValue);
            if (Number.isFinite(t) && t > this.ultimaAtividade) {
                this.ultimaAtividade = t;
                this.houveAtividade = true;
                this.agora.set(Date.now());
            }
        }
    };

    private registrar(forcarGravacao: boolean): void {
        const t = Date.now();
        this.ultimaAtividade = t;
        this.houveAtividade = true;
        if (forcarGravacao || t - this.ultimaGravacao > 5000) {
            this.ultimaGravacao = t;
            try {
                localStorage.setItem(CHAVE_ATIVIDADE, String(t));
            } catch {
                // armazenamento indisponível: cada aba conta sozinha
            }
            this.agora.set(t);
        }
    }

    private verificar(): void {
        this.agora.set(Date.now());
        if (this.encerrando) {
            return;
        }
        if (this.restanteInatividade() === 0) {
            this.encerrando = true;
            this.auth.logout('INATIVIDADE');
            return;
        }
        if (this.restanteMaximo() === 0) {
            this.encerrando = true;
            this.auth.logout('EXPIRADA');
            return;
        }
        if (this.avisoMaximoDispensado() && (this.restanteMaximo() ?? 999) <= 60) {
            this.avisoMaximoDispensado.set(false);
        }
    }

    private enviarSinal(): void {
        if (!this.auth.autenticado()) {
            return;
        }
        const ativo = this.houveAtividade;
        this.houveAtividade = false;
        // Erros (inclusive sessão encerrada pelo administrador) são tratados pelo interceptor.
        this.api.atividade(ativo).subscribe({
            next: (info) => this.auth.atualizarSessao(info),
            error: () => {
                if (ativo) {
                    this.houveAtividade = true;
                }
            }
        });
    }
}
