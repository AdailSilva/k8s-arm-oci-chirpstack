import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { CheckboxModule } from 'primeng/checkbox';
import { InputNumberModule } from 'primeng/inputnumber';
import { MessageModule } from 'primeng/message';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { VisitantesService } from '@/app/core/api/visitantes.service';
import { PoliticaSessao } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { SessaoMonitorService } from '@/app/core/auth/sessao-monitor.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora } from '@/app/core/util/format';
import { PageHeader } from '@/app/shared/page-header';

/**
 * Controle de logoff: política de sessão aplicada a todos os usuários (somente ADMIN).
 */
@Component({
    selector: 'app-controle-sessao',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, CheckboxModule, InputNumberModule, MessageModule, ToggleSwitchModule, PageHeader],
    template: `
        <app-page-header title="Controle de sessão" subtitle="Regras de logoff automático aplicadas a todos os usuários do painel" icon="pi pi-stopwatch">
            <p-button icon="pi pi-users" label="Visitantes" severity="secondary" [outlined]="true" routerLink="/sistema/visitantes" />
            <p-button icon="pi pi-check" label="Salvar" (onClick)="salvar()" [loading]="salvando()" [disabled]="!form()" />
        </app-page-header>

        @if (form(); as f) {
            <div class="grid grid-cols-1 xl:grid-cols-12 gap-6">
                <div class="xl:col-span-8 flex flex-col gap-6">
                    <div class="card mb-0!">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <div class="font-semibold text-lg">Logoff por inatividade</div>
                                <p class="text-surface-500 m-0 mt-1">Sem teclado, mouse ou toque em nenhuma aba do sistema por esse tempo, a sessão é encerrada. Antes disso aparece um aviso com contagem regressiva e a opção de continuar conectado.</p>
                            </div>
                            <p-toggleswitch [(ngModel)]="inatividadeLigada" (ngModelChange)="alternarInatividade($event)" />
                        </div>
                        @if (inatividadeLigada) {
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
                                <div>
                                    <label class="block font-medium mb-2">Tempo sem uso</label>
                                    <p-inputnumber [(ngModel)]="f.inatividadeMinutos" [min]="1" [max]="1440" suffix=" min" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                                    <div class="flex flex-wrap gap-2 mt-2">
                                        @for (m of [5, 15, 30, 60, 120]; track m) {
                                            <p-button [label]="m < 60 ? m + ' min' : m / 60 + ' h'" size="small" [severity]="f.inatividadeMinutos === m ? 'primary' : 'secondary'" [outlined]="f.inatividadeMinutos !== m" (onClick)="f.inatividadeMinutos = m" />
                                        }
                                    </div>
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">Avisar antes</label>
                                    <p-inputnumber [(ngModel)]="f.avisoSegundos" [min]="15" [max]="900" suffix=" s" [showButtons]="true" [step]="15" inputStyleClass="w-full" styleClass="w-full" />
                                    <div class="flex flex-wrap gap-2 mt-2">
                                        @for (s of [30, 60, 120, 300]; track s) {
                                            <p-button [label]="s < 60 ? s + ' s' : s / 60 + ' min'" size="small" [severity]="f.avisoSegundos === s ? 'primary' : 'secondary'" [outlined]="f.avisoSegundos !== s" (onClick)="f.avisoSegundos = s" />
                                        }
                                    </div>
                                </div>
                            </div>
                            @if (f.avisoSegundos >= f.inatividadeMinutos * 60) {
                                <p-message severity="warn" text="O aviso precisa vir antes do fim do tempo sem uso." styleClass="w-full mt-4" />
                            }
                        }
                    </div>

                    <div class="card mb-0!">
                        <div class="font-semibold text-lg">Duração máxima da sessão</div>
                        <p class="text-surface-500 m-0 mt-1">Limite absoluto desde o login, mesmo com o sistema em uso. Depois dele é preciso entrar de novo (o usuário é avisado alguns minutos antes).</p>
                        <div class="mt-5 max-w-md">
                            <p-inputnumber [(ngModel)]="f.duracaoMaximaHoras" [min]="1" [max]="720" suffix=" h" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                            <div class="flex flex-wrap gap-2 mt-2">
                                @for (h of [4, 8, 12, 24, 168]; track h) {
                                    <p-button [label]="h === 168 ? '7 dias' : h + ' h'" size="small" [severity]="f.duracaoMaximaHoras === h ? 'primary' : 'secondary'" [outlined]="f.duracaoMaximaHoras !== h" (onClick)="f.duracaoMaximaHoras = h" />
                                }
                            </div>
                        </div>
                    </div>

                    <div class="card mb-0!">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <div class="font-semibold text-lg">Sessões simultâneas</div>
                                <p class="text-surface-500 m-0 mt-1">Quantos dispositivos cada usuário pode usar ao mesmo tempo. Ao entrar além do limite, a sessão mais antiga é encerrada com o aviso "você entrou em outro dispositivo".</p>
                            </div>
                            <p-toggleswitch [(ngModel)]="limitarSimultaneas" (ngModelChange)="f.maxSessoesPorUsuario = $event ? 1 : 0" />
                        </div>
                        @if (limitarSimultaneas) {
                            <div class="mt-5 max-w-md">
                                <label class="block font-medium mb-2">Máximo por usuário</label>
                                <p-inputnumber [(ngModel)]="f.maxSessoesPorUsuario" [min]="1" [max]="20" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                            </div>
                        }
                    </div>

                    <div class="card mb-0!">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <div class="font-semibold text-lg">Manter conectado ao fechar o navegador</div>
                                <p class="text-surface-500 m-0 mt-1">Desligado, a credencial de renovação some quando o navegador é fechado: ao abrir de novo, é preciso entrar (logoff ao fechar). Vale a partir do próximo login.</p>
                            </div>
                            <p-toggleswitch [(ngModel)]="f.manterConectado" />
                        </div>
                    </div>

                    <div class="card mb-0! flex flex-col md:flex-row md:items-center justify-between gap-4">
                        <label class="flex items-center gap-3 cursor-pointer">
                            <p-checkbox [(ngModel)]="f.encerrarSessoesAbertas" [binary]="true" />
                            <span>Aplicar agora encerrando as sessões abertas (exceto a sua)</span>
                        </label>
                        <div class="text-sm text-surface-500">
                            @if (politica()?.atualizadoEm) {
                                Última alteração em {{ data(politica()!.atualizadoEm) }}{{ politica()!.atualizadoPor ? ' por ' + politica()!.atualizadoPor : '' }}
                            }
                        </div>
                    </div>
                </div>

                <div class="xl:col-span-4 flex flex-col gap-6">
                    <div class="card mb-0!">
                        <div class="font-semibold text-lg mb-4">Sua sessão agora</div>
                        @if (auth.sessao(); as s) {
                            <div class="flex flex-col gap-3 text-sm">
                                <div class="flex justify-between"><span class="text-surface-500">Logoff por inatividade em</span><b class="tabular-nums">{{ monitor.restanteInatividade() === null ? 'desligado' : monitor.formatar(monitor.restanteInatividade()) }}</b></div>
                                <div class="flex justify-between"><span class="text-surface-500">Fim da sessão (máximo)</span><b>{{ data(s.expiraEm) }}</b></div>
                                <div class="flex justify-between"><span class="text-surface-500">Manter conectado</span><b>{{ s.manterConectado ? 'Sim' : 'Não' }}</b></div>
                            </div>
                        }
                    </div>
                    <div class="card mb-0!">
                        <div class="font-semibold text-lg mb-3">Como funciona</div>
                        <ul class="m-0 pl-5 text-sm text-surface-600 dark:text-surface-300 flex flex-col gap-2 list-disc">
                            <li>O navegador conta a inatividade em todas as abas abertas e avisa antes do logoff.</li>
                            <li>O servidor confere as mesmas regras: uma aba esquecida aberta não mantém a sessão viva.</li>
                            <li>Sessões encerradas pelo administrador (tela Visitantes) caem na hora, sem esperar o token vencer.</li>
                            <li>Todo encerramento fica no histórico de visitantes com o motivo: saiu, inatividade, tempo máximo, administrador...</li>
                            <li>Alterações valem para as sessões abertas em até 1 minuto (o tempo máximo, a partir do próximo login).</li>
                        </ul>
                    </div>
                </div>
            </div>
        }
    `
})
export class ControleSessao implements OnInit {
    private api = inject(VisitantesService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);
    monitor = inject(SessaoMonitorService);

