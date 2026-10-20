import { Component, computed, DestroyRef, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { CheckboxModule } from 'primeng/checkbox';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { MessageModule } from 'primeng/message';
import { ProgressBarModule } from 'primeng/progressbar';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TabsModule } from 'primeng/tabs';
import { TagModule } from 'primeng/tag';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { TooltipModule } from 'primeng/tooltip';
import { BackupService } from '@/app/pages/backup/backup.service';
import { ArquivoBackup, BackupJob, BackupVisaoGeral } from '@/app/core/http/models';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { dataHora } from '@/app/core/format/format';
import { PageHeader } from '@/app/shared/visual/page-header';
import { BackupAgendamentoPainel } from './backup-agendamento';
import { BackupGoogleDrivePainel } from './backup-google-drive';
import { corStatus, duracaoJob, ROTULO_ORIGEM, ROTULO_STATUS, tamanho } from './backup-util';

type Aba = 'backup' | 'restaurar' | 'agendamento' | 'drive' | 'historico';

const DESCRICAO_FORMATO: Record<string, string> = {
    backup: 'Formato custom do pg_dump: compactado e de restauração mais rápida. Recomendado.',
    sql: 'Texto SQL legível, útil para conferência ou para migrar para outro servidor.'
};

/**
 * Backup e restauração do banco do painel: gerar, baixar, restaurar, backup automático
 * (agendamento) e envio ao Google Drive. Somente ADMIN.
 */
