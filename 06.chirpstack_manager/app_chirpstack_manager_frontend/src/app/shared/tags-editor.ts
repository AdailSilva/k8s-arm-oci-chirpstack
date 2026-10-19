import { Component, effect, input, model, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';

interface Linha {
    chave: string;
    valor: string;
}

/**
 * Editor de mapa chave/valor (tags, variáveis, metadados, cabeçalhos HTTP).
 */
@Component({
    selector: 'app-tags-editor',
    standalone: true,
    imports: [FormsModule, ButtonModule, InputTextModule],
    template: `
        @if (label()) {
            <div class="font-medium mb-2">{{ label() }}</div>
        }
        @if (hint()) {
            <p class="text-surface-500 text-sm mt-0 mb-3">{{ hint() }}</p>
        }
        <div class="flex flex-col gap-2">
            @for (l of linhas(); track $index; let i = $index) {
                <div class="flex gap-2 items-center">
                    <input pInputText class="flex-1" [placeholder]="keyLabel()" [ngModel]="l.chave" (ngModelChange)="alterar(i, 'chave', $event)" [disabled]="disabled()" />
                    <input pInputText class="flex-[2]" [placeholder]="valueLabel()" [ngModel]="l.valor" (ngModelChange)="alterar(i, 'valor', $event)" [disabled]="disabled()" />
                    @if (!disabled()) {
                        <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" (onClick)="remover(i)" />
                    }
                </div>
            } @empty {
                <div class="text-surface-400 text-sm">Nenhum item.</div>
            }
        </div>
        @if (!disabled()) {
            <p-button class="mt-3 inline-block" label="Adicionar" icon="pi pi-plus" size="small" severity="secondary" [outlined]="true" (onClick)="adicionar()" />
        }
    `
})
export class TagsEditor {
    label = input<string>('');
    hint = input<string>('');
    keyLabel = input<string>('Chave');
    valueLabel = input<string>('Valor');
    disabled = input<boolean>(false);
    value = model<Record<string, string> | null | undefined>({});

    linhas = signal<Linha[]>([]);
    private interno = false;

    constructor() {
        effect(() => {
            const v = this.value() ?? {};
            if (this.interno) {
                this.interno = false;
                return;
            }
            this.linhas.set(Object.entries(v).map(([chave, valor]) => ({ chave, valor })));
        });
    }

    adicionar(): void {
        this.linhas.update((l) => [...l, { chave: '', valor: '' }]);
    }

    remover(i: number): void {
        this.linhas.update((l) => l.filter((_, idx) => idx !== i));
        this.publicar();
    }

    alterar(i: number, campo: keyof Linha, valor: string): void {
        this.linhas.update((l) => l.map((x, idx) => (idx === i ? { ...x, [campo]: valor } : x)));
        this.publicar();
    }

    private publicar(): void {
        const mapa: Record<string, string> = {};
        for (const l of this.linhas()) {
            const k = l.chave.trim();
            if (k) {
                mapa[k] = l.valor;
            }
        }
        this.interno = true;
        this.value.set(mapa);
    }
}
