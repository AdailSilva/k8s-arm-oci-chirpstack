import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { MultiSelectModule } from 'primeng/multiselect';
import { PasswordModule } from 'primeng/password';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { CsUser, CsUserListItem } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { dataHora } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';

/**
 * Usuários do próprio ChirpStack (login na interface web do ChirpStack). Somente ADMIN.
 */
@Component({
    selector: 'app-cs-user-list',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, DialogModule, InputTextModule, MultiSelectModule, PasswordModule, TableModule, TagModule, TextareaModule, ToggleSwitchModule, TooltipModule, PageHeader],
    template: `
        <app-page-header title="Usuários do ChirpStack" subtitle="Contas de acesso à interface do ChirpStack (independentes dos usuários deste painel)" icon="pi pi-users">
            <p-button label="Novo usuário" icon="pi pi-plus" (onClick)="novo()" />
        </app-page-header>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '50rem' }" [rowHover]="true">
                <ng-template #header>
                    <tr>
                        <th>E-mail</th>
                        <th>Situação</th>
                        <th>Administrador</th>
                        <th>Criado em</th>
                        <th class="w-40"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-u>
                    <tr>
                        <td class="font-medium">{{ u.email }}</td>
                        <td><p-tag [value]="u.isActive ? 'Ativo' : 'Inativo'" [severity]="u.isActive ? 'success' : 'secondary'" /></td>
                        <td>
                            @if (u.isAdmin) {
                                <p-tag value="Admin global" severity="danger" />
                            } @else {
                                <span class="text-surface-400">—</span>
                            }
                        </td>
                        <td>{{ data(u.createdAt) }}</td>
                        <td class="text-right">
                            <p-button icon="pi pi-key" [text]="true" [rounded]="true" pTooltip="Alterar senha" (onClick)="abrirSenha(u)" />
                            <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" (onClick)="editar(u)" />
                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(u)" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="5" class="text-center py-8 text-surface-500">Nenhum usuário.</td></tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogo" [header]="editandoId() ? 'Editar usuário' : 'Novo usuário do ChirpStack'" [modal]="true" [style]="{ width: '36rem' }" [breakpoints]="{ '768px': '95vw' }">
            <div class="flex flex-col gap-5">
                <div>
                    <label class="block font-medium mb-2">E-mail <span class="text-red-500">*</span></label>
                    <input pInputText type="email" class="w-full" [(ngModel)]="form.email" />
                </div>
                @if (!editandoId()) {
                    <div>
                        <label class="block font-medium mb-2">Senha <span class="text-red-500">*</span></label>
                        <p-password [(ngModel)]="senha" [toggleMask]="true" [feedback]="true" styleClass="w-full" inputStyleClass="w-full" appendTo="body" />
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Tenants</label>
                        <p-multiselect [options]="ctx.tenants()" optionLabel="name" optionValue="id" [(ngModel)]="tenantsSelecionados" placeholder="Vincular a tenants (opcional)" styleClass="w-full" appendTo="body" display="chip" />
                        <small class="text-surface-500">Vinculado como usuário comum. Ajuste as permissões depois na tela do tenant.</small>
                    </div>
                }
                <div>
                    <label class="block font-medium mb-2">Observação</label>
                    <textarea pTextarea class="w-full" rows="2" [(ngModel)]="form.note"></textarea>
                </div>
                <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.isActive" /> Ativo</label>
                <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.isAdmin" /> Administrador global do ChirpStack</label>
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" [disabled]="!form.email.trim() || (!editandoId() && senha.length < 6)" />
            </ng-template>
        </p-dialog>

        <p-dialog [(visible)]="dialogoSenha" header="Alterar senha" [modal]="true" [style]="{ width: '28rem' }">
            <p class="mt-0 text-surface-500">Nova senha para <b>{{ alvoSenha()?.email }}</b>.</p>
            <p-password [(ngModel)]="novaSenha" [toggleMask]="true" styleClass="w-full" inputStyleClass="w-full" appendTo="body" />
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogoSenha.set(false)" />
                <p-button label="Alterar" icon="pi pi-check" (onClick)="salvarSenha()" [disabled]="novaSenha.length < 6" />
            </ng-template>
        </p-dialog>
    `
})
export class CsUserList extends ListaPaginada<CsUserListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    ctx = inject(TenantContextService);

    dialogo = signal(false);
    dialogoSenha = signal(false);
    editandoId = signal<string | null>(null);
    alvoSenha = signal<CsUserListItem | null>(null);
    salvando = signal(false);
    form: CsUser = this.vazio();
    senha = '';
    novaSenha = '';
    tenantsSelecionados: string[] = [];
    data = dataHora;

    protected consultar(q: ConsultaPagina) {
        return this.api.listUsers({ limit: q.limit, offset: q.offset });
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    private vazio(): CsUser {
        return { email: '', isActive: true, isAdmin: false, note: '' };
    }

    novo(): void {
        this.form = this.vazio();
        this.senha = '';
        this.tenantsSelecionados = [];
        this.editandoId.set(null);
        this.dialogo.set(true);
    }

    editar(u: CsUserListItem): void {
        this.api.getUser(u.id).subscribe({
            next: (r) => {
                this.form = { ...this.vazio(), ...r.user };
                this.editandoId.set(u.id);
                this.dialogo.set(true);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    salvar(): void {
        const id = this.editandoId();
        this.salvando.set(true);
        const dados = { ...this.form, email: this.form.email.trim() };
        const op = id
            ? this.api.updateUser(id, dados)
            : this.api.createUser(dados, this.senha, this.tenantsSelecionados.map((tenantId) => ({ tenantId, isAdmin: false, isDeviceAdmin: false, isGatewayAdmin: false })));
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso(id ? 'Usuário atualizado.' : 'Usuário criado.');
                this.carregar();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    abrirSenha(u: CsUserListItem): void {
        this.alvoSenha.set(u);
        this.novaSenha = '';
        this.dialogoSenha.set(true);
    }

    salvarSenha(): void {
        const u = this.alvoSenha();
        if (!u) {
            return;
        }
        this.api.updateUserPassword(u.id, this.novaSenha).subscribe({
            next: () => {
                this.dialogoSenha.set(false);
                this.notify.sucesso('Senha alterada.');
            },
            error: (e) => this.notify.erro(e)
        });
    }

    excluir(u: CsUserListItem): void {
        this.notify.confirmarExclusao(`o usuário ${u.email}`, () =>
            this.api.deleteUser(u.id).subscribe({
                next: () => {
                    this.notify.sucesso('Usuário excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }
}
