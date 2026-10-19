import { Component } from '@angular/core';

/** Logotipo do ChirpStack Manager: torre de rádio com ondas. */
@Component({
    selector: 'logo',
    standalone: true,
    template: `
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" aria-hidden="true">
            <rect width="32" height="32" rx="8" class="fill-primary" />
            <g fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M11.6 7.6a6.2 6.2 0 0 0 0 8.8M20.4 7.6a6.2 6.2 0 0 1 0 8.8" />
                <path d="M7.9 4.2a11 11 0 0 0 0 15.6M24.1 4.2a11 11 0 0 1 0 15.6" opacity=".7" />
                <path d="M12.4 27.5 16 14.5l3.6 13M13.5 23.5h5" />
            </g>
            <circle cx="16" cy="12" r="2.5" fill="#fff" />
        </svg>
    `
})
export class Logo {}
