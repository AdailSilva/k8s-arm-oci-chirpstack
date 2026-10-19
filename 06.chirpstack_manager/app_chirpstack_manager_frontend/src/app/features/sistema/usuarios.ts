import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { TooltipModule } from 'primeng/tooltip';
import { map } from 'rxjs';
import { SistemaService, UsuarioSistemaForm } from '@/app/core/api/sistema.service';
import { UsuarioSistema } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora, tempoRelativo } from '@/app/core/util/format';
import { PERFIS_ACESSO, rotulo } from '@/app/core/util/options';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';

const SENHA = /^(?=.*[A-Za-z])(?=.*\d).{8,72}$/;

/**
 * Usuários do painel (ChirpStack Manager). Somente ADMIN.
 */
@Component({
    selector: 'app-usuarios',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, DialogModule, IconFieldModule, InputIconModule, InputTextModule, PasswordModule, SelectModule, TableModule, TagModule, ToggleSwitchModule, TooltipModule, PageHeader],
    template: `
        <app-page-header title="Usuários do painel" subtitle="Quem acessa o ChirpStack Manager e com qual perfil" icon="pi pi-user-edit">
            <p-button label="Novo usuário" icon="pi pi-plus" (onClick)="novo()" />
        </app-page-header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div class="card mb-0! flex gap-3 items-start"><i class="pi pi-shield text-red-500 text-xl! mt-1"></i><div><b>Administrador</b><div class="text-sm text-surface-500">Tudo, inclusive tenants, usuários do ChirpStack, usuários do painel e auditoria.</div></div></div>
            <div class="card mb-0! flex gap-3 items-start"><i class="pi pi-wrench text-amber-500 text-xl! mt-1"></i><div><b>Operador</b><div class="text-sm text-surface-500">Cria, altera e exclui aplicações, dispositivos, gateways, perfis, multicast e integrações.</div></div></div>
            <div class="card mb-0! flex gap-3 items-start"><i class="pi pi-eye text-sky-500 text-xl! mt-1"></i><div><b>Visualizador</b><div class="text-sm text-surface-500">Somente leitura, sem acesso a chaves, sessões e segredos.</div></div></div>
        </div>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [tableStyle]="{ 'min-width': '60rem' }" [rowHover]="true">
                <ng-template #caption>
                    <div class="flex justify-end">
                        <p-iconfield>
                            <p-inputicon class="pi pi-search" />
                            <input pInputText type="text" placeholder="Nome ou e-mail" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" />
                        </p-iconfield>
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>Nome</th>
                        <th>E-mail</th>
                        <th>Perfil</th>
                        <th>Situação</th>
                        <th>Último acesso</th>
                        <th class="w-36"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-u>
                    <tr>
                        <td class="font-medium">
                            {{ u.nome }}
                            @if (u.email === auth.usuario()?.email) {
                                <p-tag value="você" severity="info" class="ml-1" />
                            }
                        </td>
                        <td>{{ u.email }}</td>
                        <td><p-tag [value]="perfil(u.perfil)" [severity]="u.perfil === 'ADMIN' ? 'danger' : u.perfil === 'OPERADOR' ? 'warn' : 'info'" /></td>
                        <td>
                            @if (u.bloqueado) {
                                <p-tag value="Bloqueado" severity="danger" icon="pi pi-lock" />
                            } @else {
                                <p-tag [value]="u.ativo ? 'Ativo' : 'Inativo'" [severity]="u.ativo ? 'success' : 'secondary'" />
                            }
                        </td>
                        <td [title]="data(u.ultimoLogin)">{{ relativo(u.ultimoLogin) }}</td>
                        <td class="text-right">
                            @if (u.bloqueado) {
                                <p-button icon="pi pi-lock-open" [text]="true" [rounded]="true" pTooltip="Desbloquear" (onClick)="desbloquear(u)" />
                            }
                            <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" (onClick)="editar(u)" />
                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(u)" [disabled]="u.email === auth.usuario()?.email" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="6" class="text-center py-8 text-surface-500">Nenhum usuário.</td></tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogo" [header]="editando() ? 'Editar usuário' : 'Novo usuário'" [modal]="true" [style]="{ width: '34rem' }" [breakpoints]="{ '768px': '95vw' }">
            <div class="flex flex-col gap-5">
                <div>
                    <label class="block font-medium mb-2">Nome <span class="text-red-500">*</span></label>
                    <input pInputText class="w-full" [(ngModel)]="form.nome" maxlength="120" />
                </div>
                <div>
                    <label class="block font-medium mb-2">E-mail <span class="text-red-500">*</span></label>
                    <input pInputText type="email" class="w-full" [(ngModel)]="form.email" maxlength="160" />
                </div>
                <div>
                    <label class="block font-medium mb-2">Perfil</label>
                    <p-select [options]="perfis" optionLabel="label" optionValue="value" [(ngModel)]="form.perfil" styleClass="w-full" appendTo="body" />
                </div>
                <div>
                    <label class="block font-medium mb-2">{{ editando() ? 'Redefinir senha (opcional)' : 'Senha' }} @if (!editando()) {<span class="text-red-500">*</span>}</label>
                    <p-password [(ngModel)]="senha" [toggleMask]="true" [feedback]="true" styleClass="w-full" inputStyleClass="w-full" appendTo="body" autocomplete="new-password" />
                    <small class="text-surface-500">De 8 a 72 caracteres, com letras e números.</small>
                </div>
                <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.ativo" /> Ativo</label>
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
            </ng-template>
        </p-dialog>
    `
})
export class Usuarios extends ListaPaginada<UsuarioSistema> {
    private api = inject(SistemaService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);

