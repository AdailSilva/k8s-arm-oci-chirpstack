import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { TooltipModule } from 'primeng/tooltip';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { Tenant, TenantListItem } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { dataHora, num } from '@/app/core/util/format';
import { ConsultaPagina, ListaPaginada } from '@/app/shared/lista-paginada';
import { PageHeader } from '@/app/shared/page-header';
import { TagsEditor } from '@/app/shared/tags-editor';

export function novoTenant(): Tenant {
    return { name: '', description: '', canHaveGateways: true, maxGatewayCount: 0, maxDeviceCount: 0, privateGatewaysUp: false, privateGatewaysDown: false, tags: {}, devAddrPrefixes: [] };
}

/**
 * Tenants do ChirpStack (somente ADMIN).
 */
@Component({
    selector: 'app-tenant-list',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, IconFieldModule, InputIconModule, InputNumberModule, InputTextModule, TableModule, TagModule, TextareaModule, ToggleSwitchModule, TooltipModule, PageHeader, TagsEditor],
    template: `
        <app-page-header title="Tenants" subtitle="Organizações isoladas do ChirpStack: cada uma tem seus gateways, aplicações e perfis" icon="pi pi-building">
            <p-button label="Novo tenant" icon="pi pi-plus" (onClick)="novo()" />
        </app-page-header>

        <div class="card">
            <p-table [value]="itens()" [lazy]="true" [lazyLoadOnInit]="true" (onLazyLoad)="onLazy($event)" [paginator]="true" [rows]="rows()" [first]="first()" [totalRecords]="total()" [loading]="carregando()" [rowsPerPageOptions]="[10, 20, 50]" [showCurrentPageReport]="true" currentPageReportTemplate="{first}–{last} de {totalRecords}" [tableStyle]="{ 'min-width': '60rem' }" [rowHover]="true">
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
                        <th>Gateways</th>
                        <th>Gateways privados</th>
                        <th>Máx. gateways</th>
                        <th>Máx. dispositivos</th>
                        <th>Criado em</th>
                        <th class="w-40"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-t>
                    <tr>
                        <td>
                            <a [routerLink]="['/tenants', t.id]" class="font-medium text-primary hover:underline">{{ t.name }}</a>
                            @if (t.id === ctx.tenantId()) {
                                <p-tag value="selecionado" severity="info" class="ml-2" />
                            }
                        </td>
                        <td><i [class]="t.canHaveGateways ? 'pi pi-check text-green-500' : 'pi pi-times text-surface-400'"></i></td>
                        <td>
                            @if (t.privateGatewaysUp) {
                                <p-tag value="uplink" severity="secondary" class="mr-1" />
                            }
                            @if (t.privateGatewaysDown) {
                                <p-tag value="downlink" severity="secondary" />
                            }
                        </td>
                        <td>{{ limite(t.maxGatewayCount) }}</td>
                        <td>{{ limite(t.maxDeviceCount) }}</td>
                        <td>{{ data(t.createdAt) }}</td>
                        <td class="text-right">
                            <p-button icon="pi pi-users" [text]="true" [rounded]="true" pTooltip="Usuários" [routerLink]="['/tenants', t.id]" />
                            <p-button icon="pi pi-pencil" [text]="true" [rounded]="true" pTooltip="Editar" (onClick)="editar(t)" />
                            <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" pTooltip="Excluir" (onClick)="excluir(t)" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="7" class="text-center py-8 text-surface-500">Nenhum tenant encontrado.</td></tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogo" [header]="editandoId() ? 'Editar tenant' : 'Novo tenant'" [modal]="true" [style]="{ width: '44rem' }" [breakpoints]="{ '768px': '95vw' }">
            <div class="flex flex-col gap-5">
                <div>
                    <label class="block font-medium mb-2" for="tn">Nome <span class="text-red-500">*</span></label>
                    <input pInputText id="tn" class="w-full" [(ngModel)]="form.name" maxlength="100" />
                </div>
                <div>
                    <label class="block font-medium mb-2" for="td">Descrição</label>
                    <textarea pTextarea id="td" class="w-full" rows="3" [(ngModel)]="form.description"></textarea>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block font-medium mb-2">Máximo de gateways</label>
                        <p-inputnumber [(ngModel)]="form.maxGatewayCount" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                        <small class="text-surface-500">0 = sem limite</small>
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Máximo de dispositivos</label>
                        <p-inputnumber [(ngModel)]="form.maxDeviceCount" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                        <small class="text-surface-500">0 = sem limite</small>
                    </div>
                </div>
                <div class="flex flex-col gap-3">
                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.canHaveGateways" /> Pode ter gateways</label>
                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.privateGatewaysUp" /> Gateways privados (uplink): outros tenants não recebem uplinks destes gateways</label>
                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.privateGatewaysDown" /> Gateways privados (downlink): outros tenants não usam estes gateways para downlink</label>
                </div>
                <div>
                    <label class="block font-medium mb-2" for="tpfx">Prefixos de DevAddr</label>
                    <div class="flex gap-2">
                        <input pInputText id="tpfx" class="flex-1 font-mono" placeholder="ex.: 0000ff00/24" [(ngModel)]="novoPrefixo" (keydown.enter)="adicionarPrefixo()" maxlength="11" />
                        <p-button icon="pi pi-plus" label="Adicionar" [outlined]="true" (onClick)="adicionarPrefixo()" [disabled]="!novoPrefixo.trim()" />
                    </div>
                    <small class="text-surface-500">DevAddr em hexadecimal + tamanho do prefixo em bits. Sem prefixos, o tenant usa os prefixos da rede (NetID). Cada prefixo é verificado contra os dos outros tenants.</small>
                    @if (prefixos().length) {
                        <div class="flex flex-col gap-2 mt-3">
                            @for (p of prefixos(); track p) {
                                <div class="flex items-center gap-2 flex-wrap">
                                    <p-tag [value]="p" severity="secondary" styleClass="font-mono" />
                                    @if (sobreposicoes()[p]; as outros) {
                                        @if (outros.length) {
                                            <p-tag severity="warn" icon="pi pi-exclamation-triangle" [value]="'sobrepõe: ' + outros.join(', ')" />
                                        } @else {
                                            <p-tag severity="success" icon="pi pi-check" value="sem sobreposição" />
                                        }
                                    }
                                    <p-button icon="pi pi-times" severity="danger" [text]="true" [rounded]="true" size="small" pTooltip="Remover" (onClick)="removerPrefixo(p)" />
                                </div>
                            }
                        </div>
                    }
                </div>
                <app-tags-editor label="Tags" [(value)]="form.tags" />
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" [disabled]="!form.name.trim()" />
            </ng-template>
        </p-dialog>
    `
})
export class TenantList extends ListaPaginada<TenantListItem> {
    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    ctx = inject(TenantContextService);

