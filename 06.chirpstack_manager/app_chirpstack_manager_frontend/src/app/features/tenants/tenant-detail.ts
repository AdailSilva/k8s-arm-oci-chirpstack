import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { CheckboxModule } from 'primeng/checkbox';
import { DialogModule } from 'primeng/dialog';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { CsUserListItem, GetTenantResponse, TenantUser, TenantUserListItem } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora, num } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';

/**
 * Detalhe do tenant e os usuários do ChirpStack vinculados a ele.
 */
@Component({
    selector: 'app-tenant-detail',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, CheckboxModule, DialogModule, SelectModule, TableModule, TagModule, TooltipModule, PageHeader],
    template: `
        <app-page-header [title]="tenant()?.tenant?.name ?? 'Tenant'" [subtitle]="tenant()?.tenant?.description || 'Usuários com acesso a este tenant no ChirpStack'" icon="pi pi-building">
            <p-button label="Voltar" icon="pi pi-arrow-left" severity="secondary" [outlined]="true" routerLink="/tenants" />
            <p-button label="Adicionar usuário" icon="pi pi-user-plus" (onClick)="novo()" />
        </app-page-header>

        @if (tenant(); as t) {
            <div class="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
                <div class="card mb-0!"><div class="text-surface-500 text-sm">ID</div><div class="font-mono text-sm mt-1 break-all">{{ t.tenant.id }}</div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Pode ter gateways</div><div class="font-medium mt-1">{{ t.tenant.canHaveGateways ? 'Sim' : 'Não' }}</div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Máx. gateways</div><div class="font-medium mt-1">{{ limite(t.tenant.maxGatewayCount) }}</div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Máx. dispositivos</div><div class="font-medium mt-1">{{ limite(t.tenant.maxDeviceCount) }}</div></div>
                <div class="card mb-0!"><div class="text-surface-500 text-sm">Criado em</div><div class="font-medium mt-1">{{ data(t.createdAt) }}</div></div>
            </div>
        }

        <div class="card">
            <div class="font-semibold text-lg mb-4">Usuários do tenant</div>
            <p-table [value]="itens()" [lazy]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [tableStyle]="{ 'min-width': '50rem' }" [rowHover]="true">
                <ng-template #header>
                    <tr>
                        <th>E-mail</th>
                        <th>Permissões</th>
                        <th>Adicionado em</th>
                        <th class="w-32"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-u>
                    <tr>
                        <td class="font-medium">{{ u.email }}</td>
                        <td>
                            @if (u.isAdmin) {
                                <p-tag value="Admin do tenant" severity="danger" class="mr-1" />
                            } @else {
                                @if (u.isGatewayAdmin) {
                                    <p-tag value="Admin de gateways" severity="warn" class="mr-1" />
                                }
                                @if (u.isDeviceAdmin) {
                                    <p-tag value="Admin de dispositivos" severity="info" class="mr-1" />
                                }
                                @if (!u.isGatewayAdmin && !u.isDeviceAdmin) {
                                    <p-tag value="Somente leitura" severity="secondary" />
                                }
                            }
                        </td>
                        <td>{{ data(u.createdAt) }}</td>
                        <td class="text-right">
                            <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar permissões" (onClick)="editar(u)" />
                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Remover do tenant" (onClick)="remover(u)" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="4" class="text-center py-8 text-surface-500">Nenhum usuário vinculado.</td></tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogo" [header]="editando() ? 'Permissões do usuário' : 'Adicionar usuário ao tenant'" [modal]="true" [style]="{ width: '34rem' }" [breakpoints]="{ '768px': '95vw' }">
            <div class="flex flex-col gap-5">
                @if (!editando()) {
                    <div>
                        <label class="block font-medium mb-2">Usuário do ChirpStack <span class="text-red-500">*</span></label>
                        <p-select [options]="usuarios()" optionLabel="email" optionValue="id" [(ngModel)]="form.userId" [filter]="true" filterBy="email" placeholder="Selecione" styleClass="w-full" appendTo="body" (onChange)="aoEscolher()" />
                        <small class="text-surface-500">O usuário precisa existir em "Usuários do ChirpStack".</small>
                    </div>
                } @else {
                    <div><span class="text-surface-500">Usuário:</span> <b>{{ form.email }}</b></div>
                }
                <label class="flex items-center gap-3"><p-checkbox [(ngModel)]="form.isAdmin" [binary]="true" /> Administrador do tenant (acesso total ao tenant)</label>
                <label class="flex items-center gap-3"><p-checkbox [(ngModel)]="form.isGatewayAdmin" [binary]="true" [disabled]="form.isAdmin" /> Administrador de gateways</label>
                <label class="flex items-center gap-3"><p-checkbox [(ngModel)]="form.isDeviceAdmin" [binary]="true" [disabled]="form.isAdmin" /> Administrador de dispositivos</label>
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" [disabled]="!form.userId" />
            </ng-template>
        </p-dialog>
    `
})
export class TenantDetail extends ListaPaginada<TenantUserListItem> implements OnInit {
    id = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);

    tenant = signal<GetTenantResponse | null>(null);
    usuarios = signal<CsUserListItem[]>([]);
    dialogo = signal(false);
    editando = signal(false);
    salvando = signal(false);
    form: TenantUser = this.vazio();
    data = dataHora;

    ngOnInit(): void {
        this.api.getTenant(this.id()).subscribe({ next: (t) => this.tenant.set(t), error: (e) => this.notify.erro(e) });
    }

    protected consultar(q: ConsultaPagina) {
        return this.api.listTenantUsers(this.id(), { limit: q.limit, offset: q.offset });
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e);
    }

    limite(v: string | number): string {
        return num(v) === 0 ? 'Sem limite' : String(num(v));
    }

    private vazio(): TenantUser {
        return { userId: '', email: '', isAdmin: false, isDeviceAdmin: false, isGatewayAdmin: false };
    }

    novo(): void {
        this.form = this.vazio();
        this.editando.set(false);
        this.api.listUsers({ limit: 1000 }).subscribe({
            next: (r) => {
                this.usuarios.set(r.result);
                this.dialogo.set(true);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    aoEscolher(): void {
        this.form.email = this.usuarios().find((u) => u.id === this.form.userId)?.email ?? '';
    }

    editar(u: TenantUserListItem): void {
        this.form = { userId: u.userId, email: u.email, isAdmin: u.isAdmin, isDeviceAdmin: u.isDeviceAdmin, isGatewayAdmin: u.isGatewayAdmin };
        this.editando.set(true);
        this.dialogo.set(true);
    }

    salvar(): void {
        this.salvando.set(true);
        const op = this.editando() ? this.api.updateTenantUser(this.id(), this.form.userId, this.form) : this.api.addTenantUser(this.id(), this.form);
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso(this.editando() ? 'Permissões atualizadas.' : 'Usuário adicionado ao tenant.');
                this.carregar();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    remover(u: TenantUserListItem): void {
        this.notify.confirmar('Remover usuário', `Remover ${u.email} deste tenant? O usuário continua existindo no ChirpStack.`, () =>
            this.api.deleteTenantUser(this.id(), u.userId).subscribe({
                next: () => {
                    this.notify.sucesso('Usuário removido do tenant.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            }), 'Remover');
    }
}
