import { computed, inject, Injectable, signal } from '@angular/core';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { TenantListItem } from '@/app/core/http/models';

const CHAVE = 'csm.tenantId';

/**
 * Tenant selecionado no topo da tela. Aplicações, gateways, perfis e o painel inicial
 * trabalham sempre dentro do tenant escolhido.
 */
@Injectable({ providedIn: 'root' })
export class TenantContextService {
    private api = inject(ChirpstackService);

    readonly tenants = signal<TenantListItem[]>([]);
    readonly tenantId = signal<string | null>(this.lerSalvo());
    readonly carregando = signal(false);
    readonly tenant = computed(() => this.tenants().find((t) => t.id === this.tenantId()) ?? null);

    carregar(): void {
        this.carregando.set(true);
        this.api.listTenants({ limit: 1000 }).subscribe({
            next: (r) => {
                const lista = [...r.result].sort((a, b) => a.name.localeCompare(b.name));
                this.tenants.set(lista);
                if (!lista.some((t) => t.id === this.tenantId())) {
                    this.selecionar(lista[0]?.id ?? null);
                }
                this.carregando.set(false);
            },
            error: () => this.carregando.set(false)
        });
    }

    selecionar(id: string | null): void {
        this.tenantId.set(id);
        try {
            if (id) {
                localStorage.setItem(CHAVE, id);
            } else {
                localStorage.removeItem(CHAVE);
            }
        } catch {
            /* armazenamento indisponível: segue só em memória */
        }
    }

    private lerSalvo(): string | null {
        try {
            return localStorage.getItem(CHAVE);
        } catch {
            return null;
        }
    }
}
