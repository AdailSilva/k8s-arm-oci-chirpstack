import { Component, inject, OnInit, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { MessageModule } from 'primeng/message';
import { PasswordModule } from 'primeng/password';
import { TagModule } from 'primeng/tag';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { BackupService, GoogleDriveForm } from '@/app/pages/backup/backup.service';
import { GoogleDriveConfig } from '@/app/core/http/models';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora } from '@/app/core/format/format';
import { CopyButton } from '@/app/shared/campos/copy-button';

/**
 * Conexão com o Google Drive (OAuth 2.0, escopo drive.file) e regras de envio dos backups.
 */
@Component({
    selector: 'app-backup-google-drive',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, InputNumberModule, InputTextModule, MessageModule, PasswordModule, TagModule, ToggleSwitchModule, CopyButton],
    template: `
        @if (cfg(); as c) {
            <div class="grid grid-cols-1 xl:grid-cols-12 gap-6">
                <div class="xl:col-span-7 flex flex-col gap-6">
                    <!-- Situação da conexão -->
                    <div class="border rounded-2xl p-5">
                        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
                            <div class="flex items-center gap-4">
                                <div class="w-12 h-12 rounded-2xl flex items-center justify-center" [ngClass]="c.conectado ? 'bg-green-50 text-green-600 dark:bg-green-900/30 dark:text-green-300' : 'bg-surface-100 text-surface-500 dark:bg-surface-800'">
                                    <i class="pi pi-google text-xl!"></i>
                                </div>
                                <div>
                                    @if (c.conectado) {
                                        <div class="font-semibold text-lg">Conectado</div>
                                        <div class="text-sm text-surface-500">{{ c.contaNome ? c.contaNome + ' · ' : '' }}{{ c.contaEmail }}</div>
                                        <div class="text-xs text-surface-500">desde {{ data(c.conectadoEm) }}{{ c.conectadoPor ? ' por ' + c.conectadoPor : '' }}</div>
                                    } @else {
                                        <div class="font-semibold text-lg">Nenhuma conta conectada</div>
                                        <div class="text-sm text-surface-500">Cadastre as credenciais do cliente OAuth e conecte a conta que vai receber os backups.</div>
                                    }
                                </div>
                            </div>
                            <div class="flex flex-wrap gap-2">
                                @if (c.conectado) {
                                    <p-button label="Testar envio" icon="pi pi-cloud-upload" [outlined]="true" severity="secondary" (onClick)="testar()" [loading]="testando()" />
                                    <p-button label="Reconectar" icon="pi pi-refresh" [text]="true" (onClick)="conectar()" [loading]="conectando()" />
                                    <p-button label="Desconectar" icon="pi pi-sign-out" [text]="true" severity="danger" (onClick)="desconectar()" />
                                } @else {
                                    <p-button label="Conectar conta Google" icon="pi pi-google" (onClick)="conectar()" [loading]="conectando()" [disabled]="!c.credenciaisDefinidas" />
                                }
                            </div>
                        </div>
                        @if (c.pastaLink) {
                            <a [href]="c.pastaLink" target="_blank" rel="noopener noreferrer" class="inline-flex items-center gap-2 mt-4 text-primary font-medium no-underline hover:underline"><i class="pi pi-folder-open"></i>Abrir a pasta "{{ c.pastaNome }}" no Drive</a>
                        }
                        @if (c.erroConexao) {
                            <p-message severity="error" [text]="c.erroConexao" styleClass="w-full mt-4" />
                        }
                        @if (c.ultimoEnvioEm) {
                            <div class="flex items-start gap-2 mt-4 text-sm">
                                <i class="pi mt-0.5" [ngClass]="c.ultimoEnvioStatus === 'SUCESSO' ? 'pi-check-circle text-green-500' : 'pi-times-circle text-red-500'"></i>
                                <span><b>Último envio</b> em {{ data(c.ultimoEnvioEm) }}: {{ c.ultimoEnvioMensagem }}</span>
                            </div>
                        }
                    </div>

                    <!-- Regras de envio -->
                    <div class="border rounded-2xl p-5">
                        <div class="font-semibold text-lg mb-4">Pasta e retenção</div>
                        <div class="flex flex-col gap-5">
                            <div>
                                <label class="block font-medium mb-2">Pasta no Drive</label>
                                <input pInputText class="w-full" [(ngModel)]="form.pastaNome" maxlength="200" placeholder="ChirpStack Manager/Backups" />
                                <small class="text-surface-500">Use "/" para criar níveis. O sistema cria a pasta se ela não existir.</small>
                            </div>
                            <label class="flex items-center gap-3 cursor-pointer">
                                <p-toggleswitch [(ngModel)]="form.enviarManuais" />
                                <span>Marcar "Enviar ao Google Drive" por padrão nos backups gerados pela tela</span>
                            </label>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label class="block font-medium mb-2 text-sm">Apagar do Drive após</label>
                                    <p-inputnumber [(ngModel)]="form.retencaoDias" [min]="0" [max]="3650" suffix=" dias" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                                    <small class="text-surface-500">0 = nunca apagar</small>
                                </div>
                                <div>
                                    <label class="block font-medium mb-2 text-sm">Manter no mínimo</label>
                                    <p-inputnumber [(ngModel)]="form.manterMinimo" [min]="1" [max]="100" suffix=" por formato" [showButtons]="true" inputStyleClass="w-full" styleClass="w-full" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Credenciais -->
                    <div class="border rounded-2xl p-5">
                        <div class="flex items-center justify-between mb-4">
                            <div class="font-semibold text-lg">Cliente OAuth do Google Cloud</div>
                            @if (c.origemCredenciais) {
                                <p-tag [value]="c.origemCredenciais === 'TELA' ? 'Cadastrado aqui' : 'Do ambiente (Secret)'" severity="secondary" [rounded]="true" />
                            }
                        </div>
                        <div class="flex flex-col gap-5">
                            <div>
                                <label class="block font-medium mb-2">Client ID</label>
                                <input pInputText class="w-full font-mono text-sm" [(ngModel)]="form.clientId" placeholder="000000000000-xxxxxxxx.apps.googleusercontent.com" />
                            </div>
                            <div>
                                <label class="block font-medium mb-2">Client Secret</label>
                                <p-password [(ngModel)]="form.clientSecret" [feedback]="false" [toggleMask]="true" styleClass="w-full" inputStyleClass="w-full font-mono text-sm" [placeholder]="c.clientSecretDefinido ? '•••••••• (gravado; preencha só para trocar)' : 'GOCSPX-...'" autocomplete="off" />
                                <small class="text-surface-500">Gravado cifrado (AES-256-GCM). Nunca volta para o navegador.</small>
                            </div>
                            <div>
                                <label class="block font-medium mb-2">URI de redirecionamento autorizado</label>
                                <div class="flex items-center gap-2">
                                    <input pInputText class="w-full font-mono text-sm" [value]="c.redirectUri" readonly />
                                    <app-copy-button [value]="c.redirectUri" />
                                </div>
                                <small class="text-surface-500">Cadastre exatamente este endereço no cliente OAuth (definido por GOOGLE_DRIVE_REDIRECT_URI).</small>
                            </div>
                        </div>
                        @if (!c.chaveCifragemDedicada) {
                            <p-message severity="warn" icon="pi pi-key" text="APP_CHAVE_CIFRAGEM não está definida: a chave dos segredos é derivada do segredo do JWT. Se ele mudar, será preciso reconectar a conta." styleClass="w-full mt-4" />
                        }
                    </div>

                    <div class="flex justify-end gap-2">
                        <p-button label="Descartar" icon="pi pi-undo" [text]="true" severity="secondary" (onClick)="carregar()" />
                        <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
                    </div>
                </div>

                <div class="xl:col-span-5">
                    <div class="border rounded-2xl p-5">
                        <div class="font-semibold text-lg mb-3">Como configurar</div>
                        <ol class="m-0 pl-5 text-sm text-surface-600 dark:text-surface-300 flex flex-col gap-2 list-decimal">
                            <li>No <a href="https://console.cloud.google.com/" target="_blank" rel="noopener noreferrer" class="text-primary">Google Cloud Console</a>, crie (ou escolha) um projeto.</li>
                            <li>Em <b>APIs e serviços → Biblioteca</b>, ative a <b>Google Drive API</b>.</li>
                            <li>Em <b>Tela de permissão OAuth</b>, configure o app como <i>Externo</i> e <b>publique</b> ("Em produção"). Em modo Teste, o Google invalida a autorização a cada 7 dias.</li>
                            <li>Em <b>Credenciais → Criar credenciais → ID do cliente OAuth</b>, escolha <i>Aplicativo da Web</i> e cadastre o URI de redirecionamento mostrado ao lado.</li>
                            <li>Copie o Client ID e o Client Secret para esta tela e salve.</li>
                            <li>Clique em <b>Conectar conta Google</b>, escolha a conta e autorize.</li>
                        </ol>
                        <p-message severity="info" icon="pi pi-shield" styleClass="w-full mt-4">
                            <span class="text-sm">O sistema pede o escopo <b>drive.file</b>: só enxerga e altera os arquivos que ele mesmo criou. O restante do Drive da conta continua inacessível.</span>
                        </p-message>
                    </div>
                </div>
            </div>
        }
    `
})
export class BackupGoogleDrivePainel implements OnInit {
    private api = inject(BackupService);
    private notify = inject(NotifyService);
    private route = inject(ActivatedRoute);
    private router = inject(Router);

