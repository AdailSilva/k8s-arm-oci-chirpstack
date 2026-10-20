import { Component, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { PasswordModule } from 'primeng/password';
import { MessageModule } from 'primeng/message';
import { AuthService, MENSAGENS_ENCERRAMENTO } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { LandingInput } from '@/app/layout/components/shared/landinginput';
import { LandingPassword } from '@/app/layout/components/shared/landingpassword';

/**
 * Login do ChirpStack Manager (layout do tema Avalon).
 */
@Component({
    selector: 'app-login',
    standalone: true,
    imports: [FormsModule, RouterModule, PasswordModule, MessageModule, LandingInput, LandingPassword],
    template: `
        <div>
            <div class="w-fit mx-auto mb-6 flex items-center gap-2 px-4 py-2 rounded-full border bg-surface-0 dark:bg-surface-900 text-sm text-surface-600 dark:text-surface-300">
                <i class="pi pi-wifi text-primary"></i>
                <span>Administração da rede LoRaWAN</span>
            </div>
            <h1 class="text-4xl md:text-5xl font-medium text-center mx-auto leading-[125%]">
                Bem-vindo ao<br />
                ChirpStack Manager
            </h1>
            <p class="text-lg text-surface-500 leading-6 mt-6 text-center mx-auto">Entre com seu e-mail e senha</p>
            <form class="max-w-[35rem] mx-auto" (ngSubmit)="entrar()" autocomplete="on">
                <div class="space-y-4 mt-12">
                    @if (aviso()) {
                        <p-message severity="warn" [text]="aviso()" styleClass="w-full" />
                    }
                    @if (erro()) {
                        <p-message severity="error" [text]="erro()" styleClass="w-full" />
                    }
                    <landing-input type="email" placeholder="E-mail" [(value)]="email" />
                    <landing-password placeholder="Senha" [(value)]="senha" />
                </div>
                <div class="space-y-8 mt-8">
                    <button type="submit" class="landing-button-primary w-full disabled:opacity-60" [disabled]="carregando()">
                        @if (carregando()) {
                            <i class="pi pi-spin pi-spinner mr-2"></i>Entrando...
                        } @else {
                            Entrar
                        }
                    </button>
                    <div class="text-surface-500 text-center leading-6 text-sm">
                        <i class="pi pi-lock mr-1"></i>Acesso restrito. Esqueceu a senha? Fale com um administrador do sistema.
                    </div>
                </div>
            </form>
        </div>
    `
})
export class Login implements OnInit {
    private auth = inject(AuthService);
    private router = inject(Router);
    private route = inject(ActivatedRoute);

    email = signal('');
    senha = signal('');
    carregando = signal(false);
    erro = signal('');
    aviso = signal('');

    ngOnInit(): void {
        const motivo = this.route.snapshot.queryParamMap.get('motivo') ?? this.auth.ultimoMotivo();
        if (motivo && MENSAGENS_ENCERRAMENTO[motivo]) {
            this.aviso.set(MENSAGENS_ENCERRAMENTO[motivo]);
        } else if (this.route.snapshot.queryParamMap.get('expirada')) {
            this.aviso.set('Sua sessão expirou. Entre novamente.');
        }
    }

    entrar(): void {
        this.erro.set('');
        const email = this.email().trim();
        if (!email || !this.senha()) {
            this.erro.set('Informe o e-mail e a senha.');
            return;
        }
        this.carregando.set(true);
        this.auth.login(email, this.senha()).subscribe({
            next: () => {
                const destino = this.route.snapshot.queryParamMap.get('returnUrl') || '/painel';
                this.router.navigateByUrl(destino.startsWith('/') && !destino.startsWith('//') ? destino : '/painel');
            },
            error: (e) => {
                this.carregando.set(false);
                this.senha.set('');
                this.erro.set(NotifyService.mensagem(e));
            }
        });
    }
}
