import { Component, inject } from '@angular/core';
import { PageHeader } from '@/app/shared/page-header';
import { TenantContextService } from '@/app/core/util/tenant-context.service';
import { MulticastTable } from './multicast-table';

/**
 * Todos os grupos multicast do tenant selecionado, de todas as aplicações (4.19+).
 */
@Component({
    selector: 'app-multicast-list',
    standalone: true,
    imports: [PageHeader, MulticastTable],
    template: `
        <app-page-header title="Grupos multicast" [subtitle]="'Todas as aplicações · ' + (ctx.tenant()?.name ?? 'sem tenant')" icon="pi pi-sitemap" />
        <div class="card">
            <app-multicast-table />
        </div>
    `
})
export class MulticastList {
    ctx = inject(TenantContextService);
}
