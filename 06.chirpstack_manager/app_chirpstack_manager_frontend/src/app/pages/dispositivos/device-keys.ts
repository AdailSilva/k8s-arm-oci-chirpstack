import { Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { ButtonModule } from 'primeng/button';
import { MessageModule } from 'primeng/message';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { DeviceKeys, MacVersion } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora, isHex } from '@/app/core/format/format';
import { HexField } from '@/app/shared/campos/hex-field';

/**
 * Chaves OTAA do dispositivo.
 * No ChirpStack v4, para LoRaWAN 1.0.x a "Application key" é gravada no campo nwkKey;
 * appKey só é usado em LoRaWAN 1.1.
 */
@Component({
    selector: 'app-device-keys',
    standalone: true,
    imports: [CommonModule, ButtonModule, MessageModule, HexField],
    template: `
        @if (!supportsOtaa()) {
            <p-message severity="info" text="O perfil deste dispositivo não suporta OTAA. Use a aba Ativação (ABP)." styleClass="mb-4 w-full" />
        }
        <div class="max-w-3xl flex flex-col gap-5">
            @if (lw11()) {
                <app-hex-field label="Network key (NwkKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="keys.nwkKey" [disabled]="!auth.podeEscrever()" hint="LoRaWAN 1.1: chave raiz da camada de rede." />
                <app-hex-field label="Application key (AppKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="keys.appKey" [disabled]="!auth.podeEscrever()" hint="LoRaWAN 1.1: chave raiz da camada de aplicação." />
            } @else {
                <app-hex-field label="Application key (AppKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="keys.nwkKey" [disabled]="!auth.podeEscrever()" hint="LoRaWAN 1.0.x: chave usada no join OTAA (a mesma gravada no firmware)." />
                <app-hex-field label="Gen application key (GenAppKey)" [bytes]="16" [secret]="true" [(value)]="keys.genAppKey" [disabled]="!auth.podeEscrever()" hint="Opcional. Usada só para multicast remoto (TS005) em LoRaWAN 1.0.x." />
            }
            @if (atualizadoEm()) {
                <small class="text-surface-500">Chaves atualizadas em {{ data(atualizadoEm()) }}</small>
            }
            @if (auth.podeEscrever()) {
                <div class="flex flex-wrap gap-2">
                    <p-button [label]="existe() ? 'Salvar chaves' : 'Cadastrar chaves'" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
                    @if (existe()) {
                        <p-button label="Excluir chaves" icon="pi pi-trash" severity="danger" [outlined]="true" (onClick)="excluir()" />
                    }
                    <p-button label="Limpar DevNonces" icon="pi pi-eraser" severity="secondary" [outlined]="true" (onClick)="limparNonces()" />
                </div>
                <small class="text-surface-500">Limpar DevNonces permite um novo join com nonces já usados (útil após regravar o firmware).</small>
            }
        </div>
    `
})
export class DeviceKeysPanel implements OnInit {
    devEui = input.required<string>();
    macVersion = input<MacVersion | undefined>();
    supportsOtaa = input<boolean>(true);

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);

    keys: DeviceKeys = { nwkKey: '', appKey: '', genAppKey: '' };
    existe = signal(false);
    salvando = signal(false);
    atualizadoEm = signal<string | null>(null);
    lw11 = computed(() => this.macVersion() === 'LORAWAN_1_1_0');
    data = dataHora;

    ngOnInit(): void {
        this.api.getDeviceKeys(this.devEui()).subscribe({
            next: (r) => {
                this.keys = { nwkKey: r.deviceKeys.nwkKey ?? '', appKey: r.deviceKeys.appKey ?? '', genAppKey: r.deviceKeys.genAppKey ?? '' };
                this.atualizadoEm.set(r.updatedAt);
                this.existe.set(true);
            },
            error: (e) => {
                if (!(e instanceof HttpErrorResponse && e.status === 404)) {
                    this.notify.erro(e);
                }
                this.existe.set(false);
            }
        });
    }

    salvar(): void {
        const vazio = '00000000000000000000000000000000';
        if (!isHex(this.keys.nwkKey, 16) || (this.lw11() && !isHex(this.keys.appKey, 16))) {
            this.notify.aviso('Informe as chaves com 32 caracteres hexadecimais.');
            return;
        }
        const dados: DeviceKeys = {
            nwkKey: this.keys.nwkKey,
            appKey: this.lw11() ? this.keys.appKey : vazio,
            genAppKey: this.keys.genAppKey && isHex(this.keys.genAppKey, 16) ? this.keys.genAppKey : vazio
        };
        this.salvando.set(true);
        const op = this.existe() ? this.api.updateDeviceKeys(this.devEui(), dados) : this.api.createDeviceKeys(this.devEui(), dados);
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.existe.set(true);
                this.notify.sucesso('Chaves OTAA salvas.');
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    excluir(): void {
        this.notify.confirmarExclusao('as chaves OTAA deste dispositivo', () =>
            this.api.deleteDeviceKeys(this.devEui()).subscribe({
                next: () => {
                    this.existe.set(false);
                    this.keys = { nwkKey: '', appKey: '', genAppKey: '' };
                    this.atualizadoEm.set(null);
                    this.notify.sucesso('Chaves excluídas.');
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }

    limparNonces(): void {
        this.notify.confirmar('Limpar DevNonces', 'Apagar o histórico de DevNonces deste dispositivo?', () =>
            this.api.flushDevNonces(this.devEui()).subscribe({
                next: () => this.notify.sucesso('DevNonces apagados.'),
                error: (e) => this.notify.erro(e)
            }), 'Limpar');
    }
}
