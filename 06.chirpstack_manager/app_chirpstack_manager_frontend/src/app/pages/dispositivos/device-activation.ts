import { Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputNumberModule } from 'primeng/inputnumber';
import { MessageModule } from 'primeng/message';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { DeviceActivation, MacVersion } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { isHex, num } from '@/app/core/format/format';
import { HexField } from '@/app/shared/campos/hex-field';

/**
 * Sessão (ativação) do dispositivo: consulta, ativação ABP e desativação.
 */
@Component({
    selector: 'app-device-activation',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, InputNumberModule, MessageModule, HexField],
    template: `
        @if (ativo()) {
            <p-message severity="success" styleClass="mb-4 w-full" text="Dispositivo ativado. Os valores abaixo são a sessão atual (OTAA ou ABP)." />
        } @else {
            <p-message severity="warn" styleClass="mb-4 w-full" [text]="supportsOtaa() ? 'Dispositivo ainda não fez join (OTAA). Você também pode ativá-lo manualmente (ABP).' : 'Dispositivo não ativado. Preencha os dados ABP e clique em Ativar.'" />
        }
        <div class="max-w-4xl grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="md:col-span-2 flex items-end gap-2">
                <div class="flex-1">
                    <app-hex-field label="Device address (DevAddr)" [bytes]="4" [required]="true" [generate]="false" [(value)]="form.devAddr" [disabled]="!editavel()" />
                </div>
                @if (editavel()) {
                    <p-button label="Gerar DevAddr" icon="pi pi-sync" severity="secondary" [outlined]="true" (onClick)="gerarDevAddr()" class="mb-[1px]" />
                }
            </div>
            @if (lw11()) {
                <app-hex-field label="Network session encryption key (NwkSEncKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.nwkSEncKey" [disabled]="!editavel()" />
                <app-hex-field label="Serving network session integrity key (SNwkSIntKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.sNwkSIntKey" [disabled]="!editavel()" />
                <app-hex-field label="Forwarding network session integrity key (FNwkSIntKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.fNwkSIntKey" [disabled]="!editavel()" />
            } @else {
                <app-hex-field label="Network session key (NwkSKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.nwkSEncKey" [disabled]="!editavel()" />
            }
            <app-hex-field label="Application session key (AppSKey)" [bytes]="16" [secret]="true" [required]="true" [(value)]="form.appSKey" [disabled]="!editavel()" />
            <div class="md:col-span-2 grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block font-medium mb-2">FCntUp</label>
                    <p-inputnumber [(ngModel)]="form.fCntUp" [min]="0" [useGrouping]="false" [disabled]="!editavel()" styleClass="w-full" inputStyleClass="w-full" />
                </div>
                <div>
                    <label class="block font-medium mb-2">NFCntDown</label>
                    <p-inputnumber [(ngModel)]="form.nFCntDown" [min]="0" [useGrouping]="false" [disabled]="!editavel()" styleClass="w-full" inputStyleClass="w-full" />
                </div>
                <div>
                    <label class="block font-medium mb-2">AFCntDown {{ lw11() ? '' : '(não usado no 1.0.x)' }}</label>
                    <p-inputnumber [(ngModel)]="form.aFCntDown" [min]="0" [useGrouping]="false" [disabled]="!editavel() || !lw11()" styleClass="w-full" inputStyleClass="w-full" />
                </div>
            </div>
        </div>
        @if (auth.podeEscrever()) {
            <div class="flex flex-wrap gap-2 mt-6">
                @if (!editando()) {
                    <p-button [label]="ativo() ? 'Reativar (ABP)' : 'Ativar (ABP)'" icon="pi pi-bolt" (onClick)="iniciarEdicao()" />
                } @else {
                    <p-button label="Ativar" icon="pi pi-check" (onClick)="ativar()" [loading]="salvando()" />
                    <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="cancelar()" />
                }
                @if (ativo() && !editando()) {
                    <p-button label="Desativar" icon="pi pi-power-off" severity="danger" [outlined]="true" (onClick)="desativar()" />
                    <p-button label="Próximo FCntDown" icon="pi pi-calculator" severity="secondary" [outlined]="true" (onClick)="proximoFCnt()" />
                }
            </div>
        }
    `
})
export class DeviceActivationPanel implements OnInit {
    devEui = input.required<string>();
    macVersion = input<MacVersion | undefined>();
    supportsOtaa = input<boolean>(true);

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);

    ativo = signal(false);
    editando = signal(false);
    salvando = signal(false);
    lw11 = computed(() => this.macVersion() === 'LORAWAN_1_1_0');
    editavel = computed(() => this.editando());
    form: DeviceActivation = this.vazio();
    private original: DeviceActivation = this.vazio();

    ngOnInit(): void {
        this.carregar();
    }

    private vazio(): DeviceActivation {
        return { devAddr: '', appSKey: '', nwkSEncKey: '', sNwkSIntKey: '', fNwkSIntKey: '', fCntUp: 0, nFCntDown: 0, aFCntDown: 0 };
    }

    carregar(): void {
        this.api.getDeviceActivation(this.devEui()).subscribe({
            next: (r) => {
                const a = r.deviceActivation;
                if (a && a.devAddr) {
                    this.form = { ...this.vazio(), ...a, fCntUp: num(a.fCntUp), nFCntDown: num(a.nFCntDown), aFCntDown: num(a.aFCntDown) };
                    this.ativo.set(true);
                } else {
                    this.form = this.vazio();
                    this.ativo.set(false);
                }
                this.original = { ...this.form };
            },
            error: (e) => {
                if (!(e instanceof HttpErrorResponse && e.status === 404)) {
                    this.notify.erro(e);
                }
                this.ativo.set(false);
            }
        });
    }

    iniciarEdicao(): void {
        this.editando.set(true);
    }

    cancelar(): void {
        this.form = { ...this.original };
        this.editando.set(false);
    }

    gerarDevAddr(): void {
        this.api.getRandomDevAddr(this.devEui()).subscribe({
            next: (r) => {
                this.form = { ...this.form, devAddr: r.devAddr };
                this.editando.set(true);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    ativar(): void {
        const f = { ...this.form };
        if (!this.lw11()) {
            f.sNwkSIntKey = f.nwkSEncKey;
            f.fNwkSIntKey = f.nwkSEncKey;
        }
        if (!isHex(f.devAddr, 4) || ![f.nwkSEncKey, f.sNwkSIntKey, f.fNwkSIntKey, f.appSKey].every((k) => isHex(k, 16))) {
            this.notify.aviso('Preencha DevAddr (8 hex) e as chaves de sessão (32 hex).');
            return;
        }
        this.salvando.set(true);
        this.api.activateDevice(this.devEui(), f).subscribe({
            next: () => {
                this.salvando.set(false);
                this.editando.set(false);
                this.notify.sucesso('Dispositivo ativado.');
                this.carregar();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    desativar(): void {
        this.notify.confirmar('Desativar dispositivo', 'Apagar a sessão atual? O dispositivo precisará fazer join (OTAA) ou ser ativado de novo (ABP).', () =>
            this.api.deactivateDevice(this.devEui()).subscribe({
                next: () => {
                    this.notify.sucesso('Dispositivo desativado.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            }), 'Desativar');
    }

    proximoFCnt(): void {
        this.api.getNextFCntDown(this.devEui()).subscribe({
            next: (r) => this.notify.info(`Próximo FCntDown: ${num(r.fCntDown)}. Use-o ao enfileirar payloads já criptografados.`),
            error: (e) => this.notify.erro(e)
        });
    }
}
