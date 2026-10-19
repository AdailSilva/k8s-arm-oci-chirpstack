import { Component, computed, DestroyRef, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TabsModule } from 'primeng/tabs';
import { TagModule } from 'primeng/tag';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { TooltipModule } from 'primeng/tooltip';
import { VisitantesService } from '@/app/core/api/visitantes.service';
import { AuthService } from '@/app/core/auth/auth.service';
import { FalhaLogin, Metric, ResumoVisitantes, SessaoVisitante, VisitanteUsuario } from '@/app/core/api/models';
import { NotifyService } from '@/app/core/util/notify.service';
import { dataHora, tempoRelativo } from '@/app/core/util/format';
import { KpiCard } from '@/app/shared/kpi-card';
import { MetricChart } from '@/app/shared/metric-chart';
import { PageHeader } from '@/app/shared/page-header';
import { BloqueioDialog } from './bloqueio-dialog';
import { VisitantesHistorico } from './visitantes-historico';
import { duracao } from './visitantes-util';

type Aba = 'online' | 'usuarios' | 'historico' | 'falhas';

/**
 * Controle e monitoramento de visitantes: indicadores, quem está on-line agora (atualiza a cada 10 s),
 * frequência por usuário, histórico de acessos e tentativas recusadas. Ações do administrador:
 * encerrar sessões, desconectar todos e bloquear o acesso de um usuário.
 */
