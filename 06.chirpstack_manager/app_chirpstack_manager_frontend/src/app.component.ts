import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import { ToastModule } from 'primeng/toast';
import { ConfirmDialogModule } from 'primeng/confirmdialog';

@Component({
    selector: 'app-root',
    standalone: true,
    imports: [RouterModule, ToastModule, ConfirmDialogModule],
    template: `
        <p-toast position="top-right" />
        <p-confirmdialog [style]="{ width: '30rem' }" />
        <router-outlet></router-outlet>
    `
})
export class AppComponent {}
