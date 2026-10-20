import { Component, inject, input, model, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DatePickerModule } from 'primeng/datepicker';
import { DialogModule } from 'primeng/dialog';
import { MessageModule } from 'primeng/message';
import { RadioButtonModule } from 'primeng/radiobutton';
import { TextareaModule } from 'primeng/textarea';
import { VisitantesService } from '@/app/pages/visitantes/visitantes.service';
import { VisitanteUsuario } from '@/app/core/http/models';
import { NotifyService } from '@/app/core/notificacao/notify.service';

/**
 * Bloqueio de acesso de um usuário: temporário (até data e hora) ou permanente (desativa o usuário).
 * As sessões abertas dele caem na hora.
 */
@Component({
    selector: 'app-bloqueio-dialog',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, DatePickerModule, DialogModule, MessageModule, RadioButtonModule, TextareaModule],
    template: `
        <p-dialog [(visible)]="visivel" [modal]="true" [draggable]="false" [style]="{ width: '34rem' }" [breakpoints]="{ '640px': '95vw' }" (onShow)="preparar()">
            <ng-template #header>
                <div class="flex items-center gap-3">
                    <span class="w-10 h-10 rounded-xl bg-red-50 text-red-600 dark:bg-red-900/30 dark:text-red-300 flex items-center justify-center"><i class="pi pi-ban text-lg!"></i></span>
                    <div>
                        <div class="font-semibold text-lg">Bloquear acesso</div>
                        <div class="text-sm text-surface-500">{{ usuario()?.nome }} · {{ usuario()?.email }}</div>
                    </div>
                </div>
            </ng-template>
            <div class="flex flex-col gap-5">
                <div class="flex flex-col gap-3">
                    <label class="flex items-start gap-3 cursor-pointer">
                        <p-radiobutton name="tipo" value="TEMPORARIO" [(ngModel)]="tipo" />
                        <span><b>Temporário</b><br /><span class="text-sm text-surface-500">O login fica bloqueado até a data escolhida e volta sozinho depois.</span></span>
                    </label>
                    <label class="flex items-start gap-3 cursor-pointer">
                        <p-radiobutton name="tipo" value="PERMANENTE" [(ngModel)]="tipo" />
                        <span><b>Permanente</b><br /><span class="text-sm text-surface-500">Desativa o usuário. Para liberar, reative-o em Usuários do painel.</span></span>
                    </label>
                </div>
                @if (tipo === 'TEMPORARIO') {
                    <div>
                        <label class="block font-medium mb-2">Bloqueado até <span class="text-red-500">*</span></label>
                        <p-datepicker [(ngModel)]="ate" [showTime]="true" hourFormat="24" [minDate]="agora" dateFormat="dd/mm/yy" [showIcon]="true" appendTo="body" styleClass="w-full" inputStyleClass="w-full" />
                        <div class="flex flex-wrap gap-2 mt-2">
                            @for (o of atalhos; track o.rotulo) {
                                <p-button [label]="o.rotulo" size="small" severity="secondary" [outlined]="true" (onClick)="atalho(o.horas)" />
                            }
                        </div>
                    </div>
                }
                <div>
                    <label class="block font-medium mb-2">Motivo</label>
                    <textarea pTextarea class="w-full" rows="2" maxlength="255" [(ngModel)]="motivo" placeholder="Aparece para o usuário na tela de login"></textarea>
                </div>
                <p-message severity="warn" icon="pi pi-exclamation-triangle" text="As sessões abertas deste usuário serão encerradas imediatamente." styleClass="w-full" />
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [text]="true" (onClick)="visivel.set(false)" />
                <p-button [label]="tipo === 'PERMANENTE' ? 'Desativar usuário' : 'Bloquear'" icon="pi pi-ban" severity="danger" [loading]="salvando()" (onClick)="confirmar()" />
            </ng-template>
        </p-dialog>
    `
})
export class BloqueioDialog {
    private api = inject(VisitantesService);
    private notify = inject(NotifyService);

    visivel = model(false);
    usuario = input<VisitanteUsuario | null>(null);
    concluido = output<void>();

    tipo: 'TEMPORARIO' | 'PERMANENTE' = 'TEMPORARIO';
    ate: Date | null = null;
    motivo = '';
    agora = new Date();
    salvando = signal(false);
    atalhos = [
        { rotulo: '1 hora', horas: 1 },
        { rotulo: '24 horas', horas: 24 },
        { rotulo: '7 dias', horas: 24 * 7 },
        { rotulo: '30 dias', horas: 24 * 30 }
    ];

    preparar(): void {
        this.tipo = 'TEMPORARIO';
        this.agora = new Date();
        this.ate = new Date(Date.now() + 24 * 3600_000);
        this.motivo = '';
    }

    atalho(horas: number): void {
        this.ate = new Date(Date.now() + horas * 3600_000);
    }

    confirmar(): void {
        const u = this.usuario();
        if (!u) {
            return;
        }
        if (this.tipo === 'TEMPORARIO' && (!this.ate || this.ate.getTime() <= Date.now())) {
            this.notify.aviso('Escolha uma data de liberação no futuro.');
            return;
        }
        this.salvando.set(true);
        this.api.bloquear(u.usuarioId, this.tipo === 'PERMANENTE', this.tipo === 'TEMPORARIO' ? this.ate : null, this.motivo.trim()).subscribe({
            next: () => {
                this.salvando.set(false);
                this.visivel.set(false);
                this.notify.sucesso(this.tipo === 'PERMANENTE' ? `${u.nome} foi desativado.` : `Acesso de ${u.nome} bloqueado.`);
                this.concluido.emit();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }
}
