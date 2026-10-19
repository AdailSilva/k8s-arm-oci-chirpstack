import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TabsModule } from 'primeng/tabs';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { Application, GetApplicationResponse } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora } from '@/app/core/util/format';
import { PageHeader } from '@/app/shared/page-header';
import { TagsEditor } from '@/app/shared/tags-editor';
import { CopyButton } from '@/app/shared/copy-button';
import { DeviceTable } from '@/app/features/devices/device-table';
import { MulticastTable } from '@/app/features/multicast/multicast-table';
import { IntegrationsPanel } from './integrations-panel';
import { RelaysPanel } from './relays-panel';

/**
 * Aplicação: dispositivos, grupos multicast, relays, integrações e configuração.
 */
@Component({
    selector: 'app-application-detail',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, InputTextModule, TabsModule, TagModule, TextareaModule, PageHeader, TagsEditor, CopyButton, DeviceTable, MulticastTable, IntegrationsPanel, RelaysPanel],
    template: `
        <app-page-header [title]="app()?.application?.name ?? 'Aplicação'" [subtitle]="app()?.application?.description || 'Aplicação'" icon="pi pi-th-large">
            <p-button label="Aplicações" icon="pi pi-arrow-left" severity="secondary" [outlined]="true" routerLink="/aplicacoes" />
            @if (auth.podeEscrever()) {
                <p-button label="Editar" icon="pi pi-pencil" severity="secondary" (onClick)="editar()" />
                <p-button label="Excluir" icon="pi pi-trash" severity="danger" [outlined]="true" (onClick)="excluir()" />
            }
        </app-page-header>

        <div class="card">
            <p-tabs [value]="aba()" (valueChange)="trocarAba($event)">
                <p-tablist>
                    <p-tab value="dispositivos"><i class="pi pi-microchip mr-2"></i>Dispositivos</p-tab>
                    <p-tab value="multicast"><i class="pi pi-sitemap mr-2"></i>Grupos multicast</p-tab>
                    <p-tab value="relays"><i class="pi pi-share-alt mr-2"></i>Relays</p-tab>
                    <p-tab value="integracoes"><i class="pi pi-link mr-2"></i>Integrações</p-tab>
                    <p-tab value="configuracao"><i class="pi pi-info-circle mr-2"></i>Detalhes</p-tab>
                </p-tablist>
                <p-tabpanels>
                    <p-tabpanel value="dispositivos">
                        @if (aba() === 'dispositivos') {
                            <app-device-table [applicationId]="id()" />
                        }
                    </p-tabpanel>
                    <p-tabpanel value="multicast">
                        @if (aba() === 'multicast') {
                            <app-multicast-table [applicationId]="id()" />
                        }
                    </p-tabpanel>
                    <p-tabpanel value="relays">
                        @if (aba() === 'relays') {
                            <app-relays-panel [applicationId]="id()" />
                        }
                    </p-tabpanel>
                    <p-tabpanel value="integracoes">
                        @if (aba() === 'integracoes') {
                            <app-integrations-panel [applicationId]="id()" />
                        }
                    </p-tabpanel>
                    <p-tabpanel value="configuracao">
                        @if (app(); as a) {
                            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                <div class="flex flex-col gap-4">
                                    <div><div class="text-surface-500 text-sm">ID da aplicação</div><div class="font-mono flex items-center gap-1">{{ a.application.id }} <app-copy-button [value]="a.application.id" /></div></div>
                                    <div><div class="text-surface-500 text-sm">Criada em</div><div>{{ data(a.createdAt) }}</div></div>
                                    <div><div class="text-surface-500 text-sm">Atualizada em</div><div>{{ data(a.updatedAt) }}</div></div>
                                    <div>
                                        <div class="text-surface-500 text-sm mb-1">Tags</div>
                                        @for (t of tagsDe(a.application.tags); track t[0]) {
                                            <p-tag [value]="t[0] + ': ' + t[1]" severity="secondary" class="mr-1 mb-1" />
                                        } @empty {
                                            <span class="text-surface-400">Nenhuma</span>
                                        }
                                    </div>
                                </div>
                                <div class="flex flex-col gap-4">
                                    <div>
                                        <div class="text-surface-500 text-sm mb-1">Perfis de dispositivo em uso</div>
                                        @for (p of perfis(); track p.id) {
                                            <p-tag [value]="p.name" class="mr-1 mb-1" />
                                        } @empty {
                                            <span class="text-surface-400">Nenhum</span>
                                        }
                                    </div>
                                    <div>
                                        <div class="text-surface-500 text-sm mb-1">Chaves de medição (measurement keys)</div>
                                        @for (k of a.measurementKeys; track k) {
                                            <p-tag [value]="k" severity="info" class="mr-1 mb-1" />
                                        } @empty {
                                            <span class="text-surface-400">Nenhuma</span>
                                        }
                                    </div>
                                    <div>
                                        <div class="text-surface-500 text-sm mb-1">Tags dos dispositivos</div>
                                        @for (t of tagsDispositivos(); track t.key) {
                                            <div class="text-sm"><b>{{ t.key }}</b>: {{ t.values.join(', ') }}</div>
                                        } @empty {
                                            <span class="text-surface-400">Nenhuma</span>
                                        }
                                    </div>
                                </div>
                            </div>
                        }
                    </p-tabpanel>
                </p-tabpanels>
            </p-tabs>
        </div>

        <p-dialog [(visible)]="dialogo" header="Editar aplicação" [modal]="true" [style]="{ width: '40rem' }" [breakpoints]="{ '768px': '95vw' }">
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
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [disabled]="!form.name.trim()" />
            </ng-template>
        </p-dialog>
    `
})
export class ApplicationDetail implements OnInit {
    id = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    private route = inject(ActivatedRoute);
    auth = inject(AuthService);

