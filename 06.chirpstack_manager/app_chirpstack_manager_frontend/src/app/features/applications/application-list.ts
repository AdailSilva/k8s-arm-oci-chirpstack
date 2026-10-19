import { Component, effect, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { TableModule } from 'primeng/table';
import { TextareaModule } from 'primeng/textarea';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { Application, ApplicationListItem } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { dataHora } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';
import { TagsEditor } from '@/app/shared/tags-editor';

/**
 * Aplicações do tenant selecionado.
 */
@Component({
    selector: 'app-application-list',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, IconFieldModule, InputIconModule, InputTextModule, TableModule, TextareaModule, TooltipModule, PageHeader, TagsEditor],
    template: `
        <app-page-header title="Aplicações" [subtitle]="'Agrupam dispositivos e integrações · ' + (ctx.tenant()?.name ?? 'sem tenant')" icon="pi pi-th-large">
            @if (auth.podeEscrever()) {
                <p-button label="Nova aplicação" icon="pi pi-plus" (onClick)="novo()" [disabled]="!ctx.tenantId()" />
            }
        </app-page-header>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" [lazyLoadOnInit]="false" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '50rem' }" [rowHover]="true">
                <ng-template #caption>
                    <div class="flex justify-end">
                        <p-iconfield>
                            <p-inputicon class="pi pi-search" />
                            <input pInputText type="text" placeholder="Pesquisar por nome" [ngModel]="busca()" (ngModelChange)="pesquisar($event)" />
                        </p-iconfield>
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>Nome</th>
                        <th>Descrição</th>
                        <th>Criada em</th>
                        <th>Atualizada em</th>
                        <th class="w-32"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-a>
                    <tr>
                        <td><a [routerLink]="['/aplicacoes', a.id]" class="font-medium text-primary hover:underline">{{ a.name }}</a></td>
                        <td class="text-surface-500 max-w-md truncate">{{ a.description || '—' }}</td>
                        <td>{{ data(a.createdAt) }}</td>
                        <td>{{ data(a.updatedAt) }}</td>
                        <td class="text-right">
                            <p-button icon="pi pi-eye" [text]="true" [rounded]="true" pTooltip="Abrir" [routerLink]="['/aplicacoes', a.id]" />
                            @if (auth.podeEscrever()) {
                                <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(a)" />
                            }
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="5" class="text-center py-8 text-surface-500">{{ ctx.tenantId() ? 'Nenhuma aplicação neste tenant.' : 'Selecione um tenant no topo da tela.' }}</td></tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogo" header="Nova aplicação" [modal]="true" [style]="{ width: '40rem' }" [breakpoints]="{ '768px': '95vw' }">
            <div class="flex flex-col gap-5">
                <div>
                    <label class="block font-medium mb-2">Nome <span class="text-red-500">*</span></label>
                    <input pInputText class="w-full" [(ngModel)]="form.name" maxlength="100" />
                </div>
                <div>
                    <label class="block font-medium mb-2">Descrição</label>
                    <textarea pTextarea class="w-full" rows="3" [(ngModel)]="form.description"></textarea>
                </div>
                <app-tags-editor label="Tags" [(value)]="form.tags" />
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Criar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" [disabled]="!form.name.trim()" />
            </ng-template>
        </p-dialog>
    `
})
export class ApplicationList extends ListaPaginada<ApplicationListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    ctx = inject(TenantContextService);
    auth = inject(AuthService);

    dialogo = signal(false);
    salvando = signal(false);
    form: Application = { name: '', description: '', tenantId: '', tags: {} };
    data = dataHora;

    constructor() {
        super();
        effect(() => {
            this.ctx.tenantId();
            this.recarregarDoInicio();
        });
    }

    protected consultar(q: ConsultaPagina) {
        const tenantId = this.ctx.tenantId();
        return tenantId ? this.api.listApplications({ ...q, tenantId }) : null;
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e, 'Falha ao listar aplicações');
    }

    novo(): void {
        this.form = { name: '', description: '', tenantId: this.ctx.tenantId() ?? '', tags: {} };
        this.dialogo.set(true);
    }

    salvar(): void {
        this.salvando.set(true);
        this.api.createApplication({ ...this.form, name: this.form.name.trim() }).subscribe({
            next: (r) => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso('Aplicação criada.');
                this.router.navigate(['/aplicacoes', r.id]);
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    excluir(a: ApplicationListItem): void {
        this.notify.confirmarExclusao(`a aplicação "${a.name}"`, () =>
            this.api.deleteApplication(a.id).subscribe({
                next: () => {
                    this.notify.sucesso('Aplicação excluída.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Todos os dispositivos e grupos multicast da aplicação também serão excluídos.'
        );
    }
}
