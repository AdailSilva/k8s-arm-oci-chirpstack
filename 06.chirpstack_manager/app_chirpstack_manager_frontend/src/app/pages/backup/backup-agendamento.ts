import { Component, computed, inject, input, OnInit, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { CheckboxModule } from 'primeng/checkbox';
import { InputNumberModule } from 'primeng/inputnumber';
import { MessageModule } from 'primeng/message';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { TooltipModule } from 'primeng/tooltip';
import { BackupService } from '@/app/pages/backup/backup.service';
import { AgendamentoBackup, BackupJob } from '@/app/core/http/models';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora } from '@/app/core/format/format';
import { corStatus, DIAS_SEMANA, ROTULO_ORIGEM, ROTULO_STATUS } from './backup-util';

/**
 * Backup automático: grade semanal com vários horários por dia, formatos, destinos (servidor e/ou
 * Google Drive) e retenção.
 */
@Component({
    selector: 'app-backup-agendamento',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, CheckboxModule, InputNumberModule, MessageModule, TableModule, TagModule, ToggleSwitchModule, TooltipModule],
    template: `
        @if (form(); as f) {
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6 p-4 rounded-2xl border" [ngClass]="f.ativo ? 'border-green-300 bg-green-50/50 dark:bg-green-900/10 dark:border-green-800' : ''">
                <label class="flex items-center gap-3 cursor-pointer">
                    <p-toggleswitch [(ngModel)]="f.ativo" (ngModelChange)="sujo.set(true)" />
                    <span>
                        <span class="font-semibold text-lg">Backup automático {{ f.ativo ? 'ligado' : 'desligado' }}</span><br />
                        <span class="text-sm text-surface-500">
                            @if (salvo()?.ativo && salvo()?.proximaExecucao) {
                                Próxima execução: <b>{{ data(salvo()!.proximaExecucao) }}</b>
                            } @else {
                                Nenhuma execução programada
                            }
                            · fuso {{ salvo()?.fusoHorario }}
                        </span>
                    </span>
                </label>
                <div class="flex flex-wrap gap-2">
                    @if (sujo()) {
                        <p-button label="Descartar" icon="pi pi-undo" [text]="true" severity="secondary" (onClick)="carregar()" />
                    }
                    <p-button label="Executar agora" icon="pi pi-play" [outlined]="true" severity="secondary" (onClick)="executarAgora()" [loading]="executando()" pTooltip="Gera um backup agora com estas configurações (salve antes, se alterou algo)" tooltipPosition="bottom" />
                    <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
                </div>
            </div>

            <div class="grid grid-cols-1 xl:grid-cols-12 gap-6">
                <div class="xl:col-span-7 border rounded-2xl p-5">
                    <div class="flex flex-wrap items-center justify-between gap-2 mb-4">
                        <div class="font-semibold text-lg">Horários</div>
                        <div class="flex flex-wrap gap-2">
                            <p-button label="Todo dia às 02:00" icon="pi pi-moon" size="small" [outlined]="true" severity="secondary" (onClick)="todoDia('02:00')" />
                            <p-button label="Segunda → dias úteis" icon="pi pi-copy" size="small" [outlined]="true" severity="secondary" (onClick)="copiarSegunda(5)" />
                            <p-button label="Segunda → todos" icon="pi pi-clone" size="small" [outlined]="true" severity="secondary" (onClick)="copiarSegunda(7)" />
                            <p-button label="Limpar" icon="pi pi-eraser" size="small" [text]="true" severity="secondary" (onClick)="limpar()" />
                        </div>
                    </div>
                    <div class="flex flex-col divide-y divide-surface-200 dark:divide-surface-700">
                        @for (nome of dias; track $index; let i = $index) {
                            <div class="flex flex-col md:flex-row md:items-center gap-3 py-3">
                                <div class="w-28 font-medium shrink-0">{{ nome }}</div>
                                <div class="flex flex-wrap items-center gap-2 flex-1">
                                    @for (h of horasDoDia(i + 1); track h) {
                                        <span class="inline-flex items-center gap-1 pl-3 pr-1 py-1 rounded-full bg-primary-50 dark:bg-primary-900/30 text-primary font-medium text-sm tabular-nums">
                                            {{ h }}
                                            <button type="button" class="w-6 h-6 rounded-full hover:bg-primary-100 dark:hover:bg-primary-800 flex items-center justify-center cursor-pointer" (click)="remover(i + 1, h)" [attr.aria-label]="'Remover ' + h"><i class="pi pi-times text-xs!"></i></button>
                                        </span>
                                    } @empty {
                                        <span class="text-sm text-surface-400">sem backup</span>
                                    }
                                </div>
                                <div class="flex items-center gap-2">
                                    <input type="time" class="p-inputtext p-component w-36" [(ngModel)]="novaHora[i]" />
                                    <p-button icon="pi pi-plus" size="small" [outlined]="true" (onClick)="adicionar(i + 1)" pTooltip="Adicionar horário" />
                                </div>
                            </div>
                        }
                    </div>
                </div>

                <div class="xl:col-span-5 flex flex-col gap-6">
                    <div class="border rounded-2xl p-5">
                        <div class="font-semibold text-lg mb-3">Formatos</div>
                        <div class="flex flex-wrap gap-4">
                            @for (fmt of formatosDisponiveis(); track fmt) {
                                <label class="flex items-center gap-2 cursor-pointer">
                                    <p-checkbox [binary]="true" [ngModel]="f.formatos.includes(fmt)" (ngModelChange)="alternarFormato(fmt, $event)" />
                                    <span>.{{ fmt }}</span>
                                </label>
                            }
                        </div>
                    </div>
                    <div class="border rounded-2xl p-5">
                        <div class="font-semibold text-lg mb-3">Destinos</div>
                        <div class="flex flex-col gap-3">
                            <label class="flex items-center gap-3 cursor-pointer">
                                <p-toggleswitch [(ngModel)]="f.destinoServidor" (ngModelChange)="sujo.set(true)" />
                                <span>Pasta <b>agendados/</b> do servidor</span>
                            </label>
                            <label class="flex items-center gap-3" [pTooltip]="salvo()?.driveConectado ? '' : 'Conecte uma conta na aba Google Drive'">
                                <p-toggleswitch [(ngModel)]="f.destinoDrive" (ngModelChange)="sujo.set(true)" [disabled]="!salvo()?.driveConectado && !f.destinoDrive" />
                                <span>Google Drive</span>
                                @if (!salvo()?.driveConectado) {
                                    <p-tag value="não conectado" severity="secondary" [rounded]="true" />
                                }
                            </label>
                            @if (!f.destinoServidor && !f.destinoDrive) {
                                <p-message severity="warn" text="Escolha pelo menos um destino." styleClass="w-full" />
                            }
                            @if (!f.destinoServidor && f.destinoDrive) {
                                <p-message severity="info" text="Os arquivos são gerados numa área temporária e apagados depois do envio. Se o envio falhar, ficam guardados em agendados/." styleClass="w-full" />
                            }
                        </div>
                    </div>
                    <div class="border rounded-2xl p-5">
                        <div class="font-semibold text-lg mb-1">Retenção no servidor</div>
                        <p class="text-sm text-surface-500 m-0 mb-4">Depois de cada backup automático, apaga os arquivos de agendados/ mais velhos que o limite. A retenção do Drive é configurada na aba Google Drive.</p>
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <label class="block font-medium mb-2 text-sm">Apagar após</label>
                                <p-inputnumber [(ngModel)]="f.retencaoDias" (ngModelChange)="sujo.set(true)" [min]="0" [max]="3650" suffix=" dias" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                                <small class="text-surface-500">0 = nunca apagar</small>
                            </div>
                            <div>
                                <label class="block font-medium mb-2 text-sm">Manter no mínimo</label>
                                <p-inputnumber [(ngModel)]="f.manterMinimo" (ngModelChange)="sujo.set(true)" [min]="1" [max]="100" suffix=" por formato" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="mt-6">
                <div class="font-semibold text-lg mb-3">Últimas execuções automáticas</div>
                <p-table [value]="execucoes()" [rowHover]="true" styleClass="p-datatable-sm" [tableStyle]="{ 'min-width': '50rem' }">
                    <ng-template #header>
                        <tr>
                            <th class="w-44">Programado / início</th>
                            <th class="w-36">Origem</th>
                            <th class="w-32">Situação</th>
                            <th>Mensagem</th>
                        </tr>
                    </ng-template>
                    <ng-template #body let-j>
                        <tr>
                            <td class="text-sm">{{ data(j.agendadoPara || j.criadoEm) }}</td>
                            <td class="text-sm">{{ rotuloOrigem[j.origem] }}</td>
                            <td><p-tag [value]="rotuloStatus[j.status]" [severity]="cor(j.status)" [rounded]="true" /></td>
                            <td class="text-sm">{{ j.mensagem }}@if (j.driveMensagem) {<div class="text-surface-500 text-xs">Drive: {{ j.driveMensagem }}</div>}</td>
                        </tr>
                    </ng-template>
                    <ng-template #emptymessage>
                        <tr><td colspan="4" class="text-center py-6 text-surface-500">Nenhuma execução automática ainda.</td></tr>
                    </ng-template>
                </p-table>
            </div>
        }
    `
})
export class BackupAgendamentoPainel implements OnInit {
    private api = inject(BackupService);
    private notify = inject(NotifyService);

