import { Component, inject, signal } from '@angular/core';
import { RouterModule } from '@angular/router';
import { LayoutService } from '@/app/layout/service/layout.service';
import { Logo } from './icons/logo';
import { LandingConfigButton } from './shared/landingconfigbutton';
import { AppConfigurator } from './app.configurator';

@Component({
    selector: 'auth-layout',
    standalone: true,
    imports: [RouterModule, Logo, LandingConfigButton, AppConfigurator],
    template: `
        <landing-config-button />
        <app-configurator location="auth" />
        <div class="overflow-hidden bg-surface-50 dark:bg-surface-950 w-full min-h-screen">
            <div class="landing-container min-h-screen flex flex-col gap-20 justify-between">
                <!-- Header -->
                <div class="flex items-end gap-16 mb-12">
                    <div class="flex-1 relative">
                        <svg class="absolute right-0 bottom-0 [&_stop]:[stop-color:var(--p-surface-200)] dark:[&_stop]:[stop-color:var(--p-surface-800)]" width="634" height="132" viewBox="0 0 634 132" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path
                                d="M633.667 129C633.667 130.473 632.473 131.667 631 131.667C629.527 131.667 628.333 130.473 628.333 129C628.333 127.527 629.527 126.333 631 126.333C632.473 126.333 633.667 127.527 633.667 129ZM-228.095 -136.574C-228.33 -136.718 -228.404 -137.026 -228.26 -137.262C-228.115 -137.497 -227.807 -137.571 -227.572 -137.426L-228.095 -136.574ZM199.513 125.451L199.774 125.025L199.513 125.451ZM631 129.5H212.072V128.5H631V129.5ZM199.251 125.877L-228.095 -136.574L-227.572 -137.426L199.774 125.025L199.251 125.877ZM212.072 129.5C207.546 129.5 203.108 128.246 199.251 125.877L199.774 125.025C203.474 127.297 207.731 128.5 212.072 128.5V129.5Z"
                                fill="url(#paint0_linear_101_3698)"
                            />
                            <defs>
                                <linearGradient id="paint0_linear_101_3698" x1="-227.833" y1="-3.99999" x2="631" y2="-3.99999" gradientUnits="userSpaceOnUse">
                                    <stop stop-opacity="0" />
                                    <stop offset="0.095" />
                                </linearGradient>
                            </defs>
                        </svg>
                    </div>
                    <a routerLink="/landing">
                        <div class="translate-y-10 p-2 rounded-full bg-surface-50 dark:bg-surface-950 border">
                            <div
                                class="w-20 h-20 rounded-full flex items-center justify-center bg-surface-0 dark:bg-surface-900 shadow-[0px_129.205px_36.493px_0px_rgba(44,54,87,0.00),_0px_82.849px_33.534px_0px_rgba(44,54,87,0.01),_0px_46.356px_27.616px_0px_rgba(44,54,87,0.05),_0px_20.712px_20.712px_0px_rgba(44,54,87,0.09),_0px_4.932px_11.836px_0px_rgba(44,54,87,0.10)]"
                            >
                                <logo />
                            </div>
                        </div>
                    </a>
                    <div class="flex-1 relative">
                        <svg class="absolute left-0 bottom-0 [&_stop]:[stop-color:var(--p-surface-200)] dark:[&_stop]:[stop-color:var(--p-surface-800)]" xmlns="http://www.w3.org/2000/svg" width="634" height="130" viewBox="0 0 634 130" fill="none">
                            <path
                                d="M0.333333 127C0.333333 128.473 1.52724 129.667 3 129.667C4.47276 129.667 5.66667 128.473 5.66667 127C5.66667 125.527 4.47276 124.333 3 124.333C1.52724 124.333 0.333333 125.527 0.333333 127ZM862.095 -138.574C862.33 -138.718 862.404 -139.026 862.26 -139.262C862.115 -139.497 861.807 -139.571 861.572 -139.426L862.095 -138.574ZM434.487 123.451L434.226 123.025L434.487 123.451ZM3 127.5H421.928V126.5H3V127.5ZM434.749 123.877L862.095 -138.574L861.572 -139.426L434.226 123.025L434.749 123.877ZM421.928 127.5C426.454 127.5 430.892 126.246 434.749 123.877L434.226 123.025C430.526 125.297 426.269 126.5 421.928 126.5V127.5Z"
                                fill="url(#paint0_linear_6688_24071)"
                            />
                            <defs>
                                <linearGradient id="paint0_linear_6688_24071" x1="861.833" y1="-5.99999" x2="3" y2="-5.99999" gradientUnits="userSpaceOnUse">
                                    <stop stop-opacity="0" />
                                    <stop offset="0.095" />
                                </linearGradient>
                            </defs>
                        </svg>
                    </div>
                </div>

                <!-- Content -->
                <div>
                    <router-outlet />
                </div>

                <!-- Footer -->
                <div class="flex items-end gap-12">
                    <div class="flex-1 relative">
                        <svg class="absolute right-0 bottom-0 [&_stop]:[stop-color:var(--p-surface-200)] dark:[&_stop]:[stop-color:var(--p-surface-800)]" width="583" height="137" viewBox="0 0 583 137" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path
                                d="M582.167 3C582.167 1.52724 580.973 0.333333 579.5 0.333333C578.027 0.333333 576.833 1.52724 576.833 3C576.833 4.47276 578.027 5.66667 579.5 5.66667C580.973 5.66667 582.167 4.47276 582.167 3ZM-209.326 314.621C-209.535 314.801 -209.559 315.117 -209.379 315.326C-209.199 315.535 -208.883 315.559 -208.674 315.379L-209.326 314.621ZM147.043 8.80355L147.369 9.18264L147.043 8.80355ZM579.5 2.5H162.692V3.5H579.5V2.5ZM146.717 8.42445L-209.326 314.621L-208.674 315.379L147.369 9.18264L146.717 8.42445ZM162.692 2.5C156.829 2.5 151.161 4.60202 146.717 8.42445L147.369 9.18264C151.632 5.51622 157.069 3.5 162.692 3.5V2.5Z"
                                fill="url(#paint0_linear_101_3681)"
                            />
                            <defs>
                                <linearGradient id="paint0_linear_101_3681" x1="-209" y1="159" x2="579.5" y2="159" gradientUnits="userSpaceOnUse">
                                    <stop stop-opacity="0" />
                                    <stop offset="0.095" />
                                </linearGradient>
                            </defs>
                        </svg>
                    </div>

                    <div class="pb-12">
                        <div class="w-fit mx-auto">
                            <div class="rounded-full border p-2 bg-surface-50 dark:bg-surface-950">
                                <div
                                    class="rounded-full flex items-center gap-2 p-2 bg-surface-0 dark:bg-surface-900 shadow-[0px_28px_8px_0px_rgba(44,54,87,0.00),_0px_18px_7px_0px_rgba(44,54,87,0.01),_0px_10px_6px_0px_rgba(44,54,87,0.02),_0px_4px_4px_0px_rgba(44,54,87,0.03),_0px_1px_2px_0px_rgba(44,54,87,0.04)]"
                                >
                                    @for (item of socialLinks(); track item.icon) {
                                        <a [href]="item.href" target="_blank">
                                            <button class="px-4 py-2 text-surface-950 dark:text-surface-0 hover:opacity-50 transition-opacity">
                                                <i [class]="item.icon" class="!leading-none"></i>
                                            </button>
                                        </a>
                                    }
                                </div>
                            </div>
                        </div>
                        <div class="w-fit mx-auto mt-10">
                            <p class="text-surface-500">&copy; {{ currentYear }} PrimeTek</p>
                        </div>
                    </div>

                    <div class="flex-1 relative">
                        <svg class="absolute left-0 bottom-0 [&_stop]:[stop-color:var(--p-surface-200)] dark:[&_stop]:[stop-color:var(--p-surface-800)]" width="584" height="137" viewBox="0 0 584 137" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path
                                d="M0.333333 3C0.333333 1.52724 1.52724 0.333333 3 0.333333C4.47276 0.333333 5.66667 1.52724 5.66667 3C5.66667 4.47276 4.47276 5.66667 3 5.66667C1.52724 5.66667 0.333333 4.47276 0.333333 3ZM791.826 314.621C792.035 314.801 792.059 315.117 791.879 315.326C791.699 315.535 791.383 315.559 791.174 315.379L791.826 314.621ZM435.457 8.80355L435.131 9.18264L435.457 8.80355ZM3 2.5H419.808V3.5H3V2.5ZM435.783 8.42445L791.826 314.621L791.174 315.379L435.131 9.18264L435.783 8.42445ZM419.808 2.5C425.671 2.5 431.339 4.60202 435.783 8.42445L435.131 9.18264C430.868 5.51622 425.431 3.5 419.808 3.5V2.5Z"
                                fill="url(#paint0_linear_101_3680)"
                            />
                            <defs>
                                <linearGradient id="paint0_linear_101_3680" x1="791.5" y1="159" x2="3" y2="159" gradientUnits="userSpaceOnUse">
                                    <stop stop-opacity="0" />
                                    <stop offset="0.095" />
                                </linearGradient>
                            </defs>
                        </svg>
                    </div>
                </div>
            </div>
        </div>
    `
})
export class AuthLayout {
    layoutService = inject(LayoutService);

    currentYear = new Date().getFullYear();

    socialLinks = signal([
        {
            icon: 'pi pi-youtube',
            href: 'https://www.youtube.com'
        },
        {
            icon: 'pi pi-twitter',
            href: 'https://www.twitter.com'
        },
        {
            icon: 'pi pi-discord',
            href: 'https://www.discord.com'
        }
    ]);
}