@Component({
    selector: 'app-backup',
    standalone: true,
    imports: [
        CommonModule,
        FormsModule,
        ButtonModule,
        CheckboxModule,
        DialogModule,
        InputTextModule,
        MessageModule,
        ProgressBarModule,
        SelectModule,
        TableModule,
        TabsModule,
        TagModule,
        ToggleSwitchModule,
        TooltipModule,
        PageHeader,
        BackupAgendamentoPainel,
        BackupGoogleDrivePainel
    ],
    template: `
        <app-page-header title="Backup & Restauração" subtitle="Cópias do banco do painel: usuários, sessões, auditoria e configurações" icon="pi pi-database">
            <p-button icon="pi pi-refresh" label="Atualizar" severity="secondary" [outlined]="true" (onClick)="carregar()" [loading]="carregando()" />
        </app-page-header>

        @if (job(); as j) {
            <div class="card mb-6! border-l-4!" [ngClass]="j.emAndamento ? 'border-l-primary!' : j.status === 'SUCESSO' ? 'border-l-green-500!' : j.status === 'ERRO' ? 'border-l-red-500!' : 'border-l-amber-500!'">
                <div class="flex flex-col md:flex-row md:items-center justify-between gap-3 mb-3">
                    <div class="flex items-center gap-3">
                        <i class="text-2xl!" [ngClass]="j.emAndamento ? 'pi pi-spin pi-spinner text-primary' : j.status === 'SUCESSO' ? 'pi pi-check-circle text-green-500' : j.status === 'ERRO' ? 'pi pi-times-circle text-red-500' : 'pi pi-exclamation-triangle text-amber-500'"></i>
                        <div>
                            <div class="font-semibold">{{ j.tipo === 'BACKUP' ? 'Backup' : 'Restauração' }} · {{ rotuloStatus[j.status] }}</div>
                            <div class="text-sm text-surface-500">{{ j.mensagem }}</div>
                        </div>
                    </div>
                    <div class="flex items-center gap-2">
                        @if (!j.emAndamento) {
                            <p-button icon="pi pi-times" [text]="true" [rounded]="true" severity="secondary" (onClick)="job.set(null)" pTooltip="Fechar" />
                        }
                    </div>
                </div>
                <p-progressbar [value]="j.progresso" [showValue]="true" styleClass="h-4!" />
                @if (j.erro) {
                    <p-message severity="error" [text]="j.erro" styleClass="w-full mt-3" />
                }
                @if (j.driveMensagem) {
                    <p-message [severity]="j.driveStatus === 'SUCESSO' ? 'success' : 'warn'" icon="pi pi-google" [text]="'Google Drive: ' + j.driveMensagem" styleClass="w-full mt-3" />
                }
                @if (!j.emAndamento && j.arquivos.length) {
                    <div class="flex flex-wrap gap-2 mt-3">
                        @for (a of j.arquivos; track a) {
                            <p-tag [value]="a" icon="pi pi-file" severity="secondary" />
                        }
                        @if (j.tamanhoBytes) {
                            <span class="text-sm text-surface-500 self-center">{{ tam(j.tamanhoBytes) }}</span>
                        }
                    </div>
                }
            </div>
        }

        <div class="card">
            <p-tabs [value]="aba()" (valueChange)="trocarAba($any($event))">
                <p-tablist>
                    <p-tab value="backup"><i class="pi pi-download mr-2"></i>Backup</p-tab>
                    <p-tab value="restaurar"><i class="pi pi-upload mr-2"></i>Restaurar</p-tab>
                    <p-tab value="agendamento"><i class="pi pi-calendar-clock mr-2"></i>Agendamento</p-tab>
                    <p-tab value="drive"><i class="pi pi-google mr-2"></i>Google Drive</p-tab>
                    <p-tab value="historico"><i class="pi pi-history mr-2"></i>Histórico</p-tab>
                </p-tablist>
                <p-tabpanels>
                    <!-- ── Backup ───────────────────────────────────────────── -->
                    <p-tabpanel value="backup">
                        <div class="grid grid-cols-1 xl:grid-cols-12 gap-6 mb-6">
                            <div class="xl:col-span-7 border rounded-2xl p-5">
                                <div class="font-semibold text-lg mb-1">Gerar backup agora</div>
                                <p class="text-surface-500 m-0 mb-4 text-sm">Os arquivos ficam na pasta <b>manuais/</b> do servidor e aparecem na lista abaixo para baixar.</p>
                                <div class="flex flex-col gap-3">
                                    @for (f of visao()?.formatos ?? []; track f) {
                                        <label class="flex items-start gap-3 cursor-pointer p-3 rounded-xl border" [ngClass]="formatos().includes(f) ? 'border-primary bg-primary-50/40 dark:bg-primary-900/10' : ''">
                                            <p-checkbox [binary]="true" [ngModel]="formatos().includes(f)" (ngModelChange)="alternarFormato(f, $event)" />
                                            <span><b>.{{ f }}</b><br /><span class="text-sm text-surface-500">{{ descricao[f] }}</span></span>
                                        </label>
                                    }
                                </div>
                                <label class="flex items-center gap-3 mt-4" [pTooltip]="driveConectado() ? '' : 'Conecte uma conta na aba Google Drive'">
                                    <p-toggleswitch [(ngModel)]="enviarDrive" [disabled]="!driveConectado()" />
                                    <span>Enviar também ao Google Drive</span>
                                </label>
                                <div class="mt-5">
                                    <p-button label="Gerar backup" icon="pi pi-download" (onClick)="gerar()" [loading]="ocupado()" [disabled]="ocupado() || formatos().length === 0" />
                                </div>
                            </div>
                            <div class="xl:col-span-5 border rounded-2xl p-5">
                                <div class="flex items-center justify-between mb-3">
                                    <div class="font-semibold text-lg">Verificação do ambiente</div>
                                    <p-tag [value]="visao()?.motor ?? '...'" severity="secondary" [rounded]="true" />
                                </div>
                                <div class="flex flex-col gap-3">
                                    @for (v of visao()?.verificacoes ?? []; track v.item) {
                                        <div class="flex items-start gap-3">
                                            <i class="mt-0.5" [ngClass]="v.ok ? 'pi pi-check-circle text-green-500' : v.item === 'Google Drive' ? 'pi pi-minus-circle text-surface-400' : 'pi pi-times-circle text-red-500'"></i>
                                            <div class="min-w-0">
                                                <div class="font-medium text-sm">{{ v.item }}</div>
                                                <div class="text-xs text-surface-500 break-all">{{ v.detalhe }}</div>
                                            </div>
                                        </div>
                                    }
                                </div>
                            </div>
                        </div>

                        <p-table [value]="arquivosFiltrados()" [rowHover]="true" styleClass="p-datatable-sm" [paginator]="arquivosFiltrados().length > 15" [rows]="15" [tableStyle]="{ 'min-width': '60rem' }">
                            <ng-template #caption>
                                <div class="flex flex-wrap items-center justify-between gap-2">
                                    <span class="font-semibold">Arquivos no servidor <span class="text-surface-500 font-normal">({{ arquivos().length }} · {{ tam(totalArquivos()) }})</span></span>
                                    <p-select [options]="pastas" optionLabel="label" optionValue="value" [ngModel]="pasta()" (ngModelChange)="pasta.set($event ?? '')" placeholder="Todas as pastas" [showClear]="true" styleClass="w-52" />
                                </div>
                            </ng-template>
                            <ng-template #header>
                                <tr>
                                    <th>Arquivo</th>
                                    <th class="w-36">Pasta</th>
                                    <th class="w-28">Tamanho</th>
                                    <th class="w-44">Data</th>
                                    <th class="w-40 text-right">Ações</th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-a>
                                <tr>
                                    <td class="font-mono text-sm break-all"><i class="pi mr-2" [ngClass]="a.formato === 'sql' ? 'pi-file-edit' : 'pi-box'"></i>{{ a.nome }}</td>
                                    <td><p-tag [value]="rotuloPasta[a.pasta]" [severity]="a.pasta === 'agendados' ? 'info' : a.pasta === 'seguranca' ? 'warn' : 'secondary'" [rounded]="true" /></td>
                                    <td class="text-sm tabular-nums">{{ tam(a.tamanho) }}</td>
                                    <td class="text-sm">{{ data(a.modificadoEm) }}</td>
                                    <td class="text-right whitespace-nowrap">
                                        <p-button icon="pi pi-download" [text]="true" [rounded]="true" (onClick)="baixar(a)" [loading]="baixando() === a.nome" pTooltip="Baixar" tooltipPosition="left" />
                                        <p-button icon="pi pi-replay" [text]="true" [rounded]="true" severity="warn" (onClick)="pedirRestauracaoServidor(a)" [disabled]="ocupado()" pTooltip="Restaurar este backup" tooltipPosition="left" />
                                        <p-button icon="pi pi-trash" [text]="true" [rounded]="true" severity="danger" (onClick)="excluir(a)" pTooltip="Excluir" tooltipPosition="left" />
                                    </td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage>
                                <tr><td colspan="5" class="text-center py-8 text-surface-500">Nenhum arquivo de backup no servidor.</td></tr>
                            </ng-template>
                        </p-table>
                    </p-tabpanel>

                    <!-- ── Restaurar ────────────────────────────────────────── -->
                    <p-tabpanel value="restaurar">
                        <div class="grid grid-cols-1 xl:grid-cols-12 gap-6">
                            <div class="xl:col-span-7 border rounded-2xl p-5">
                                <div class="font-semibold text-lg mb-1">Restaurar a partir de um arquivo</div>
                                <p class="text-surface-500 m-0 mb-4 text-sm">Envie um arquivo {{ extensoes() }} gerado por este sistema. Para restaurar um backup que já está no servidor, use o botão <i class="pi pi-replay"></i> na lista da aba Backup.</p>
                                <label class="flex flex-col items-center justify-center gap-2 border-2 border-dashed rounded-2xl p-8 cursor-pointer hover:border-primary transition-colors" [ngClass]="arquivo() ? 'border-primary bg-primary-50/40 dark:bg-primary-900/10' : 'border-surface-300 dark:border-surface-700'">
                                    <i class="pi pi-cloud-upload text-4xl! text-primary"></i>
                                    @if (arquivo(); as f) {
                                        <span class="font-medium break-all text-center">{{ f.name }}</span>
                                        <span class="text-sm text-surface-500">{{ tam(f.size) }}</span>
                                    } @else {
                                        <span class="font-medium">Clique para escolher o arquivo</span>
                                        <span class="text-sm text-surface-500">{{ extensoes() }}</span>
                                    }
                                    <input type="file" class="hidden" [accept]="aceitar()" (change)="escolher($event)" />
                                </label>
                                <label class="flex items-center gap-3 mt-4 cursor-pointer">
                                    <p-checkbox [(ngModel)]="backupSeguranca" [binary]="true" />
                                    <span>Gerar um backup de segurança do banco atual antes (pasta <b>seguranca/</b>)</span>
                                </label>
                                <div class="mt-5">
                                    <p-button label="Restaurar" icon="pi pi-upload" severity="danger" (onClick)="pedirRestauracaoUpload()" [disabled]="!arquivo() || ocupado()" />
                                </div>
                            </div>
                            <div class="xl:col-span-5">
                                <p-message severity="error" icon="pi pi-exclamation-triangle" styleClass="w-full">
                                    <div>
                                        <div class="font-semibold mb-1">Atenção</div>
                                        <ul class="m-0 pl-4 text-sm list-disc flex flex-col gap-1">
                                            <li>Todos os dados do painel são substituídos pelos do arquivo (usuários, sessões, auditoria e configurações).</li>
                                            <li>A restauração roda em transação única: se falhar, o banco fica como estava.</li>
                                            <li>Ao terminar, <b>todos os usuários são desconectados</b>, inclusive você.</li>
                                            <li>A conexão atual com o Google Drive é mantida.</li>
                                            <li>Os dados do ChirpStack (aplicações, dispositivos, gateways) não são afetados: eles ficam no próprio ChirpStack.</li>
                                        </ul>
                                    </div>
                                </p-message>
                            </div>
                        </div>
                    </p-tabpanel>

                    <!-- ── Agendamento ──────────────────────────────────────── -->
                    <p-tabpanel value="agendamento">
                        @if (aba() === 'agendamento') {
                            <app-backup-agendamento [formatosDisponiveis]="visao()?.formatos ?? []" (iniciado)="acompanhar($event)" />
                        }
                    </p-tabpanel>

                    <!-- ── Google Drive ─────────────────────────────────────── -->
                    <p-tabpanel value="drive">
                        @if (aba() === 'drive') {
                            <app-backup-google-drive (alterado)="carregar()" />
                        }
                    </p-tabpanel>

                    <!-- ── Histórico ────────────────────────────────────────── -->
                    <p-tabpanel value="historico">
                        <p-table [value]="historico()" [rowHover]="true" styleClass="p-datatable-sm" [paginator]="historico().length > 20" [rows]="20" [tableStyle]="{ 'min-width': '78rem' }" dataKey="id">
                            <ng-template #header>
                                <tr>
                                    <th class="w-44">Data</th>
                                    <th class="w-32">Operação</th>
                                    <th class="w-32">Origem</th>
                                    <th class="w-32">Situação</th>
                                    <th class="w-24">Duração</th>
                                    <th>Arquivos</th>
                                    <th class="w-28">Google Drive</th>
                                    <th>Mensagem</th>
                                    <th class="w-40">Por</th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-j>
                                <tr>
                                    <td class="text-sm">{{ data(j.agendadoPara || j.criadoEm) }}</td>
                                    <td><i class="pi mr-2" [ngClass]="j.tipo === 'BACKUP' ? 'pi-download' : 'pi-upload'"></i>{{ j.tipo === 'BACKUP' ? 'Backup' : 'Restauração' }}</td>
                                    <td class="text-sm">{{ rotuloOrigem[j.origem] }}</td>
                                    <td><p-tag [value]="rotuloStatus[j.status]" [severity]="cor(j.status)" [rounded]="true" /></td>
                                    <td class="text-sm tabular-nums">{{ duracao(j) }}</td>
                                    <td class="text-xs font-mono break-all">
                                        @for (a of j.arquivos; track a) {
                                            <div>{{ a }}</div>
                                        }
                                        @if (j.tamanhoBytes) {
                                            <span class="text-surface-500 font-sans">{{ tam(j.tamanhoBytes) }}</span>
                                        }
                                    </td>
                                    <td>
                                        @if (j.driveStatus) {
                                            <p-tag [value]="j.driveStatus === 'SUCESSO' ? 'Enviado' : j.driveStatus === 'ENVIANDO' ? 'Enviando' : 'Falhou'" [severity]="j.driveStatus === 'SUCESSO' ? 'success' : j.driveStatus === 'ENVIANDO' ? 'info' : 'danger'" [pTooltip]="j.driveMensagem" [rounded]="true" />
                                        } @else {
                                            <span class="text-surface-400">—</span>
                                        }
                                    </td>
                                    <td class="text-sm">
                                        {{ j.mensagem }}
                                        @if (j.erro) {
                                            <div class="text-red-500 text-xs mt-1 break-all">{{ j.erro }}</div>
                                        }
                                        @if (j.removidos > 0) {
                                            <div class="text-surface-500 text-xs mt-1">{{ j.removidos }} arquivo(s) antigo(s) removido(s) pela retenção</div>
                                        }
                                    </td>
                                    <td class="text-sm">{{ j.solicitadoPor || '—' }}</td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage>
                                <tr><td colspan="9" class="text-center py-8 text-surface-500">Nenhuma execução registrada.</td></tr>
                            </ng-template>
                        </p-table>
                    </p-tabpanel>
                </p-tabpanels>
            </p-tabs>
        </div>

        <p-dialog [(visible)]="confirmacaoVisivel" [modal]="true" [draggable]="false" [style]="{ width: '32rem' }" [breakpoints]="{ '640px': '95vw' }" header="Confirmar restauração">
            <div class="flex flex-col gap-4">
                <p class="m-0">
                    O banco do painel será substituído pelo conteúdo de <b class="break-all">{{ alvoRestauracao() }}</b>. Todos os usuários serão desconectados ao final.
                </p>
                @if (!backupSeguranca) {
                    <p-message severity="warn" text="Sem backup de segurança: não haverá como voltar ao estado atual." styleClass="w-full" />
                }
                <div>
                    <label class="block font-medium mb-2">Digite <b>RESTAURAR</b> para confirmar</label>
                    <input pInputText class="w-full" [(ngModel)]="textoConfirmacao" autocomplete="off" />
                </div>
            </div>
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [text]="true" (onClick)="confirmacaoVisivel.set(false)" />
                <p-button label="Restaurar agora" icon="pi pi-upload" severity="danger" [disabled]="textoConfirmacao.trim().toUpperCase() !== 'RESTAURAR'" (onClick)="restaurar()" />
            </ng-template>
        </p-dialog>
    `
})
export class Backup implements OnInit {
    private api = inject(BackupService);
    private notify = inject(NotifyService);
    private route = inject(ActivatedRoute);
    private router = inject(Router);
    private destroyRef = inject(DestroyRef);