    formatosDisponiveis = input<string[]>([]);
    iniciado = output<BackupJob>();

    salvo = signal<AgendamentoBackup | null>(null);
    form = signal<AgendamentoBackup | null>(null);
    execucoes = signal<BackupJob[]>([]);
    sujo = signal(false);
    salvando = signal(false);
    executando = signal(false);
    novaHora: string[] = Array(7).fill('02:00');

    dias = DIAS_SEMANA;
    data = dataHora;
    cor = corStatus;
    rotuloStatus = ROTULO_STATUS;
    rotuloOrigem = ROTULO_ORIGEM;

    private horarios = signal<{ dia: number; hora: string }[]>([]);

    totalHorarios = computed(() => this.horarios().length);

    ngOnInit(): void {
        this.carregar();
    }

    carregar(): void {
        this.api.agendamento().subscribe({
            next: (a) => {
                this.salvo.set(a);
                this.form.set({ ...a, formatos: [...a.formatos] });
                this.horarios.set([...a.horarios]);
                this.sujo.set(false);
            },
            error: (e) => this.notify.erro(e)
        });
        this.api.historico(20, true).subscribe({ next: (h) => this.execucoes.set(h), error: () => undefined });
    }

    horasDoDia(dia: number): string[] {
        return this.horarios()
            .filter((h) => h.dia === dia)
            .map((h) => h.hora)
            .sort();
    }

