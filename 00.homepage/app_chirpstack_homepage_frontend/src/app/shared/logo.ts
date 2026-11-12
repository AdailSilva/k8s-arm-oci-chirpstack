import { Component, input } from '@angular/core';

let seq = 0;

/** Marca do site: antena LoRa (ondas de rádio) sobre bloco com gradiente da cor primária. */
@Component({
    selector: 'site-logo',
    standalone: true,
    template: `
        <span class="inline-flex items-center gap-2.5">
            <svg [attr.width]="tamanho()" [attr.height]="tamanho()" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                <defs>
                    <linearGradient [attr.id]="gradId" x1="0" y1="0" x2="40" y2="40" gradientUnits="userSpaceOnUse">
                        <stop offset="0" stop-color="var(--p-primary-400)" />
                        <stop offset="1" stop-color="var(--p-primary-700)" />
                    </linearGradient>
                </defs>
                <rect width="40" height="40" rx="12" [attr.fill]="'url(#' + gradId + ')'" />
                <path d="M20 21V31" stroke="white" stroke-width="3" stroke-linecap="round" />
                <circle cx="20" cy="18" r="3" fill="white" />
                <path d="M14.3 12.3A8 8 0 0 0 14.3 23.7M25.7 12.3A8 8 0 0 1 25.7 23.7" stroke="white" stroke-opacity="0.85" stroke-width="2.4" stroke-linecap="round" />
                <path d="M10.4 8.4A13.5 13.5 0 0 0 10.4 27.6M29.6 8.4A13.5 13.5 0 0 1 29.6 27.6" stroke="white" stroke-opacity="0.5" stroke-width="2.4" stroke-linecap="round" />
            </svg>
            @if (comTexto()) {
                <span class="leading-none">
                    <span class="block font-semibold tracking-tight text-surface-950 dark:text-surface-0">ChirpStack</span>
                    <span class="block text-[11px] text-surface-500 mt-0.5 tracking-wide">na OCI Always Free</span>
                </span>
            }
        </span>
    `
})
export class SiteLogo {
    /** id único por instância: com ids repetidos, o gradiente some quando a 1ª instância está oculta (display:none). */
    readonly gradId = `logo-grad-${++seq}`;
    tamanho = input<number>(34);
    comTexto = input<boolean>(false);
}
