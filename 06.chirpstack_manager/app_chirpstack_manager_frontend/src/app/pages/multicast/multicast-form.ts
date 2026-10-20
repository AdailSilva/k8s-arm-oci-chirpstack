import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { MulticastGroup } from '@/app/core/http/models';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { isHex, num } from '@/app/core/format/format';
import { AGENDAMENTO_CLASSE_C, PERIODICIDADE_PING_SLOT, REGIOES, TIPOS_MULTICAST } from '@/app/core/format/options';
import { HexField } from '@/app/shared/campos/hex-field';
import { PageHeader } from '@/app/shared/visual/page-header';

/**
 * Cadastro e edição de grupo multicast.
 */
@Component({
    selector: 'app-multicast-form',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, InputNumberModule, InputTextModule, SelectModule, HexField, PageHeader],
    template: `
        <app-page-header [title]="id() ? 'Editar grupo multicast' : 'Novo grupo multicast'" subtitle="Sessão multicast compartilhada pelos dispositivos do grupo" icon="pi pi-sitemap">
            <p-button label="Cancelar" icon="pi pi-times" severity="secondary" [outlined]="true" (onClick)="voltar()" />
            <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
        </app-page-header>

        <div class="grid grid-cols-12 gap-6">
            <div class="col-span-12 xl:col-span-6">
                <div class="card mb-0! flex flex-col gap-5">
                    <div class="font-semibold text-lg">Grupo</div>
                    <div>
                        <label class="block font-medium mb-2">Nome <span class="text-red-500">*</span></label>
                        <input pInputText class="w-full" [(ngModel)]="form.name" maxlength="100" />
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block font-medium mb-2">Região</label>
                            <p-select [options]="regioes" optionLabel="label" optionValue="value" [(ngModel)]="form.region" styleClass="w-full" />
                        </div>
                        <div>
                            <label class="block font-medium mb-2">Tipo</label>
                            <p-select [options]="tipos" optionLabel="label" optionValue="value" [(ngModel)]="form.groupType" styleClass="w-full" />
                        </div>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block font-medium mb-2">Data rate (DR)</label>
                            <p-inputnumber [(ngModel)]="form.dr" [min]="0" [max]="15" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                        </div>
                        <div>
                            <label class="block font-medium mb-2">Frequência (Hz)</label>
                            <p-inputnumber [(ngModel)]="form.frequency" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" placeholder="923300000" />
                        </div>
                    </div>
                    @if (form.groupType === 'CLASS_B') {
                        <div>
                            <label class="block font-medium mb-2">Periodicidade do ping-slot</label>
                            <p-select [options]="periodicidades" optionLabel="label" optionValue="value" [(ngModel)]="form.classBPingSlotPeriodicity" styleClass="w-full" />
                        </div>
                    } @else {
                        <div>
                            <label class="block font-medium mb-2">Agendamento classe C</label>
                            <p-select [options]="agendamentos" optionLabel="label" optionValue="value" [(ngModel)]="form.classCSchedulingType" styleClass="w-full" />
                        </div>
                    }
                </div>
            </div>
            <div class="col-span-12 xl:col-span-6">
                <div class="card mb-0! flex flex-col gap-5">
                    <div class="font-semibold text-lg">Sessão multicast</div>
                    <app-hex-field label="Multicast address (McAddr)" [bytes]="4" [required]="true" [(value)]="form.mcAddr" />
                    <app-hex-field label="Multicast network session key (McNwkSKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.mcNwkSKey" />
                    <app-hex-field label="Multicast application session key (McAppSKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.mcAppSKey" />
                    <div>
                        <label class="block font-medium mb-2">Frame-counter (FCnt)</label>
                        <p-inputnumber [(ngModel)]="form.fCnt" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                    </div>
                </div>
            </div>
        </div>
    `
})
export class MulticastForm implements OnInit {
    applicationId = input.required<string>();
    id = input<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);

    regioes = REGIOES;
    tipos = TIPOS_MULTICAST;
    periodicidades = PERIODICIDADE_PING_SLOT;
    agendamentos = AGENDAMENTO_CLASSE_C;
    salvando = signal(false);
    carregado = signal(false);
    form: MulticastGroup = {
        name: '', applicationId: '', region: 'AU915', mcAddr: '', mcNwkSKey: '', mcAppSKey: '', fCnt: 0, groupType: 'CLASS_C', dr: 8, frequency: 923300000, classBPingSlotPeriodicity: 0, classCSchedulingType: 'DELAY'
    };

    ngOnInit(): void {
        this.form.applicationId = this.applicationId();
        const id = this.id();
        if (id) {
            this.api.getMulticastGroup(id).subscribe({
                next: (r) => {
                    const g = r.multicastGroup;
                    this.form = { ...this.form, ...g, fCnt: num(g.fCnt), dr: num(g.dr), frequency: num(g.frequency), classBPingSlotPeriodicity: num(g.classBPingSlotPeriodicity) };
                    this.carregado.set(true);
                },
                error: (e) => this.notify.erro(e)
            });
        }
    }

    salvar(): void {
        const f = this.form;
        if (!f.name.trim() || !isHex(f.mcAddr, 4) || !isHex(f.mcNwkSKey, 16) || !isHex(f.mcAppSKey, 16)) {
            this.notify.aviso('Preencha o nome, o McAddr (8 hex) e as chaves (32 hex).');
            return;
        }
        this.salvando.set(true);
        const id = this.id();
        const op = id ? this.api.updateMulticastGroup(id, { ...f, name: f.name.trim() }) : this.api.createMulticastGroup({ ...f, name: f.name.trim() });
        op.subscribe({
            next: (r) => {
                this.salvando.set(false);
                this.notify.sucesso(id ? 'Grupo atualizado.' : 'Grupo criado.');
                const novoId = id ?? (r as { id: string }).id;
                this.router.navigate(['/aplicacoes', this.applicationId(), 'multicast', novoId]);
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    voltar(): void {
        this.router.navigate(['/aplicacoes', this.applicationId()], { queryParams: { aba: 'multicast' } });
    }
}