    adicionar(dia: number): void {
        const hora = (this.novaHora[dia - 1] || '').slice(0, 5);
        if (!/^\d{2}:\d{2}$/.test(hora)) {
            this.notify.aviso('Informe o horário no formato HH:mm.');
            return;
        }
        if (this.horasDoDia(dia).includes(hora)) {
            return;
        }
        this.horarios.update((l) => [...l, { dia, hora }]);
        this.sujo.set(true);
    }

    remover(dia: number, hora: string): void {
        this.horarios.update((l) => l.filter((h) => !(h.dia === dia && h.hora === hora)));
        this.sujo.set(true);
    }

    todoDia(hora: string): void {
        this.horarios.set([1, 2, 3, 4, 5, 6, 7].map((dia) => ({ dia, hora })));
        this.sujo.set(true);
    }

    copiarSegunda(ate: number): void {
        const seg = this.horasDoDia(1);
        if (seg.length === 0) {
            this.notify.aviso('Inclua primeiro os horários de segunda-feira.');
            return;
        }
        const outros = this.horarios().filter((h) => h.dia > ate);
        const novos: { dia: number; hora: string }[] = [];
        for (let dia = 1; dia <= ate; dia++) {
            seg.forEach((hora) => novos.push({ dia, hora }));
        }
        this.horarios.set([...novos, ...outros]);
        this.sujo.set(true);
    }

    limpar(): void {
        this.horarios.set([]);
        this.sujo.set(true);
    }

    alternarFormato(f: string, marcado: boolean): void {
        const form = this.form();
        if (!form) {
            return;
        }
        form.formatos = marcado ? [...new Set([...form.formatos, f])] : form.formatos.filter((x) => x !== f);
        this.sujo.set(true);
    }

    salvar(): void {
        const f = this.form();
        if (!f) {
            return;
        }
        this.salvando.set(true);
        this.api.salvarAgendamento({ ...f, horarios: this.horarios() }).subscribe({
            next: (a) => {
                this.salvando.set(false);
                this.salvo.set(a);
                this.form.set({ ...a, formatos: [...a.formatos] });
                this.horarios.set([...a.horarios]);
                this.sujo.set(false);
                this.notify.sucesso(a.ativo ? 'Backup automático salvo e ligado.' : 'Configuração salva (backup automático desligado).');
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    executarAgora(): void {
        this.executando.set(true);
        this.api.executarAgora().subscribe({
            next: (j) => {
                this.executando.set(false);
                this.notify.info('Backup iniciado com a configuração do agendamento.');
                this.iniciado.emit(j);
                setTimeout(() => this.api.historico(20, true).subscribe({ next: (h) => this.execucoes.set(h), error: () => undefined }), 1500);
            },
            error: (e) => {
                this.executando.set(false);
                this.notify.erro(e);
            }
        });
    }
}
