import { Component, computed, input, model, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { InputGroupModule } from 'primeng/inputgroup';
import { InputGroupAddonModule } from 'primeng/inputgroupaddon';
import { TooltipModule } from 'primeng/tooltip';
import { hexAleatorio, isHex } from '@/app/core/format/format';
import { CopyButton } from './copy-button';

/**
 * Campo hexadecimal de tamanho fixo (EUI, DevAddr, chaves AES) com gerar, mostrar/ocultar e copiar.
 */
@Component({
    selector: 'app-hex-field',
    standalone: true,
    imports: [FormsModule, ButtonModule, InputTextModule, InputGroupModule, InputGroupAddonModule, TooltipModule, CopyButton],
    template: `
        <label [for]="id()" class="block font-medium mb-2">
            {{ label() }}
            @if (required()) {
                <span class="text-red-500">*</span>
            }
        </label>
        <p-inputgroup>
            <input
                pInputText
                [id]="id()"
                [type]="secret() && !visivel() ? 'password' : 'text'"
                class="font-mono"
                [ngModel]="value()"
                (ngModelChange)="value.set(($event || '').trim().toLowerCase())"
                [maxlength]="bytes() * 2"
                [placeholder]="placeholder() || '0'.repeat(bytes() * 2)"
                [disabled]="disabled()"
                [class.ng-invalid]="tocado() && invalido()"
                [class.ng-dirty]="tocado() && invalido()"
                (blur)="tocado.set(true)"
                autocomplete="off"
                spellcheck="false"
            />
            @if (secret()) {
                <p-inputgroup-addon>
                    <p-button [icon]="visivel() ? 'pi pi-eye-slash' : 'pi pi-eye'" [text]="true" severity="secondary" (onClick)="visivel.set(!visivel())" pTooltip="Mostrar/ocultar" />
                </p-inputgroup-addon>
            }
            @if (generate() && !disabled()) {
                <p-inputgroup-addon>
                    <p-button icon="pi pi-sync" [text]="true" severity="secondary" (onClick)="gerar()" pTooltip="Gerar aleatório" />
                </p-inputgroup-addon>
            }
            <p-inputgroup-addon>
                <app-copy-button [value]="value()" />
            </p-inputgroup-addon>
        </p-inputgroup>
        @if (hint()) {
            <small class="text-surface-500 block mt-1">{{ hint() }}</small>
        }
        @if (tocado() && invalido()) {
            <small class="text-red-500 block mt-1">Informe {{ bytes() * 2 }} caracteres hexadecimais.</small>
        }
    `
})
export class HexField {
    label = input.required<string>();
    id = input<string>('hex-' + Math.random().toString(36).slice(2, 8));
    bytes = input<number>(8);
    required = input<boolean>(false);
    secret = input<boolean>(false);
    generate = input<boolean>(true);
    disabled = input<boolean>(false);
    hint = input<string>('');
    placeholder = input<string>('');
    value = model<string>('');

    visivel = signal(false);
    tocado = signal(false);

    invalido = computed(() => {
        const v = this.value();
        return this.required() ? !isHex(v, this.bytes()) : !!v && !isHex(v, this.bytes());
    });

    gerar(): void {
        this.value.set(hexAleatorio(this.bytes()));
        this.tocado.set(true);
    }
}
