import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TextareaModule } from 'primeng/textarea';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { Device, DeviceProfileListItem } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { isHex } from '@/app/core/util/format';
import { HexField } from '@/app/shared/hex-field';
import { PageHeader } from '@/app/shared/page-header';
import { TagsEditor } from '@/app/shared/tags-editor';

/**
 * Cadastro e edição de dispositivo.
 */
@Component({
    selector: 'app-device-form',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, InputTextModule, SelectModule, TextareaModule, ToggleSwitchModule, HexField, PageHeader, TagsEditor],
    template: `
        <app-page-header [title]="devEui() ? 'Editar dispositivo' : 'Novo dispositivo'" [subtitle]="nomeApp()" icon="pi pi-microchip">
            <p-button label="Cancelar" icon="pi pi-times" severity="secondary" [outlined]="true" (onClick)="voltar()" />
            <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
        </app-page-header>

        <div class="grid grid-cols-12 gap-6">
            <div class="col-span-12 xl:col-span-7">
                <div class="card mb-0! flex flex-col gap-5">
                    <div class="font-semibold text-lg">Identificação</div>
                    <div>
                        <label class="block font-medium mb-2">Nome <span class="text-red-500">*</span></label>
                        <input pInputText class="w-full" [(ngModel)]="form.name" maxlength="100" />
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Descrição</label>
                        <textarea pTextarea class="w-full" rows="2" [(ngModel)]="form.description"></textarea>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <app-hex-field label="DevEUI" [bytes]="8" [required]="true" [(value)]="form.devEui" [disabled]="!!devEui()" [generate]="!devEui()" hint="Identificador único do dispositivo (EUI-64)." />
                        </div>
                        <div>
                            <app-hex-field label="JoinEUI (AppEUI)" [bytes]="8" [(value)]="form.joinEui" hint="Opcional. Preenchido no primeiro join OTAA se vazio." />
                        </div>
                    </div>
                    <div>
                        <label class="block font-medium mb-2">Perfil de dispositivo <span class="text-red-500">*</span></label>
                        <p-select [options]="perfis()" optionLabel="name" optionValue="id" [(ngModel)]="form.deviceProfileId" [filter]="true" filterBy="name" placeholder="Selecione" styleClass="w-full" emptyMessage="Nenhum perfil neste tenant">
                            <ng-template #item let-p>
                                <div>
                                    <div>{{ p.name }}</div>
                                    <div class="text-xs text-surface-500">{{ p.region }} · {{ p.macVersion }} · {{ p.supportsOtaa ? 'OTAA' : 'ABP' }}</div>
                                </div>
                            </ng-template>
                        </p-select>
                    </div>
                    <div class="flex flex-col gap-3">
                        <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.isDisabled" /> Dispositivo desativado (o ChirpStack ignora os pacotes dele)</label>
                        <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.skipFcntCheck" /> Ignorar verificação do contador de quadros (frame-counter)</label>
                        @if (form.skipFcntCheck) {
                            <small class="text-amber-600 -mt-2">Desligar a verificação deixa o dispositivo vulnerável a ataques de repetição. Use só para testes.</small>
                        }
                    </div>
                </div>
            </div>
            <div class="col-span-12 xl:col-span-5 flex flex-col gap-6">
                <div class="card mb-0!">
                    <app-tags-editor label="Tags" hint="Metadados enviados junto com os eventos para as integrações." [(value)]="form.tags" />
                </div>
                <div class="card mb-0!">
                    <app-tags-editor label="Variáveis" hint="Valores usados pelas integrações (ex.: tokens). Não aparecem nos eventos." [(value)]="form.variables" />
                </div>
            </div>
        </div>
    `
})
export class DeviceForm implements OnInit {
    applicationId = input.required<string>();
    devEui = input<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);

    perfis = signal<DeviceProfileListItem[]>([]);
    nomeApp = signal('');
    salvando = signal(false);
    carregado = signal(false);
    form: Device = { devEui: '', joinEui: '', name: '', description: '', applicationId: '', deviceProfileId: '', isDisabled: false, skipFcntCheck: false, tags: {}, variables: {} };

    ngOnInit(): void {
        this.form.applicationId = this.applicationId();
        this.api.getApplication(this.applicationId()).subscribe({
            next: (a) => {
                this.nomeApp.set('Aplicação ' + a.application.name);
                this.api.listDeviceProfiles({ tenantId: a.application.tenantId, limit: 1000 }).subscribe({ next: (r) => this.perfis.set(r.result) });
            },
            error: (e) => this.notify.erro(e)
        });
        const eui = this.devEui();
        if (eui) {
            this.api.getDevice(eui).subscribe({
                next: (r) => {
                    this.form = { ...this.form, ...r.device, tags: { ...(r.device.tags ?? {}) }, variables: { ...(r.device.variables ?? {}) } };
                    this.carregado.set(true);
                },
                error: (e) => this.notify.erro(e)
            });
        }
    }

    private validar(): string | null {
        if (!this.form.name.trim()) {
            return 'Informe o nome.';
        }
        if (!isHex(this.form.devEui, 8)) {
            return 'DevEUI deve ter 16 caracteres hexadecimais.';
        }
        if (this.form.joinEui && !isHex(this.form.joinEui, 8)) {
            return 'JoinEUI deve ter 16 caracteres hexadecimais.';
        }
        if (!this.form.deviceProfileId) {
            return 'Selecione o perfil de dispositivo.';
        }
        return null;
    }

    salvar(): void {
        const erro = this.validar();
        if (erro) {
            this.notify.aviso(erro);
            return;
        }
        const dados: Device = { ...this.form, name: this.form.name.trim(), joinEui: this.form.joinEui || '0000000000000000' };
        this.salvando.set(true);
        const eui = this.devEui();
        const op = eui ? this.api.updateDevice(eui, dados) : this.api.createDevice(dados);
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.notify.sucesso(eui ? 'Dispositivo atualizado.' : 'Dispositivo criado.');
                const otaa = this.perfis().find((p) => p.id === dados.deviceProfileId)?.supportsOtaa;
                const aba = eui ? 'resumo' : otaa ? 'chaves' : 'ativacao';
                this.router.navigate(['/aplicacoes', this.applicationId(), 'dispositivos', dados.devEui], { queryParams: { aba } });
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    voltar(): void {
        const eui = this.devEui();
        if (eui) {
            this.router.navigate(['/aplicacoes', this.applicationId(), 'dispositivos', eui]);
        } else {
            this.router.navigate(['/aplicacoes', this.applicationId()]);
        }
    }
}