    dialogo = signal(false);
    form: Tenant = novoTenant();
    editandoId = signal<string | null>(null);
    salvando = signal(false);
    data = dataHora;

    /** Prefixos de DevAddr do formulário (4.19+) e tenants que se sobrepõem a cada um. */
    prefixos = signal<string[]>([]);
    sobreposicoes = signal<Record<string, string[]>>({});
    novoPrefixo = '';

    protected consultar(q: ConsultaPagina) {
        return this.api.listTenants(q);
    }

    protected override aoFalhar(e: unknown): void {
        this.notify.erro(e, 'Falha ao listar tenants');
    }

    limite(v: string | number): string {
        return num(v) === 0 ? 'Sem limite' : String(num(v));
    }

    novo(): void {
        this.form = novoTenant();
        this.editandoId.set(null);
        this.definirPrefixos([]);
        this.dialogo.set(true);
    }

    editar(t: TenantListItem): void {
        this.api.getTenant(t.id).subscribe({
            next: (r) => {
                this.form = { ...novoTenant(), ...r.tenant, maxGatewayCount: num(r.tenant.maxGatewayCount), maxDeviceCount: num(r.tenant.maxDeviceCount), tags: { ...(r.tenant.tags ?? {}) } };
                this.editandoId.set(t.id);
                this.definirPrefixos(r.tenant.devAddrPrefixes ?? []);
                this.dialogo.set(true);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    salvar(): void {
        const id = this.editandoId();
        const dados: Tenant = { ...this.form, name: this.form.name.trim(), maxGatewayCount: num(this.form.maxGatewayCount), maxDeviceCount: num(this.form.maxDeviceCount), devAddrPrefixes: this.prefixos() };
        this.salvando.set(true);
        const op = id ? this.api.updateTenant(id, dados) : this.api.createTenant(dados);
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso(id ? 'Tenant atualizado.' : 'Tenant criado.');
                this.carregar();
                this.ctx.carregar();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    private definirPrefixos(lista: string[]): void {
        this.prefixos.set([...lista]);
        this.sobreposicoes.set({});
        this.novoPrefixo = '';
        lista.forEach((p) => this.verificarSobreposicao(p));
    }

    adicionarPrefixo(): void {
        const p = this.novoPrefixo.trim().toLowerCase();
        const m = /^([0-9a-f]{8})\/(\d{1,2})$/.exec(p);
        if (!m || Number(m[2]) > 32) {
            this.notify.aviso('Prefixo inválido. Use 8 dígitos hexadecimais, barra e o tamanho em bits (0 a 32), ex.: 0000ff00/24.');
            return;
        }
        if (this.prefixos().includes(p)) {
            this.notify.aviso('Prefixo já adicionado.');
            return;
        }
        this.prefixos.update((l) => [...l, p]);
        this.novoPrefixo = '';
        this.verificarSobreposicao(p);
    }

    removerPrefixo(p: string): void {
        this.prefixos.update((l) => l.filter((x) => x !== p));
    }

    private verificarSobreposicao(p: string): void {
        this.api.listTenantsByDevAddrPrefixOverlap(p).subscribe({
            next: (r) => {
                const outros = (r.result ?? []).filter((t) => t.id !== this.editandoId()).map((t) => t.name);
                this.sobreposicoes.update((m) => ({ ...m, [p]: outros }));
            },
            // Sem a verificação (ex.: ChirpStack anterior à 4.19) o prefixo segue sem indicador.
            error: () => undefined
        });
    }

    excluir(t: TenantListItem): void {
        this.notify.confirmarExclusao(`o tenant "${t.name}"`, () =>
            this.api.deleteTenant(t.id).subscribe({
                next: () => {
                    this.notify.sucesso('Tenant excluído.');
                    this.carregar();
                    this.ctx.carregar();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Todas as aplicações, dispositivos e gateways do tenant também serão removidos.'
        );
    }
}