    politica = signal<PoliticaSessao | null>(null);
    salvando = signal(false);
    form = signal<PoliticaSessao | null>(null);
    inatividadeLigada = true;
    limitarSimultaneas = false;
    /** Último valor de inatividade antes de desligar, para voltar a ele ao religar. */
    private ultimaInatividade = 30;
    data = dataHora;

    ngOnInit(): void {
        this.api.politica().subscribe({ next: (p) => this.aplicar(p), error: (e) => this.notify.erro(e) });
    }

    alternarInatividade(ligada: boolean): void {
        const f = this.form();
        if (!f) {
            return;
        }
        if (ligada) {
            f.inatividadeMinutos = this.ultimaInatividade || 30;
        } else {
            this.ultimaInatividade = f.inatividadeMinutos || 30;
            f.inatividadeMinutos = 0;
        }
    }

    salvar(): void {
        const f = this.form();
        if (!f) {
            return;
        }
        if (f.inatividadeMinutos > 0 && f.avisoSegundos >= f.inatividadeMinutos * 60) {
            this.notify.aviso('O aviso precisa vir antes do fim do tempo sem uso.');
            return;
        }
        this.salvando.set(true);
        this.api.salvarPolitica(f).subscribe({
            next: (p) => {
                this.salvando.set(false);
                this.aplicar(p);
                this.notify.sucesso(f.encerrarSessoesAbertas ? 'Política salva e sessões abertas encerradas.' : 'Política de sessão salva.');
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    private aplicar(p: PoliticaSessao): void {
        this.politica.set(p);
        this.form.set({ ...p, encerrarSessoesAbertas: false });
        this.inatividadeLigada = p.inatividadeMinutos > 0;
        this.limitarSimultaneas = p.maxSessoesPorUsuario > 0;
        if (p.inatividadeMinutos > 0) {
            this.ultimaInatividade = p.inatividadeMinutos;
        }
    }
}