    app = signal<GetApplicationResponse | null>(null);
    perfis = signal<{ id: string; name: string }[]>([]);
    tagsDispositivos = signal<{ key: string; values: string[] }[]>([]);
    aba = signal<string>('dispositivos');
    dialogo = signal(false);
    form: Application = { name: '', description: '', tenantId: '', tags: {} };
    data = dataHora;

    ngOnInit(): void {
        this.aba.set(this.route.snapshot.queryParamMap.get('aba') ?? 'dispositivos');
        this.carregar();
    }

    carregar(): void {
        this.api.getApplication(this.id()).subscribe({ next: (a) => this.app.set(a), error: (e) => this.notify.erro(e) });
        this.api.listApplicationDeviceProfiles(this.id()).subscribe({ next: (r) => this.perfis.set(r.result ?? []) });
        this.api.listApplicationDeviceTags(this.id()).subscribe({ next: (r) => this.tagsDispositivos.set(r.result ?? []) });
    }

    trocarAba(v: string | number | undefined): void {
        const aba = String(v ?? 'dispositivos');
        this.aba.set(aba);
        this.router.navigate([], { queryParams: { aba }, replaceUrl: true });
    }

    tagsDe(t: Record<string, string> | undefined): [string, string][] {
        return Object.entries(t ?? {});
    }

    editar(): void {
        const a = this.app()?.application;
        if (a) {
            this.form = { ...a, tags: { ...(a.tags ?? {}) } };
            this.dialogo.set(true);
        }
    }

    salvar(): void {
        this.api.updateApplication(this.id(), { ...this.form, name: this.form.name.trim() }).subscribe({
            next: () => {
                this.dialogo.set(false);
                this.notify.sucesso('Aplicação atualizada.');
                this.carregar();
            },
            error: (e) => this.notify.erro(e)
        });
    }

    excluir(): void {
        const nome = this.app()?.application?.name ?? '';
        this.notify.confirmarExclusao(`a aplicação "${nome}"`, () =>
            this.api.deleteApplication(this.id()).subscribe({
                next: () => {
                    this.notify.sucesso('Aplicação excluída.');
                    this.router.navigate(['/aplicacoes']);
                },
                error: (e) => this.notify.erro(e)
            }),
            'Todos os dispositivos e grupos multicast da aplicação também serão excluídos.'
        );
    }
}
