import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { CheckboxModule } from 'primeng/checkbox';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { SelectButtonModule } from 'primeng/selectbutton';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ChirpstackService } from '@/app/core/api/chirpstack.service';
import { DeviceQueueItem } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { base64ParaHex, dataHora, hexParaBase64, num, textoParaBase64 } from '@/app/core/util/format';

type Formato = 'hex' | 'base64' | 'texto' | 'json';

/**
 * Fila de downlink do dispositivo: listar, enfileirar e limpar.
 */
@Component({
    selector: 'app-device-queue',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, CheckboxModule, InputNumberModule, InputTextModule, SelectButtonModule, TableModule, TagModule, TextareaModule],
    template: `
        <div class="grid grid-cols-12 gap-6">
            @if (auth.podeEscrever()) {
                <div class="col-span-12 xl:col-span-5">
                    <div class="border border-surface-200 dark:border-surface-700 rounded-2xl p-5 flex flex-col gap-4">
                        <div class="font-semibold">Enfileirar downlink</div>
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <label class="block font-medium mb-2">FPort</label>
                                <p-inputnumber [(ngModel)]="fPort" [min]="1" [max]="223" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" />
                            </div>
                            <div class="flex items-end pb-2">
                                <label class="flex items-center gap-2"><p-checkbox [(ngModel)]="confirmado" [binary]="true" /> Confirmado</label>
                            </div>
                        </div>
                        <div>
                            <label class="block font-medium mb-2">Formato do payload</label>
                            <p-selectbutton [options]="formatos" optionLabel="label" optionValue="value" [(ngModel)]="formato" [allowEmpty]="false" size="small" />
                        </div>
                        <div>
                            <textarea pTextarea class="w-full font-mono text-sm" rows="4" [(ngModel)]="payload" [placeholder]="exemplos[formato]"></textarea>
                            @if (formato === 'json') {
                                <small class="text-surface-500">O objeto JSON é convertido em bytes pela função encodeDownlink do codec do perfil.</small>
                            }
                        </div>
                        <label class="flex items-center gap-2"><p-checkbox [(ngModel)]="limparAntes" [binary]="true" /> Limpar a fila antes de enfileirar</label>
                        <p-button label="Enfileirar" icon="pi pi-send" (onClick)="enfileirar()" [loading]="enviando()" />
                        <small class="text-surface-500">Classe A: entregue após o próximo uplink. Classe B/C: entregue no próximo slot disponível.</small>
                    </div>
                </div>
            }
            <div class="col-span-12" [ngClass]="{ 'xl:col-span-7': auth.podeEscrever() }">
                <div class="flex items-center justify-between mb-3">
                    <span class="font-semibold">Itens na fila ({{ itens().length }})</span>
                    <div class="flex gap-2">
                        <p-button icon="pi pi-refresh" severity="secondary" [outlined]="true" (onClick)="carregar()" [loading]="carregando()" />
                        @if (auth.podeEscrever()) {
                            <p-button label="Limpar fila" icon="pi pi-trash" severity="danger" [outlined]="true" (onClick)="limpar()" [disabled]="!itens().length" />
                        }
                    </div>
                </div>
                <p-table [value]="itens()" [loading]="carregando()" [tableStyle]="{ 'min-width': '40rem' }">
                    <ng-template #header>
                        <tr>
                            <th>FPort</th>
                            <th>Confirmado</th>
                            <th>Payload (hex)</th>
                            <th>FCntDown</th>
                            <th>Situação</th>
                            <th>Expira em</th>
                        </tr>
                    </ng-template>
                    <ng-template #body let-q>
                        <tr>
                            <td>{{ q.fPort }}</td>
                            <td>{{ q.confirmed ? 'Sim' : 'Não' }}</td>
                            <td class="font-mono text-sm break-all">{{ hex(q.data) || '—' }}</td>
                            <td>{{ fcnt(q.fCntDown) }}</td>
                            <td><p-tag [value]="q.isPending ? 'Enviado, aguardando ACK' : 'Na fila'" [severity]="q.isPending ? 'warn' : 'info'" /></td>
                            <td>{{ q.expiresAt ? data(q.expiresAt) : '—' }}</td>
                        </tr>
                    </ng-template>
                    <ng-template #emptymessage>
                        <tr><td colspan="6" class="text-center py-6 text-surface-500">A fila está vazia.</td></tr>
                    </ng-template>
                </p-table>
            </div>
        </div>
    `
})
export class DeviceQueuePanel implements OnInit {
    devEui = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);

    itens = signal<DeviceQueueItem[]>([]);
    carregando = signal(false);
    enviando = signal(false);
    fPort = 1;
    confirmado = false;
    limparAntes = false;
    formato: Formato = 'hex';
    payload = '';
    data = dataHora;
    hex = base64ParaHex;
    formatos = [
        { label: 'Hex', value: 'hex' },
        { label: 'Base64', value: 'base64' },
        { label: 'Texto', value: 'texto' },
        { label: 'JSON (codec)', value: 'json' }
    ];
    exemplos: Record<Formato, string> = { hex: '01 0A FF', base64: 'AQr/', texto: 'liga', json: '{ "rele": true }' };

    ngOnInit(): void {
        this.carregar();
    }

    fcnt(v: string | number | undefined): string {
        return v === undefined || v === null ? '—' : String(num(v));
    }

    carregar(): void {
        this.carregando.set(true);
        this.api.getDeviceQueue(this.devEui()).subscribe({
            next: (r) => {
                this.itens.set(r.result ?? []);
                this.carregando.set(false);
            },
            error: (e) => {
                this.carregando.set(false);
                this.notify.erro(e);
            }
        });
    }

    enfileirar(): void {
        const item: DeviceQueueItem = { fPort: this.fPort, confirmed: this.confirmado };
        try {
            switch (this.formato) {
                case 'hex':
                    item.data = hexParaBase64(this.payload);
                    break;
                case 'base64':
                    atob(this.payload.trim());
                    item.data = this.payload.trim();
                    break;
                case 'texto':
                    item.data = textoParaBase64(this.payload);
                    break;
                case 'json':
                    item.object = JSON.parse(this.payload);
                    break;
            }
        } catch {
            this.notify.aviso('Payload inválido para o formato escolhido.');
            return;
        }
        if (!this.fPort || this.fPort < 1 || this.fPort > 223) {
            this.notify.aviso('FPort deve estar entre 1 e 223.');
            return;
        }
        this.enviando.set(true);
        this.api.enqueue(this.devEui(), item, this.limparAntes).subscribe({
            next: () => {
                this.enviando.set(false);
                this.notify.sucesso('Downlink enfileirado.');
                this.carregar();
            },
            error: (e) => {
                this.enviando.set(false);
                this.notify.erro(e);
            }
        });
    }

    limpar(): void {
        this.notify.confirmar('Limpar fila', 'Remover todos os downlinks pendentes deste dispositivo?', () =>
            this.api.flushDeviceQueue(this.devEui()).subscribe({
                next: () => {
                    this.notify.sucesso('Fila limpa.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            }), 'Limpar');
    }
}
