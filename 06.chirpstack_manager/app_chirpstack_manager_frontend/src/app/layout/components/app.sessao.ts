import { Component, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { ProgressBarModule } from 'primeng/progressbar';
import { TooltipModule } from 'primeng/tooltip';
import { SessaoMonitorService } from '@/app/core/sessao/sessao-monitor.service';
import { AuthService } from '@/app/core/auth/auth.service';

/**
 * Indicador da sessão no topo: tempo até o logoff por inatividade (ou até o fim da sessão, quando a
 * inatividade está desligada). Fica amarelo no aviso e vermelho no último minuto.
 */
@Component({
    selector: 'app-sessao-chip',
    standalone: true,
    imports: [CommonModule, TooltipModule],
    template: `
        @if (auth.sessao(); as s) {
            <div class="hidden md:flex items-center gap-2 px-3 h-9 rounded-lg border text-sm font-medium tabular-nums select-none transition-colors" [ngClass]="classe()" [pTooltip]="dica()" tooltipPosition="bottom" [escape]="false">
                <i class="pi" [ngClass]="m.restanteInatividade() !== null ? 'pi-stopwatch' : 'pi-clock'"></i>
                <span>{{ m.formatar(valor()) }}</span>
            </div>
        }
    `
})
export class SessaoChip {
    auth = inject(AuthService);
    m = inject(SessaoMonitorService);

    valor = computed(() => this.m.restanteInatividade() ?? this.m.restanteMaximo());

    classe = computed(() => {
        const v = this.valor() ?? 9999;
        if (v <= 60) {
            return 'border-red-300 bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-300 dark:border-red-800';
        }
        if (this.m.avisoInatividade() || this.m.avisoMaximo()) {
            return 'border-amber-300 bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 dark:border-amber-800';
        }
        return 'border-surface-200 dark:border-surface-700 text-surface-600 dark:text-surface-300';
    });

    dica = computed(() => {
        const s = this.auth.sessao();
        if (!s) {
            return '';
        }
        const fim = new Date(s.expiraEm).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
        const inat = s.inatividadeSegundos > 0 ? `Logoff automático após <b>${Math.round(s.inatividadeSegundos / 60)} min</b> sem uso.<br>` : 'Sem logoff por inatividade.<br>';
        return `${inat}A sessão termina em <b>${fim}</b> (tempo máximo).`;
    });
}

/**
 * Aviso de logoff: inatividade (com "Continuar conectado") e tempo máximo da sessão.
 */
@Component({
    selector: 'app-sessao-aviso',
    standalone: true,
    imports: [CommonModule, ButtonModule, DialogModule, ProgressBarModule],
    template: `
        <p-dialog [visible]="m.avisoInatividade()" [modal]="true" [closable]="false" [draggable]="false" [resizable]="false" [style]="{ width: '30rem' }" [breakpoints]="{ '640px': '95vw' }">
            <ng-template #header>
                <div class="flex items-center gap-3">
                    <span class="w-10 h-10 rounded-xl bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300 flex items-center justify-center"><i class="pi pi-stopwatch text-lg!"></i></span>
                    <span class="font-semibold text-lg">Sua sessão vai expirar</span>
                </div>
            </ng-template>
            <p class="m-0 text-surface-600 dark:text-surface-300">Não detectamos atividade há algum tempo. Por segurança, você será desconectado em:</p>
            <div class="text-5xl font-semibold text-center my-6 tabular-nums" [class.text-red-500]="(m.restanteInatividade() ?? 99) <= 15">{{ m.formatar(m.restanteInatividade()) }}</div>
            <p-progressbar [value]="percentual()" [showValue]="false" styleClass="h-2!" />
            <ng-template #footer>
                <p-button label="Sair agora" icon="pi pi-sign-out" severity="secondary" [outlined]="true" (onClick)="m.sairAgora()" />
                <p-button label="Continuar conectado" icon="pi pi-check" (onClick)="m.continuar()" />
            </ng-template>
        </p-dialog>

        <p-dialog [visible]="m.avisoMaximo() && !m.avisoMaximoDispensado()" [modal]="true" [closable]="false" [draggable]="false" [resizable]="false" [style]="{ width: '30rem' }" [breakpoints]="{ '640px': '95vw' }">
            <ng-template #header>
                <div class="flex items-center gap-3">
                    <span class="w-10 h-10 rounded-xl bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300 flex items-center justify-center"><i class="pi pi-clock text-lg!"></i></span>
                    <span class="font-semibold text-lg">Tempo máximo da sessão</span>
                </div>
            </ng-template>
            <p class="m-0 text-surface-600 dark:text-surface-300">
                Sua sessão atinge o tempo máximo permitido em <b class="tabular-nums">{{ m.formatar(m.restanteMaximo()) }}</b>. Conclua o que estiver fazendo: depois disso será preciso entrar novamente.
            </p>
            <ng-template #footer>
                <p-button label="Sair agora" icon="pi pi-sign-out" severity="secondary" [outlined]="true" (onClick)="m.sairAgora()" />
                <p-button label="Entendi" icon="pi pi-check" (onClick)="m.avisoMaximoDispensado.set(true)" />
            </ng-template>
        </p-dialog>
    `
})
export class AppSessaoAviso {
    m = inject(SessaoMonitorService);
    private auth = inject(AuthService);

    percentual = computed(() => {
        const s = this.auth.sessao();
        const r = this.m.restanteInatividade();
        if (!s || r === null || s.avisoSegundos <= 0) {
            return 0;
        }
        return Math.max(0, Math.min(100, Math.round((r / s.avisoSegundos) * 100)));
    });
}