@Component({
    selector: 'app-visitantes',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, SelectModule, TableModule, TabsModule, TagModule, ToggleSwitchModule, TooltipModule, KpiCard, MetricChart, PageHeader, BloqueioDialog, VisitantesHistorico],
    template: `
        <app-page-header title="Visitantes" subtitle="Quem acessou, de onde, quem está on-line agora e as tentativas recusadas" icon="pi pi-users">
            <label class="flex items-center gap-2 text-sm text-surface-600 dark:text-surface-300 mr-2" pTooltip="Atualiza indicadores e sessões a cada 10 segundos" tooltipPosition="bottom">
                <p-toggleswitch [ngModel]="tempoReal()" (ngModelChange)="tempoReal.set($event)" />
                Tempo real
                @if (tempoReal()) {
                    <span class="relative flex h-2 w-2"><span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span><span class="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span></span>
                }
            </label>
            <p-select [options]="periodos" optionLabel="label" optionValue="value" [ngModel]="dias()" (ngModelChange)="dias.set($event); carregarResumo()" styleClass="w-40" />
            <p-button icon="pi pi-refresh" label="Atualizar" severity="secondary" [outlined]="true" (onClick)="atualizarTudo()" [loading]="carregando()" />
            <p-button icon="pi pi-power-off" label="Desconectar todos" severity="danger" [outlined]="true" (onClick)="desconectarTodos()" [disabled]="outrasSessoes() === 0" pTooltip="Encerra todas as sessões, exceto a sua" tooltipPosition="bottom" />
        </app-page-header>

        <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-6 gap-4 mb-6">
            <app-kpi-card label="On-line agora" [value]="resumo()?.usuariosOnline ?? '—'" [detail]="(resumo()?.onlineAgora ?? 0) + ' aba(s) · ' + (resumo()?.sessoesAbertas ?? 0) + ' sessão(ões) aberta(s)'" icon="pi pi-circle-fill" iconBg="bg-green-50 text-green-600 dark:bg-green-900/30 dark:text-green-300" />
            <app-kpi-card label="Acessos hoje" [value]="resumo()?.acessosHoje ?? '—'" [detail]="(resumo()?.visitantesHoje ?? 0) + ' visitante(s) único(s)'" icon="pi pi-sign-in" />
            <app-kpi-card label="Visitantes (7 dias)" [value]="resumo()?.visitantes7Dias ?? '—'" detail="usuários diferentes" icon="pi pi-users" iconBg="bg-indigo-50 text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-300" />
            <app-kpi-card [label]="'Acessos (' + dias() + ' dias)'" [value]="resumo()?.acessosPeriodo ?? '—'" [detail]="'média de ' + (resumo()?.duracaoMediaMinutos ?? 0) + ' min por sessão'" icon="pi pi-chart-line" iconBg="bg-cyan-50 text-cyan-600 dark:bg-cyan-900/30 dark:text-cyan-300" />
            <app-kpi-card label="Recusas hoje" [value]="resumo()?.falhasLoginHoje ?? '—'" detail="senha errada, bloqueio ou excesso" [detailClass]="(resumo()?.falhasLoginHoje ?? 0) > 0 ? 'text-orange-600' : 'text-surface-500'" icon="pi pi-shield" iconBg="bg-orange-50 text-orange-600 dark:bg-orange-900/30 dark:text-orange-300" />
            <app-kpi-card label="Bloqueados / inativos" [value]="resumo()?.usuariosBloqueados ?? '—'" detail="sem acesso no momento" icon="pi pi-ban" iconBg="bg-red-50 text-red-600 dark:bg-red-900/30 dark:text-red-300" />
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-12 gap-4 mb-6">
            <div class="xl:col-span-6"><app-metric-chart [metric]="serie()" title="Acessos por dia" type="bar" /></div>
            <div class="xl:col-span-3"><app-metric-chart [metric]="porHora()" title="Horário dos acessos" type="bar" /></div>
            <div class="xl:col-span-3">
                <div class="card h-full mb-0!">
                    <div class="font-semibold mb-4">Dispositivos</div>
                    @for (d of resumo()?.dispositivos ?? []; track d.nome) {
                        <div class="mb-3">
                            <div class="flex justify-between text-sm mb-1"><span class="truncate">{{ d.nome }}</span><b class="tabular-nums">{{ d.total }}</b></div>
                            <div class="h-2 rounded-full bg-surface-100 dark:bg-surface-800 overflow-hidden"><div class="h-full rounded-full bg-primary" [style.width.%]="pct(d.total, maxDispositivo())"></div></div>
                        </div>
                    } @empty {
                        <div class="h-56 flex flex-col items-center justify-center text-surface-400 gap-2"><i class="pi pi-desktop text-3xl!"></i><span>Sem acessos no período</span></div>
                    }
                    @if (resumo()?.encerramentos?.length) {
                        <div class="font-semibold mt-5 mb-3">Como as sessões terminaram</div>
                        <div class="flex flex-wrap gap-2">
                            @for (e of resumo()?.encerramentos ?? []; track e.nome) {
                                <p-tag [value]="e.nome + ': ' + e.total" severity="secondary" [rounded]="true" />
                            }
                        </div>
                    }
                </div>
            </div>
        </div>

        <div class="card">
            <p-tabs [value]="aba()" (valueChange)="aba.set($any($event))">
                <p-tablist>
                    <p-tab value="online"><i class="pi pi-circle-fill text-green-500 mr-2 text-xs!"></i>On-line agora <span class="ml-2 text-surface-500">({{ sessoes().length }})</span></p-tab>
                    <p-tab value="usuarios"><i class="pi pi-user mr-2"></i>Por usuário</p-tab>
                    <p-tab value="historico"><i class="pi pi-history mr-2"></i>Histórico de acessos</p-tab>
                    <p-tab value="falhas"><i class="pi pi-shield mr-2"></i>Tentativas recusadas</p-tab>
                </p-tablist>
                <p-tabpanels>
                    <p-tabpanel value="online">
                        <p-table [value]="sessoes()" [rowHover]="true" styleClass="p-datatable-sm" [tableStyle]="{ 'min-width': '72rem' }" dataKey="id">
                            <ng-template #header>
                                <tr>
                                    <th>Usuário</th>
                                    <th class="w-36">Situação</th>
                                    <th>Dispositivo</th>
                                    <th class="w-36">IP</th>
                                    <th class="w-36">Entrou</th>
                                    <th class="w-32">Sem interação</th>
                                    <th class="w-40">Encerra no máximo</th>
                                    <th class="w-24 text-right">Ações</th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-s>
                                <tr>
                                    <td>
                                        <div class="flex items-center gap-2">
                                            <span class="font-medium">{{ s.usuarioNome }}</span>
                                            @if (s.atual) {
                                                <p-tag value="Você" severity="info" [rounded]="true" />
                                            }
                                        </div>
                                        <div class="text-sm text-surface-500">{{ s.usuarioEmail }}</div>
                                    </td>
                                    <td>
                                        @if (s.online) {
                                            <span class="inline-flex items-center gap-2 text-green-600 dark:text-green-400 font-medium"><span class="w-2 h-2 rounded-full bg-green-500"></span>On-line</span>
                                        } @else {
                                            <span class="inline-flex items-center gap-2 text-surface-500" pTooltip="A sessão está aberta, mas nenhuma aba do sistema está aberta agora." tooltipPosition="top"><span class="w-2 h-2 rounded-full bg-surface-400"></span>Ausente</span>
                                        }
                                    </td>
                                    <td class="text-sm" [pTooltip]="s.userAgent" tooltipPosition="top">{{ s.dispositivo || '—' }}</td>
                                    <td class="text-sm font-mono">{{ s.ip || '—' }}</td>
                                    <td class="text-sm" [pTooltip]="data(s.iniciadaEm)" tooltipPosition="top">{{ relativo(s.iniciadaEm) }}<div class="text-surface-500">{{ duracao(s.duracaoSegundos) }} de sessão</div></td>
                                    <td class="text-sm tabular-nums">{{ duracao(s.ociosoSegundos) }}</td>
                                    <td class="text-sm">{{ data(s.expiraEm) }}</td>
                                    <td class="text-right">
                                        <p-button icon="pi pi-sign-out" severity="danger" [text]="true" [rounded]="true" [disabled]="s.atual" (onClick)="encerrarSessao(s)" [pTooltip]="s.atual ? 'Esta é a sua sessão' : 'Encerrar esta sessão'" tooltipPosition="left" />
                                    </td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage>
                                <tr><td colspan="8" class="text-center py-8 text-surface-500">Nenhuma sessão aberta.</td></tr>
                            </ng-template>
                        </p-table>
                    </p-tabpanel>

                    <p-tabpanel value="usuarios">
                        <p-table [value]="usuarios()" [rowHover]="true" styleClass="p-datatable-sm" [tableStyle]="{ 'min-width': '76rem' }" sortField="ultimoAcesso" [sortOrder]="-1" dataKey="usuarioId">
                            <ng-template #header>
                                <tr>
                                    <th pSortableColumn="nome">Usuário <p-sortIcon field="nome" /></th>
                                    <th class="w-48">Situação</th>
                                    <th pSortableColumn="totalAcessos" class="w-24 text-center">Total <p-sortIcon field="totalAcessos" /></th>
                                    <th pSortableColumn="acessosHoje" class="w-24 text-center">Hoje <p-sortIcon field="acessosHoje" /></th>
                                    <th pSortableColumn="acessos7Dias" class="w-24 text-center">7 dias <p-sortIcon field="acessos7Dias" /></th>
                                    <th pSortableColumn="ultimoAcesso" class="w-40">Último acesso <p-sortIcon field="ultimoAcesso" /></th>
                                    <th>Último dispositivo / IP</th>
                                    <th class="w-40 text-right">Ações</th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-u>
                                <tr>
                                    <td>
                                        <div class="flex items-center gap-2">
                                            <span class="w-2 h-2 rounded-full shrink-0" [ngClass]="u.online ? 'bg-green-500' : 'bg-surface-300 dark:bg-surface-600'" [pTooltip]="u.online ? 'On-line' : 'Off-line'"></span>
                                            <span class="font-medium">{{ u.nome }}</span>
                                        </div>
                                        <div class="text-sm text-surface-500 ml-4">{{ u.email }} · {{ perfis[u.perfil] }}</div>
                                    </td>
                                    <td>
                                        @if (!u.ativo) {
                                            <p-tag value="Inativo" severity="danger" [rounded]="true" [pTooltip]="u.motivoBloqueio || ''" />
                                        } @else if (u.bloqueado) {
                                            <p-tag [value]="'Bloqueado até ' + data(u.bloqueadoAte)" severity="warn" [rounded]="true" [pTooltip]="u.motivoBloqueio || 'Excesso de tentativas de login'" />
                                        } @else if (u.sessoesAbertas > 0) {
                                            <p-tag [value]="u.sessoesAbertas + ' sessão(ões) aberta(s)'" severity="success" [rounded]="true" />
                                        } @else {
                                            <p-tag value="Sem sessão" severity="secondary" [rounded]="true" />
                                        }
                                    </td>
                                    <td class="text-center tabular-nums">{{ u.totalAcessos }}</td>
                                    <td class="text-center tabular-nums">{{ u.acessosHoje }}</td>
                                    <td class="text-center tabular-nums">{{ u.acessos7Dias }}</td>
                                    <td class="text-sm" [pTooltip]="data(u.ultimoAcesso)">{{ u.ultimoAcesso ? relativo(u.ultimoAcesso) : 'nunca' }}</td>
                                    <td class="text-sm">{{ u.ultimoDispositivo || '—' }}<div class="text-surface-500 font-mono">{{ u.ultimoIp || '' }}</div></td>
                                    <td class="text-right whitespace-nowrap">
                                        <p-button icon="pi pi-history" [text]="true" [rounded]="true" severity="secondary" (onClick)="verHistorico(u)" pTooltip="Histórico de acessos" tooltipPosition="left" />
                                        <p-button icon="pi pi-sign-out" [text]="true" [rounded]="true" severity="danger" [disabled]="u.sessoesAbertas === 0" (onClick)="encerrarDoUsuario(u)" pTooltip="Encerrar as sessões" tooltipPosition="left" />
                                        @if (u.bloqueado) {
                                            <p-button icon="pi pi-lock-open" [text]="true" [rounded]="true" severity="success" (onClick)="desbloquear(u)" pTooltip="Desbloquear" tooltipPosition="left" />
                                        } @else {
                                            <p-button icon="pi pi-ban" [text]="true" [rounded]="true" severity="danger" [disabled]="!u.ativo || u.email === meuEmail()" (onClick)="abrirBloqueio(u)" pTooltip="Bloquear acesso" tooltipPosition="left" />
                                        }
                                    </td>
                                </tr>
                            </ng-template>
                        </p-table>
                    </p-tabpanel>

                    <p-tabpanel value="historico">
                        @if (aba() === 'historico') {
                            <app-visitantes-historico [usuarios]="usuarios()" [filtroUsuario]="filtroHistorico()" />
                        }
                    </p-tabpanel>

                    <p-tabpanel value="falhas">
                        <p-table [value]="falhas()" [rowHover]="true" styleClass="p-datatable-sm" [paginator]="falhas().length > 20" [rows]="20" [tableStyle]="{ 'min-width': '60rem' }">
                            <ng-template #header>
                                <tr>
                                    <th class="w-44">Data/hora</th>
                                    <th>E-mail informado</th>
                                    <th class="w-44">Tipo</th>
                                    <th>Detalhe</th>
                                    <th class="w-36">IP</th>
                                </tr>
                            </ng-template>
                            <ng-template #body let-f>
                                <tr>
                                    <td class="text-sm">{{ data(f.criadoEm) }}</td>
                                    <td>{{ f.email || '—' }}</td>
                                    <td><p-tag [value]="f.acao === 'LOGIN_BLOQUEADO_IP' ? 'Excesso por IP' : 'Login recusado'" [severity]="f.acao === 'LOGIN_BLOQUEADO_IP' ? 'danger' : 'warn'" [rounded]="true" /></td>
                                    <td class="text-sm">{{ f.detalhe || '—' }}</td>
                                    <td class="text-sm font-mono">{{ f.ip || '—' }}</td>
                                </tr>
                            </ng-template>
                            <ng-template #emptymessage>
                                <tr><td colspan="5" class="text-center py-8 text-surface-500">Nenhuma tentativa recusada.</td></tr>
                            </ng-template>
                        </p-table>
                    </p-tabpanel>
                </p-tabpanels>
            </p-tabs>
        </div>

        <app-bloqueio-dialog [(visivel)]="bloqueioVisivel" [usuario]="selecionado()" (concluido)="atualizarTudo()" />
    `
})
export class Visitantes implements OnInit {
    private api = inject(VisitantesService);
    private notify = inject(NotifyService);
    private auth = inject(AuthService);