    visao = signal<BackupVisaoGeral | null>(null);
    arquivos = signal<ArquivoBackup[]>([]);
    historico = signal<BackupJob[]>([]);
    job = signal<BackupJob | null>(null);
    carregando = signal(false);
    aba = signal<Aba>('backup');
    formatos = signal<string[]>([]);
    pasta = signal('');
    arquivo = signal<File | null>(null);
    baixando = signal<string | null>(null);
    confirmacaoVisivel = signal(false);
    alvoRestauracao = signal('');
    enviarDrive = false;
    backupSeguranca = true;
    textoConfirmacao = '';
    private restauracaoServidor: ArquivoBackup | null = null;
    private poll: ReturnType<typeof setTimeout> | null = null;

    descricao = DESCRICAO_FORMATO;
    rotuloStatus = ROTULO_STATUS;
    rotuloOrigem = ROTULO_ORIGEM;
    rotuloPasta: Record<string, string> = { manuais: 'Manuais', agendados: 'Agendados', seguranca: 'Segurança' };
    pastas = [
        { label: 'Manuais', value: 'manuais' },
        { label: 'Agendados', value: 'agendados' },
        { label: 'Segurança (pré-restauração)', value: 'seguranca' }
    ];
    data = dataHora;
    tam = tamanho;
    cor = corStatus;
    duracao = duracaoJob;

