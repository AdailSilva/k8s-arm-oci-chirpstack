import { Component, inject } from '@angular/core';
import { Meta } from '@angular/platform-browser';
import { RouterModule } from '@angular/router';
import { environment } from './environments/environment';

@Component({
    selector: 'app-root',
    standalone: true,
    imports: [RouterModule],
    template: `<router-outlet></router-outlet>`
})
export class AppComponent {
    constructor() {
        // development/staging não devem aparecer nos buscadores.
        if (!environment.indexar) {
            inject(Meta).updateTag({ name: 'robots', content: 'noindex, nofollow' });
        }
    }
}