    resumo = signal<ResumoVisitantes | null>(null);
    sessoes = signal<SessaoVisitante[]>([]);
    usuarios = signal<VisitanteUsuario[]>([]);
    falhas = signal<FalhaLogin[]>([]);
    carregando = signal(false);
    aba = signal<Aba>('online');
    dias = signal(14);
    tempoReal = signal(true);
    bloqueioVisivel = signal(false);
    selecionado = signal<VisitanteUsuario | null>(null);
    filtroHistorico = signal<number | null>(null);

    periodos = [
        { label: '7 dias', value: 7 },
        { label: '14 dias', value: 14 },
        { label: '30 dias', value: 30 },
        { label: '90 dias', value: 90 }
    ];
    perfis: Record<string, string> = { ADMIN: 'Administrador', OPERADOR: 'Operador', VISUALIZADOR: 'Visualizador' };
    data = dataHora;
    relativo = tempoRelativo;
    duracao = duracao;

    meuEmail = computed(() => this.auth.usuario()?.email ?? '');
    outrasSessoes = computed(() => this.sessoes().filter((s) => !s.atual).length);

    serie = computed<Metric | null>(() => {
        const r = this.resumo();
        if (!r) {
            return null;
        }
        return {
            name: 'Acessos',
            kind: 'COUNTER',
            timestamps: r.serie.map((d) => d.dia + 'T12:00:00'),
            datasets: [
                { label: 'Acessos', data: r.serie.map((d) => d.acessos) },
                { label: 'Visitantes únicos', data: r.serie.map((d) => d.visitantes) }
            ]
        };
    });

