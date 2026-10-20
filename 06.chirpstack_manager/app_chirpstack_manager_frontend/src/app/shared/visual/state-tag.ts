import { Component, computed, input } from '@angular/core';
import { TagModule } from 'primeng/tag';

/** Estado do gateway (online, offline, nunca visto). */
@Component({
    selector: 'app-state-tag',
    standalone: true,
    imports: [TagModule],
    template: `<p-tag [value]="info().label" [severity]="info().sev" [icon]="info().icon" [rounded]="true" />`
})
export class StateTag {
    state = input<string | undefined>('NEVER_SEEN');

    info = computed(() => {
        switch (this.state()) {
            case 'ONLINE':
                return { label: 'Online', sev: 'success' as const, icon: 'pi pi-wifi' };
            case 'OFFLINE':
                return { label: 'Offline', sev: 'danger' as const, icon: 'pi pi-times-circle' };
            default:
                return { label: 'Nunca visto', sev: 'secondary' as const, icon: 'pi pi-minus-circle' };
        }
    });
}
