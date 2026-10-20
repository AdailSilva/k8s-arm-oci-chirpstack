import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { TagModule } from 'primeng/tag';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora } from '@/app/core/format/format';
import { PERFIS_ACESSO, rotulo } from '@/app/core/format/options';
import { PageHeader } from '@/app/shared/visual/page-header';

const SENHA = /^(?=.*[A-Za-z])(?=.*\d).{8,72}$/;

/**
 * Dados do próprio usuário e troca de senha.
 */
@Component({
    selector: 'app-meu-perfil',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, InputTextModule, PasswordModule, TagModule, PageHeader],
    template: `
        <app-page-header title="Meu perfil" subtitle="Seus dados de acesso ao ChirpStack Manager" icon="pi pi-user" />

        <div class="grid grid-cols-12 gap-6">
            <div class="col-span-12 lg:col-span-6">
                <div class="card mb-0! flex flex-col gap-5">
                    <div class="font-semibold text-lg">Dados</div>
                    <div>
                        <label class="block font-medium mb-2">Nome</label>
                        <input pInputText class="w-full" [(ngModel)]="nome" maxlength="120" />
                    </div>
                    <div>
                        <label class="block font-medium mb-2">E-mail</label>
                        <input pInputText class="w-full" [value]="auth.usuario()?.email ?? ''" disabled />
                    </div>
                    <div class="flex gap-6 text-sm">
                        <div><span class="text-surface-500">Perfil:</span> <p-tag [value]="perfil()" class="ml-1" /></div>
                        <div><span class="text-surface-500">Último acesso:</span> {{ data(auth.usuario()?.ultimoLogin) }}</div>
                    </div>
                    <div><p-button label="Salvar nome" icon="pi pi-check" (onClick)="salvarNome()" [disabled]="!nome.trim()" /></div>
                </div>
            </div>
            <div class="col-span-12 lg:col-span-6">
                <div class="card mb-0! flex flex-col gap-5">
                    <div class="font-semibold text-lg">Alterar senha</div>
                    <div>
                        <label class="block font-medium mb-2">Senha atual</label>
                        <p-password [(ngModel)]="senhaAtual" [feedback]="false" [toggleMask]="true" styleClass="w-full" inputStyleClass="w-full" autocomplete="current-password" />
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Nova senha</label>
                        <p-password [(ngModel)]="novaSenha" [toggleMask]="true" styleClass="w-full" inputStyleClass="w-full" autocomplete="new-password" />
                        <small class="text-surface-500">De 8 a 72 caracteres, com letras e números.</small>
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Confirmar nova senha</label>
                        <p-password [(ngModel)]="confirmacao" [feedback]="false" [toggleMask]="true" styleClass="w-full" inputStyleClass="w-full" autocomplete="new-password" />
                    </div>
                    <div><p-button label="Alterar senha" icon="pi pi-key" (onClick)="trocarSenha()" [loading]="salvando()" /></div>
                    <small class="text-surface-500">Ao trocar a senha, as outras sessões abertas são encerradas e você precisará entrar de novo.</small>
                </div>
            </div>
        </div>
    `
})
export class MeuPerfil implements OnInit {
    auth = inject(AuthService);
    private notify = inject(NotifyService);

    nome = '';
    senhaAtual = '';
    novaSenha = '';
    confirmacao = '';
    salvando = signal(false);
    data = dataHora;

    ngOnInit(): void {
        this.nome = this.auth.usuario()?.nome ?? '';
        this.auth.me().subscribe({ next: (u) => (this.nome = u.nome) });
    }

    perfil(): string {
        return rotulo(PERFIS_ACESSO, this.auth.perfil());
    }

    salvarNome(): void {
        this.auth.atualizarNome(this.nome.trim()).subscribe({
            next: () => this.notify.sucesso('Nome atualizado.'),
            error: (e) => this.notify.erro(e)
        });
    }

    trocarSenha(): void {
        if (!SENHA.test(this.novaSenha)) {
            this.notify.aviso('A nova senha deve ter de 8 a 72 caracteres, com letras e números.');
            return;
        }
        if (this.novaSenha !== this.confirmacao) {
            this.notify.aviso('A confirmação não confere.');
            return;
        }
        this.salvando.set(true);
        this.auth.trocarSenha(this.senhaAtual, this.novaSenha).subscribe({
            next: () => {
                this.salvando.set(false);
                this.notify.sucesso('Senha alterada. Entre novamente.');
                this.auth.sessaoEncerrada('SENHA_ALTERADA');
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }
}