    ocupado = computed(() => !!this.job()?.emAndamento || !!this.visao()?.emAndamento);
    driveConectado = computed(() => !!this.visao()?.verificacoes.find((v) => v.item === 'Google Drive')?.ok);
    arquivosFiltrados = computed(() => (this.pasta() ? this.arquivos().filter((a) => a.pasta === this.pasta()) : this.arquivos()));
    totalArquivos = computed(() => this.arquivos().reduce((s, a) => s + a.tamanho, 0));
    extensoes = computed(() => (this.visao()?.formatos ?? ['backup', 'sql']).map((f) => '.' + f).join(' ou '));
    aceitar = computed(() => (this.visao()?.formatos ?? ['backup', 'sql']).map((f) => '.' + f).join(','));

    constructor() {
        this.destroyRef.onDestroy(() => this.pararPoll());
    }

    ngOnInit(): void {
        const aba = this.route.snapshot.queryParamMap.get('aba') as Aba | null;
        if (aba) {
            this.aba.set(aba);
        }
        this.carregar();
        // Execução em andamento (aberta em outra aba ou pelo agendamento): acompanha.
        this.api.historico(1).subscribe({
            next: (h) => {
                if (h[0]?.emAndamento) {
                    this.acompanhar(h[0]);
                }
            },
            error: () => undefined
        });
    }

