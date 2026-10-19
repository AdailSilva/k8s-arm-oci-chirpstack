import { ChangeDetectorRef, Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { Gateway } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { isHex, num } from '@/app/core/util/format';
import { HexField } from '@/app/shared/hex-field';
import { PageHeader } from '@/app/shared/page-header';
import { TagsEditor } from '@/app/shared/tags-editor';

/**
 * Cadastro e edição de gateway.
 */
@Component({
    selector: 'app-gateway-form',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, InputNumberModule, InputTextModule, TextareaModule, HexField, PageHeader, TagsEditor],
    template: `
        <app-page-header [title]="id() ? 'Editar gateway' : 'Novo gateway'" [subtitle]="'Tenant ' + (ctx.tenant()?.name ?? '')" icon="pi pi-wifi">
            <p-button label="Cancelar" icon="pi pi-times" severity="secondary" [outlined]="true" (onClick)="voltar()" />
            <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
        </app-page-header>

        <div class="grid grid-cols-12 gap-6">
            <div class="col-span-12 xl:col-span-7">
                <div class="card mb-0! flex flex-col gap-5">
                    <div class="font-semibold text-lg">Identificação</div>
                    <app-hex-field label="Gateway ID (EUI-64)" [bytes]="8" [required]="true" [(value)]="form.gatewayId" [disabled]="!!id()" [generate]="false" hint="O mesmo Gateway ID configurado no packet forwarder / ChirpStack Gateway Bridge." />
                    <div>
                        <label class="block font-medium mb-2">Nome <span class="text-red-500">*</span></label>
                        <input pInputText class="w-full" [(ngModel)]="form.name" maxlength="100" />
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Descrição</label>
                        <textarea pTextarea class="w-full" rows="3" [(ngModel)]="form.description"></textarea>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block font-medium mb-2">Intervalo de estatísticas (s)</label>
                            <p-inputnumber [(ngModel)]="form.statsInterval" [min]="1" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                            <small class="text-surface-500">Deve ser igual ao do gateway; serve para calcular se está online.</small>
                        </div>
                        <div>
                            <label class="block font-medium mb-2">Prioridade de downlink</label>
                            <p-inputnumber [(ngModel)]="form.downlinkPriority" [min]="1" [max]="32767" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                            <small class="text-surface-500">Peso na escolha do gateway que envia o downlink quando vários ouviram o dispositivo com boa margem. Padrão 10; 20 = duas vezes mais provável, 5 = metade.</small>
                        </div>
                    </div>
                    <div class="font-semibold text-lg mt-2">Localização</div>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label class="block font-medium mb-2">Latitude</label>
                            <p-inputnumber [(ngModel)]="form.location.latitude" mode="decimal" [minFractionDigits]="0" [maxFractionDigits]="7" [min]="-90" [max]="90" locale="en-US" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                        </div>
                        <div>
                            <label class="block font-medium mb-2">Longitude</label>
                            <p-inputnumber [(ngModel)]="form.location.longitude" mode="decimal" [minFractionDigits]="0" [maxFractionDigits]="7" [min]="-180" [max]="180" locale="en-US" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                        </div>
                        <div>
                            <label class="block font-medium mb-2">Altitude (m)</label>
                            <p-inputnumber [(ngModel)]="form.location.altitude" mode="decimal" [maxFractionDigits]="1" locale="en-US" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                        </div>
                    </div>
                    <div>
                        <p-button label="Usar minha localização" icon="pi pi-map-marker" severity="secondary" [outlined]="true" size="small" (onClick)="minhaLocalizacao()" />
                    </div>
                </div>
            </div>
            <div class="col-span-12 xl:col-span-5 flex flex-col gap-6">
                <div class="card mb-0!">
                    <app-tags-editor label="Tags" hint="Metadados do gateway, enviados junto com os uplinks." [(value)]="form.tags" />
                </div>
                @if (id() && metadataLista().length) {
                    <div class="card mb-0!">
                        <div class="font-medium mb-2">Metadados informados pelo gateway</div>
                        @for (m of metadataLista(); track m[0]) {
                            <div class="text-sm"><b>{{ m[0] }}</b>: {{ m[1] }}</div>
                        }
                    </div>
                }
            </div>
        </div>
    `
})
export class GatewayForm implements OnInit {
    id = input<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    private cdr = inject(ChangeDetectorRef);
    ctx = inject(TenantContextService);

    salvando = signal(false);
    metadataLista = signal<[string, string][]>([]);
    form: Gateway = { gatewayId: '', name: '', description: '', tenantId: '', tags: {}, statsInterval: 30, downlinkPriority: 10, location: { latitude: 0, longitude: 0, altitude: 0 } };

    ngOnInit(): void {
        this.form.tenantId = this.ctx.tenantId() ?? '';
        const id = this.id();
        if (id) {
            this.api.getGateway(id).subscribe({
                next: (r) => {
                    const g = r.gateway;
                    this.form = {
                        ...this.form,
                        ...g,
                        statsInterval: num(g.statsInterval, 30),
                        downlinkPriority: num(g.downlinkPriority, 10) || 10,
                        tags: { ...(g.tags ?? {}) },
                        location: { ...{ latitude: 0, longitude: 0, altitude: 0 }, ...(g.location ?? {}) }
                    };
                    this.metadataLista.set(Object.entries(g.metadata ?? {}));
                },
                error: (e) => this.notify.erro(e)
            });
        }
    }

    minhaLocalizacao(): void {
        if (!navigator.geolocation) {
            this.notify.aviso('O navegador não oferece geolocalização.');
            return;
        }
        navigator.geolocation.getCurrentPosition(
            (p) => {
                this.form.location = { ...this.form.location, latitude: +p.coords.latitude.toFixed(7), longitude: +p.coords.longitude.toFixed(7), altitude: Math.round(p.coords.altitude ?? this.form.location.altitude) };
                this.cdr.markForCheck();
            },
            () => this.notify.aviso('Não foi possível obter a localização.')
        );
    }

    salvar(): void {
        if (!isHex(this.form.gatewayId, 8) || !this.form.name.trim()) {
            this.notify.aviso('Informe o Gateway ID (16 hex) e o nome.');
            return;
        }
        const id = this.id();
        const dados: Gateway = { ...this.form, downlinkPriority: num(this.form.downlinkPriority, 10) || 10, name: this.form.name.trim(), location: { ...this.form.location, source: 'CONFIG' }, tenantId: this.form.tenantId || this.ctx.tenantId() || '' };
        this.salvando.set(true);
        const op = id ? this.api.updateGateway(id, dados) : this.api.createGateway(dados);
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.notify.sucesso(id ? 'Gateway atualizado.' : 'Gateway cadastrado.');
                this.router.navigate(['/gateways', dados.gatewayId]);
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    voltar(): void {
        const id = this.id();
        this.router.navigate(id ? ['/gateways', id] : ['/gateways']);
    }
}
