import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { TooltipModule } from 'primeng/tooltip';
import { Navbar } from './navbar';
import { Footer } from './footer';
import { CONTATOS } from '@/app/core/site.config';
import { linkWhatsapp } from '@/app/core/contato.util';

@Component({
    selector: 'site-layout',
    standalone: true,
    imports: [RouterOutlet, Navbar, Footer, TooltipModule],
    template: `
        <div class="w-full min-h-screen overflow-x-clip">
            <header navbar></header>
            <main>
                <router-outlet />
            </main>
            <footer footer></footer>

            @if (whatsapp) {
                <a
                    [href]="whatsapp"
                    target="_blank"
                    rel="noopener"
                    pTooltip="Conversar no WhatsApp"
                    tooltipPosition="left"
                    aria-label="Conversar no WhatsApp"
                    class="fixed right-5 bottom-5 z-40 w-14 h-14 rounded-full flex items-center justify-center bg-[#25D366] text-white shadow-[0_10px_30px_-5px_rgba(37,211,102,0.55)] hover:scale-105 transition-transform"
                >
                    <i class="pi pi-whatsapp text-2xl!"></i>
                </a>
            }
        </div>
    `
})
export class SiteLayout {
    readonly whatsapp = CONTATOS.whatsapp ? linkWhatsapp('Olá, Adail! Vim pelo site do ChirpStack na OCI Always Free e gostaria de conversar sobre LoRaWAN.') : '';
}