    carregar(): void {
        this.carregando.set(true);
        this.api.visaoGeral().subscribe({
            next: (v) => {
                this.visao.set(v);
                if (this.formatos().length === 0) {
                    this.formatos.set([v.formatos[0]]);
                }
                this.carregando.set(false);
            },
            error: (e) => {
                this.carregando.set(false);
                this.notify.erro(e);
            }
        });
        this.api.arquivos().subscribe({ next: (a) => this.arquivos.set(a), error: (e) => this.notify.erro(e) });
        this.api.historico(100).subscribe({ next: (h) => this.historico.set(h), error: () => undefined });
    }

    trocarAba(aba: Aba): void {
        this.aba.set(aba);
        this.router.navigate([], { relativeTo: this.route, queryParams: { aba }, replaceUrl: true });
        if (aba === 'historico') {
            this.api.historico(100).subscribe({ next: (h) => this.historico.set(h), error: () => undefined });
        }
    }

    alternarFormato(f: string, marcado: boolean): void {
        this.formatos.update((l) => (marcado ? [...new Set([...l, f])] : l.filter((x) => x !== f)));
    }

    gerar(): void {
        this.api.executar(this.formatos(), this.enviarDrive).subscribe({
            next: (j) => {
                this.notify.info('Backup iniciado. Acompanhe o progresso no topo da página.');
                this.acompanhar(j);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    baixar(a: ArquivoBackup): void {
        this.baixando.set(a.nome);
        this.api.baixar(a).subscribe({
            next: (blob) => {
                this.baixando.set(null);
                const url = URL.createObjectURL(blob);
                const link = document.createElement('a');
                link.href = url;
                link.download = a.nome;
                document.body.appendChild(link);
                link.click();
                link.remove();
                setTimeout(() => URL.revokeObjectURL(url), 1000);
            },
            error: (e) => {
                this.baixando.set(null);
                this.notify.erro(e);
            }
        });
    }

    excluir(a: ArquivoBackup): void {
        this.notify.confirmarExclusao(`o arquivo ${a.nome}`, () =>
            this.api.excluir(a).subscribe({
                next: () => {
                    this.notify.sucesso('Arquivo excluído.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }

    escolher(ev: Event): void {
        const input = ev.target as HTMLInputElement;
        this.arquivo.set(input.files?.[0] ?? null);
        input.value = '';
    }

    pedirRestauracaoUpload(): void {
        const f = this.arquivo();
        if (!f) {
            return;
        }
        this.restauracaoServidor = null;
        this.alvoRestauracao.set(f.name);
        this.abrirConfirmacao();
    }

    pedirRestauracaoServidor(a: ArquivoBackup): void {
        this.restauracaoServidor = a;
        this.alvoRestauracao.set(`${a.pasta}/${a.nome}`);
        this.abrirConfirmacao();
    }

    restaurar(): void {
        this.confirmacaoVisivel.set(false);
        const obs = this.restauracaoServidor ? this.api.restaurarDoServidor(this.restauracaoServidor, this.backupSeguranca) : this.api.restaurarUpload(this.arquivo()!, this.backupSeguranca);
        obs.subscribe({
            next: (j) => {
                this.arquivo.set(null);
                this.notify.info('Restauração iniciada. Ao terminar, todos serão desconectados.');
                this.acompanhar(j);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    /** Acompanha um job até terminar (consulta a cada 1,5 s). */
    acompanhar(j: BackupJob): void {
        this.job.set(j);
        this.pararPoll();
        const consultar = () => {
            this.api.job(j.id).subscribe({
                next: (atual) => {
                    this.job.set(atual);
                    if (atual.emAndamento) {
                        this.poll = setTimeout(consultar, 1500);
                    } else {
                        this.aoTerminar(atual);
                    }
                },
                // 401 de sessão encerrada (fim de uma restauração) é tratado pelo interceptor.
                error: () => (this.poll = setTimeout(consultar, 4000))
            });
        };
        this.poll = setTimeout(consultar, 800);
    }

    private aoTerminar(j: BackupJob): void {
        this.carregar();
        if (j.status === 'SUCESSO') {
            this.notify.sucesso(j.mensagem ?? 'Concluído.');
        } else if (j.status === 'PARCIAL') {
            this.notify.aviso(j.mensagem ?? 'Concluído com avisos.');
        } else if (j.status === 'ERRO') {
            this.notify.erro(new Error(j.erro ? `${j.mensagem} ${j.erro}` : (j.mensagem ?? 'Falhou.')));
        }
    }

    private abrirConfirmacao(): void {
        this.textoConfirmacao = '';
        this.confirmacaoVisivel.set(true);
    }

    private pararPoll(): void {
        if (this.poll) {
            clearTimeout(this.poll);
            this.poll = null;
        }
    }
}
