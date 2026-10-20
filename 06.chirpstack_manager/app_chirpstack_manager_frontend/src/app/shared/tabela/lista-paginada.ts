import { signal, untracked } from '@angular/core';
import { Observable, Subscription } from 'rxjs';
import { TableLazyLoadEvent } from 'primeng/table';
import { ListResponse } from '@/app/core/http/models';
import { PageQuery } from '@/app/core/http/chirpstack.service';
import { num } from '@/app/core/format/format';

export interface ConsultaPagina extends PageQuery {
    limit: number;
    offset: number;
    search: string;
}

/**
 * Base das tabelas com paginação no servidor (o ChirpStack pagina por limit/offset).
 */
export abstract class ListaPaginada<T> {
    readonly itens = signal<T[]>([]);
    readonly total = signal(0);
    readonly carregando = signal(false);
    readonly busca = signal('');
    readonly first = signal(0);
    readonly rows = signal(20);

    private sub?: Subscription;
    private debounce?: ReturnType<typeof setTimeout>;

    protected abstract consultar(q: ConsultaPagina): Observable<ListResponse<T>> | null;

    carregar(): void {
        untracked(() => {
            const obs = this.consultar({ limit: this.rows(), offset: this.first(), search: this.busca().trim() });
            this.sub?.unsubscribe();
            if (!obs) {
                this.itens.set([]);
                this.total.set(0);
                return;
            }
            this.carregando.set(true);
            this.sub = obs.subscribe({
                next: (r) => {
                    this.itens.set(r.result ?? []);
                    this.total.set(num(r.totalCount));
                    this.carregando.set(false);
                },
                error: (e) => {
                    this.carregando.set(false);
                    this.aoFalhar(e);
                }
            });
        });
    }

    recarregarDoInicio(): void {
        this.first.set(0);
        this.carregar();
    }

    onLazy(e: TableLazyLoadEvent): void {
        this.first.set(e.first ?? 0);
        this.rows.set(e.rows ?? 20);
        this.carregar();
    }

    pesquisar(texto: string): void {
        this.busca.set(texto);
        clearTimeout(this.debounce);
        this.debounce = setTimeout(() => this.recarregarDoInicio(), 350);
    }

    protected aoFalhar(_e: unknown): void {
        /* sobrescrito pelas telas que exibem toast */
    }
}