    alterado = output<void>();

    cfg = signal<GoogleDriveConfig | null>(null);
    salvando = signal(false);
    conectando = signal(false);
    testando = signal(false);
    form: GoogleDriveForm = {};
    data = dataHora;

    ngOnInit(): void {
        // Retorno do consentimento do Google (?drive=conectado|erro&mensagem=...)
        const q = this.route.snapshot.queryParamMap;
        const situacao = q.get('drive');
        if (situacao) {
            const msg = q.get('mensagem') ?? '';
            if (situacao === 'conectado') {
                this.notify.sucesso(`Google Drive conectado${msg ? ' à conta ' + msg : ''}.`);
                this.alterado.emit();
            } else {
                this.notify.erro(new Error(msg || 'Não foi possível conectar.'), 'Google Drive');
            }
            this.router.navigate([], { relativeTo: this.route, queryParams: { aba: 'drive' }, replaceUrl: true });
        }
        this.carregar();
    }

    carregar(): void {
        this.api.drive().subscribe({ next: (c) => this.aplicar(c), error: (e) => this.notify.erro(e) });
    }

    salvar(): void {
        this.salvando.set(true);
        const envio: GoogleDriveForm = { ...this.form };
        if (!envio.clientSecret) {
            delete envio.clientSecret;
        }
        this.api.salvarDrive(envio).subscribe({
            next: (c) => {
                this.salvando.set(false);
                this.aplicar(c);
                this.notify.sucesso('Configuração do Google Drive salva.');
                this.alterado.emit();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    conectar(): void {
        this.conectando.set(true);
        this.api.autorizarDrive().subscribe({
            next: (r) => (window.location.href = r.url),
            error: (e) => {
                this.conectando.set(false);
                this.notify.erro(e);
            }
        });
    }

    desconectar(): void {
        this.notify.confirmar('Desconectar Google Drive', 'Revogar a autorização desta conta? Os backups já enviados continuam no Drive; novos envios param até conectar de novo.', () =>
            this.api.desconectarDrive().subscribe({
                next: (c) => {
                    this.aplicar(c);
                    this.notify.sucesso('Conta Google desconectada.');
                    this.alterado.emit();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Desconectar'
        );
    }

    testar(): void {
        this.testando.set(true);
        this.api.testarDrive().subscribe({
            next: (r) => {
                this.testando.set(false);
                if (r.sucesso) {
                    this.notify.sucesso(r.mensagem, 'Google Drive');
                } else {
                    this.notify.erro(new Error(r.mensagem), 'Google Drive');
                }
                this.carregar();
            },
            error: (e) => {
                this.testando.set(false);
                this.notify.erro(e);
            }
        });
    }

    private aplicar(c: GoogleDriveConfig): void {
        this.form = {
            clientId: c.origemCredenciais === 'TELA' ? (c.clientId ?? '') : '',
            clientSecret: '',
            pastaNome: c.pastaNome,
            enviarManuais: c.enviarManuais,
            retencaoDias: c.retencaoDias,
            manterMinimo: c.manterMinimo
        };
        this.cfg.set(c);
    }
}