    porHora = computed<Metric | null>(() => {
        const r = this.resumo();
        if (!r) {
            return null;
        }
        const hoje = new Date();
        return {
            name: 'Acessos por hora',
            kind: 'COUNTER',
            timestamps: r.porHora.map((_, h) => new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), h).toISOString()),
            datasets: [{ label: 'Acessos', data: r.porHora }]
        };
    });

    maxDispositivo = computed(() => Math.max(1, ...(this.resumo()?.dispositivos ?? []).map((d) => d.total)));

    constructor() {
        const timer = setInterval(() => {
            if (this.tempoReal() && !document.hidden) {
                this.carregarSessoes();
                this.carregarResumo(true);
                if (this.aba() === 'usuarios') {
                    this.carregarUsuarios();
                }
            }
        }, 10_000);
        inject(DestroyRef).onDestroy(() => clearInterval(timer));
    }

    ngOnInit(): void {
        this.atualizarTudo();
    }

    atualizarTudo(): void {
        this.carregarResumo();
        this.carregarSessoes();
        this.carregarUsuarios();
        this.api.falhas().subscribe({ next: (f) => this.falhas.set(f), error: () => undefined });
    }

    carregarResumo(silencioso = false): void {
        if (!silencioso) {
            this.carregando.set(true);
        }
        this.api.resumo(this.dias()).subscribe({
            next: (r) => {
                this.resumo.set(r);
                this.carregando.set(false);
            },
            error: (e) => {
                this.carregando.set(false);
                if (!silencioso) {
                    this.notify.erro(e);
                }
            }
        });
    }

    carregarSessoes(): void {
        this.api.sessoesAbertas().subscribe({ next: (s) => this.sessoes.set(s), error: () => undefined });
    }

    carregarUsuarios(): void {
        this.api.porUsuario().subscribe({ next: (u) => this.usuarios.set(u), error: () => undefined });
    }

    pct(v: number, max: number): number {
        return Math.round((v / max) * 100);
    }

    verHistorico(u: VisitanteUsuario): void {
        this.filtroHistorico.set(u.usuarioId);
        this.aba.set('historico');
    }

    encerrarSessao(s: SessaoVisitante): void {
        this.notify.confirmar('Encerrar sessão', `Encerrar a sessão de <b>${s.usuarioNome}</b> (${s.dispositivo ?? 'dispositivo desconhecido'})? A tela dele volta para o login na hora.`, () =>
            this.api.encerrarSessao(s.id).subscribe({
                next: () => {
                    this.notify.sucesso('Sessão encerrada.');
                    this.atualizarTudo();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Encerrar'
        );
    }

    encerrarDoUsuario(u: VisitanteUsuario): void {
        this.notify.confirmar('Encerrar sessões', `Encerrar todas as sessões de <b>${u.nome}</b>?`, () =>
            this.api.encerrarSessoesDoUsuario(u.usuarioId).subscribe({
                next: (r) => {
                    this.notify.sucesso(`${r.encerradas} sessão(ões) encerrada(s).`);
                    this.atualizarTudo();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Encerrar'
        );
    }

    desconectarTodos(): void {
        this.notify.confirmar('Desconectar todos', 'Encerrar <b>todas as sessões abertas</b>, exceto a sua? Todos os demais usuários voltam para o login.', () =>
            this.api.encerrarTodas().subscribe({
                next: (r) => {
                    this.notify.sucesso(`${r.encerradas} sessão(ões) encerrada(s).`);
                    this.atualizarTudo();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Desconectar todos'
        );
    }

    abrirBloqueio(u: VisitanteUsuario): void {
        this.selecionado.set(u);
        this.bloqueioVisivel.set(true);
    }

    desbloquear(u: VisitanteUsuario): void {
        this.notify.confirmar('Desbloquear acesso', `Liberar o acesso de <b>${u.nome}</b> agora?`, () =>
            this.api.desbloquear(u.usuarioId).subscribe({
                next: () => {
                    this.notify.sucesso('Acesso liberado.');
                    this.atualizarTudo();
                },
                error: (e) => this.notify.erro(e)
            }),
            'Desbloquear'
        );
    }
}