    perfis = PERFIS_ACESSO;
    dialogo = signal(false);
    editando = signal<UsuarioSistema | null>(null);
    salvando = signal(false);
    form: UsuarioSistemaForm = { nome: '', email: '', perfil: 'VISUALIZADOR', ativo: true };
    senha = '';
    data = dataHora;
    relativo = tempoRelativo;

    protected consultar(q: ConsultaPagina) {
        return this.api.listarUsuarios(q.search, Math.floor(q.offset / q.limit), q.limit).pipe(map((r) => r));
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    perfil(p: string): string {
        return rotulo(PERFIS_ACESSO, p);
    }

    novo(): void {
        this.form = { nome: '', email: '', perfil: 'VISUALIZADOR', ativo: true };
        this.senha = '';
        this.editando.set(null);
        this.dialogo.set(true);
    }

    editar(u: UsuarioSistema): void {
        this.form = { nome: u.nome, email: u.email, perfil: u.perfil, ativo: u.ativo };
        this.senha = '';
        this.editando.set(u);
        this.dialogo.set(true);
    }

    salvar(): void {
        const u = this.editando();
        if (!this.form.nome.trim() || !this.form.email.trim()) {
            this.notify.aviso('Informe o nome e o e-mail.');
            return;
        }
        if ((!u || this.senha) && !SENHA.test(this.senha)) {
            this.notify.aviso('A senha deve ter de 8 a 72 caracteres, com letras e números.');
            return;
        }
        this.salvando.set(true);
        const op = u ? this.api.atualizarUsuario(u.id, { ...this.form, novaSenha: this.senha || undefined }) : this.api.criarUsuario({ ...this.form, senha: this.senha });
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso(u ? 'Usuário atualizado.' : 'Usuário criado.');
                this.carregar();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    desbloquear(u: UsuarioSistema): void {
        this.api.desbloquearUsuario(u.id).subscribe({
            next: () => {
                this.notify.sucesso('Usuário desbloqueado.');
                this.carregar();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    excluir(u: UsuarioSistema): void {
        this.notify.confirmarExclusao(`o usuário ${u.email}`, () =>
            this.api.excluirUsuario(u.id).subscribe({
                next: () => {
                    this.notify.sucesso('Usuário excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
