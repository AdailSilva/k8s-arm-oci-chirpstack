import { Component, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { SelectModule } from 'primeng/select';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { ChirpstackService, IntegrationPath } from '@/app/core/api/chirpstack.service';
import { CertificateResponse, IntegrationKind } from '@/app/core/api/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/util/notify.service';
import { baixarArquivo, dataHora } from '@/app/core/util/format';
import { CODIFICACOES, Opcao } from '@/app/core/util/options';
import { TagsEditor } from '@/app/shared/tags-editor';
import { CopyButton } from '@/app/shared/copy-button';

type TipoCampo = 'text' | 'password' | 'textarea' | 'select' | 'map' | 'bool' | 'list';

interface Campo {
    nome: string;
    rotulo: string;
    tipo: TipoCampo;
    opcoes?: Opcao[];
    obrigatorio?: boolean;
    dica?: string;
    padrao?: unknown;
}

interface Integracao {
    kind: IntegrationKind;
    path: IntegrationPath;
    nome: string;
    descricao: string;
    icone: string;
    campos: Campo[];
}

const ENC: Campo = { nome: 'encoding', rotulo: 'Codificação do payload', tipo: 'select', opcoes: CODIFICACOES, padrao: 'JSON' };

/** Catálogo das integrações configuráveis pela REST API (v4.15). */
const INTEGRACOES: Integracao[] = [
    {
        kind: 'HTTP', path: 'http', nome: 'HTTP', icone: 'pi pi-globe', descricao: 'Envia os eventos por POST para uma URL.',
        campos: [ENC, { nome: 'eventEndpointUrl', rotulo: 'URL(s) de destino', tipo: 'text', obrigatorio: true, dica: 'Várias URLs separadas por vírgula.' }, { nome: 'headers', rotulo: 'Cabeçalhos HTTP', tipo: 'map', padrao: {} }]
    },
    {
        kind: 'INFLUX_DB', path: 'influxdb', nome: 'InfluxDB', icone: 'pi pi-database', descricao: 'Grava as medições decodificadas no InfluxDB.',
        campos: [
            { nome: 'version', rotulo: 'Versão', tipo: 'select', opcoes: [{ label: 'InfluxDB 1.x', value: 'INFLUXDB_1' }, { label: 'InfluxDB 2.x', value: 'INFLUXDB_2' }, { label: 'InfluxDB 3.x', value: 'INFLUXDB_3' }], padrao: 'INFLUXDB_2' },
            { nome: 'endpoint', rotulo: 'Endpoint de escrita', tipo: 'text', obrigatorio: true, dica: 'Ex.: http://influxdb:8086/api/v2/write' },
            { nome: 'organization', rotulo: 'Organização (2.x/3.x)', tipo: 'text' },
            { nome: 'bucket', rotulo: 'Bucket (2.x/3.x)', tipo: 'text' },
            { nome: 'token', rotulo: 'Token (2.x/3.x)', tipo: 'password' },
            { nome: 'db', rotulo: 'Banco (1.x)', tipo: 'text' },
            { nome: 'username', rotulo: 'Usuário (1.x)', tipo: 'text' },
            { nome: 'password', rotulo: 'Senha (1.x)', tipo: 'password' },
            { nome: 'retentionPolicyName', rotulo: 'Retention policy (1.x)', tipo: 'text' },
            { nome: 'precision', rotulo: 'Precisão do timestamp', tipo: 'select', opcoes: ['NS', 'U', 'MS', 'S', 'M', 'H'].map((v) => ({ label: v, value: v })), padrao: 'NS' }
        ]
    },
    { kind: 'THINGS_BOARD', path: 'thingsboard', nome: 'ThingsBoard', icone: 'pi pi-desktop', descricao: 'Publica telemetria no ThingsBoard.', campos: [{ nome: 'server', rotulo: 'Servidor', tipo: 'text', obrigatorio: true, dica: 'Ex.: https://thingsboard.exemplo.com' }] },
    { kind: 'MY_DEVICES', path: 'mydevices', nome: 'myDevices', icone: 'pi pi-mobile', descricao: 'Encaminha uplinks ao myDevices (Cayenne).', campos: [{ nome: 'endpoint', rotulo: 'Endpoint', tipo: 'text', obrigatorio: true }] },
    {
        kind: 'GCP_PUB_SUB', path: 'gcp-pub-sub', nome: 'GCP Pub/Sub', icone: 'pi pi-google', descricao: 'Publica os eventos num tópico do Google Cloud Pub/Sub.',
        campos: [ENC, { nome: 'projectId', rotulo: 'Projeto', tipo: 'text', obrigatorio: true }, { nome: 'topicName', rotulo: 'Tópico', tipo: 'text', obrigatorio: true }, { nome: 'credentialsFile', rotulo: 'Credenciais (JSON da service account)', tipo: 'textarea', obrigatorio: true }]
    },
    {
        kind: 'AWS_SNS', path: 'aws-sns', nome: 'AWS SNS', icone: 'pi pi-amazon', descricao: 'Publica os eventos num tópico do Amazon SNS.',
        campos: [ENC, { nome: 'region', rotulo: 'Região', tipo: 'text', obrigatorio: true }, { nome: 'accessKeyId', rotulo: 'Access key ID', tipo: 'text', obrigatorio: true }, { nome: 'secretAccessKey', rotulo: 'Secret access key', tipo: 'password', obrigatorio: true }, { nome: 'topicArn', rotulo: 'Topic ARN', tipo: 'text', obrigatorio: true }]
    },
    {
        kind: 'AZURE_SERVICE_BUS', path: 'azure-service-bus', nome: 'Azure Service Bus', icone: 'pi pi-microsoft', descricao: 'Publica numa fila ou tópico do Azure Service Bus.',
        campos: [ENC, { nome: 'connectionString', rotulo: 'Connection string', tipo: 'password', obrigatorio: true }, { nome: 'publishName', rotulo: 'Fila ou tópico', tipo: 'text', obrigatorio: true }]
    },
    { kind: 'PILOT_THINGS', path: 'pilot-things', nome: 'Pilot Things', icone: 'pi pi-send', descricao: 'Integração com a plataforma Pilot Things.', campos: [{ nome: 'server', rotulo: 'Servidor', tipo: 'text', obrigatorio: true }, { nome: 'token', rotulo: 'Token', tipo: 'password', obrigatorio: true }] },
    {
        kind: 'IFTTT', path: 'ifttt', nome: 'IFTTT', icone: 'pi pi-bolt', descricao: 'Dispara applets do IFTTT (Webhooks).',
        campos: [{ nome: 'key', rotulo: 'Chave do Webhooks', tipo: 'password', obrigatorio: true }, { nome: 'eventPrefix', rotulo: 'Prefixo do evento', tipo: 'text' }, { nome: 'uplinkValues', rotulo: 'Valores do uplink (até 2 chaves do objeto decodificado)', tipo: 'list', padrao: [] }, { nome: 'arbitraryJson', rotulo: 'Enviar JSON arbitrário', tipo: 'bool', padrao: false }]
    },
    { kind: 'BLYNK', path: 'blynk', nome: 'Blynk', icone: 'pi pi-th-large', descricao: 'Envia dados para o Blynk.', campos: [{ nome: 'token', rotulo: 'Token', tipo: 'password', obrigatorio: true }] }
];

/**
 * Integrações da aplicação e certificado de cliente MQTT.
 */
@Component({
    selector: 'app-integrations-panel',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, DialogModule, InputTextModule, PasswordModule, SelectModule, TagModule, TextareaModule, ToggleSwitchModule, TagsEditor, CopyButton],
    template: `
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            <div class="border border-surface-200 dark:border-surface-700 rounded-2xl p-5 flex flex-col gap-3">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-900/40 text-primary flex items-center justify-center"><i class="pi pi-server"></i></div>
                    <div class="flex-1">
                        <div class="font-semibold">MQTT</div>
                        <div class="text-sm text-surface-500">Integração global do ChirpStack</div>
                    </div>
                    @if (configuradas().has('MQTT_GLOBAL')) {
                        <p-tag value="Ativa" severity="success" />
                    }
                </div>
                <p class="text-sm text-surface-500 m-0 flex-1">Gera um certificado de cliente para assinar os tópicos <code>application/{{ applicationId() }}/#</code> do broker MQTT do ChirpStack.</p>
                @if (auth.podeEscrever()) {
                    <p-button label="Gerar certificado" icon="pi pi-shield" severity="secondary" [outlined]="true" (onClick)="gerarCertificado()" [loading]="gerando()" />
                }
            </div>

            @for (i of catalogo; track i.kind) {
                <div class="border border-surface-200 dark:border-surface-700 rounded-2xl p-5 flex flex-col gap-3">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-xl bg-surface-100 dark:bg-surface-800 flex items-center justify-center"><i [class]="i.icone"></i></div>
                        <div class="flex-1 font-semibold">{{ i.nome }}</div>
                        @if (configuradas().has(i.kind)) {
                            <p-tag value="Configurada" severity="success" />
                        }
                    </div>
                    <p class="text-sm text-surface-500 m-0 flex-1">{{ i.descricao }}</p>
                    @if (auth.podeEscrever()) {
                        <div class="flex gap-2">
                            @if (configuradas().has(i.kind)) {
                                <p-button label="Editar" icon="pi pi-pencil" size="small" severity="secondary" [outlined]="true" (onClick)="abrir(i)" />
                                <p-button label="Remover" icon="pi pi-trash" size="small" severity="danger" [text]="true" (onClick)="remover(i)" />
                            } @else {
                                <p-button label="Adicionar" icon="pi pi-plus" size="small" (onClick)="abrir(i)" />
                            }
                        </div>
                    }
                </div>
            }
        </div>

        <p-dialog [(visible)]="dialogo" [header]="(editando() ? 'Editar integração ' : 'Nova integração ') + (atual()?.nome ?? '')" [modal]="true" [style]="{ width: '42rem' }" [breakpoints]="{ '768px': '95vw' }">
            @if (atual(); as i) {
                <div class="flex flex-col gap-5">
                    @for (c of i.campos; track c.nome) {
                        <div>
                            @switch (c.tipo) {
                                @case ('bool') {
                                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form[c.nome]" /> {{ c.rotulo }}</label>
                                }
                                @case ('map') {
                                    <app-tags-editor [label]="c.rotulo" keyLabel="Cabeçalho" valueLabel="Valor" [(value)]="form[c.nome]" />
                                }
                                @default {
                                    <label class="block font-medium mb-2">{{ c.rotulo }} @if (c.obrigatorio) {<span class="text-red-500">*</span>}</label>
                                    @switch (c.tipo) {
                                        @case ('select') {
                                            <p-select [options]="c.opcoes ?? []" optionLabel="label" optionValue="value" [(ngModel)]="form[c.nome]" styleClass="w-full" appendTo="body" />
                                        }
                                        @case ('password') {
                                            <p-password [(ngModel)]="form[c.nome]" [feedback]="false" [toggleMask]="true" styleClass="w-full" inputStyleClass="w-full" autocomplete="off" />
                                        }
                                        @case ('textarea') {
                                            <textarea pTextarea class="w-full font-mono text-sm" rows="6" [(ngModel)]="form[c.nome]"></textarea>
                                        }
                                        @case ('list') {
                                            <input pInputText class="w-full" [ngModel]="listaTexto(c.nome)" (ngModelChange)="definirLista(c.nome, $event)" placeholder="temperatura, umidade" />
                                        }
                                        @default {
                                            <input pInputText class="w-full" [(ngModel)]="form[c.nome]" />
                                        }
                                    }
                                }
                            }
                            @if (c.dica) {
                                <small class="text-surface-500 block mt-1">{{ c.dica }}</small>
                            }
                        </div>
                    }
                </div>
            }
            <ng-template #footer>
                <p-button label="Cancelar" severity="secondary" [outlined]="true" (onClick)="dialogo.set(false)" />
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
            </ng-template>
        </p-dialog>

        <p-dialog [(visible)]="dialogoCert" header="Certificado de cliente MQTT" [modal]="true" [style]="{ width: '46rem' }" [breakpoints]="{ '768px': '95vw' }">
            @if (certificado(); as c) {
                <p class="mt-0 text-surface-500">Válido até <b>{{ data(c.expiresAt) }}</b>. A chave privada não fica guardada no ChirpStack: baixe agora.</p>
                @for (p of partesCert(c); track p.nome) {
                    <div class="mb-4">
                        <div class="flex items-center justify-between mb-1">
                            <span class="font-medium">{{ p.rotulo }}</span>
                            <span>
                                <app-copy-button [value]="p.valor" />
                                <p-button icon="pi pi-download" [text]="true" [rounded]="true" size="small" severity="secondary" (onClick)="baixar(p.nome, p.valor)" />
                            </span>
                        </div>
                        <textarea pTextarea class="w-full font-mono text-xs" rows="4" [ngModel]="p.valor" readonly></textarea>
                    </div>
                }
            }
        </p-dialog>
    `
})
export class IntegrationsPanel implements OnInit {
    applicationId = input.required<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    auth = inject(AuthService);

    catalogo = INTEGRACOES;
    configuradas = signal<Set<string>>(new Set());
    atual = signal<Integracao | null>(null);
    editando = signal(false);
    dialogo = signal(false);
    dialogoCert = signal(false);
    salvando = signal(false);
    gerando = signal(false);
    certificado = signal<CertificateResponse | null>(null);
    form: Record<string, any> = {};
    data = dataHora;

    ngOnInit(): void {
        this.carregar();
    }

    carregar(): void {
        this.api.listIntegrations(this.applicationId()).subscribe({
            next: (r) => this.configuradas.set(new Set(r.result.map((i) => i.kind))),
            error: (e) => this.notify.erro(e)
        });
    }

    abrir(i: Integracao): void {
        const inicial: Record<string, any> = {};
        i.campos.forEach((c) => (inicial[c.nome] = structuredClone(c.padrao ?? '')));
        if (this.configuradas().has(i.kind)) {
            this.api.getIntegration(this.applicationId(), i.path).subscribe({
                next: (r) => {
                    this.form = { ...inicial, ...(r.integration as Record<string, any>) };
                    this.editando.set(true);
                    this.atual.set(i);
                    this.dialogo.set(true);
                },
                error: (e) => this.notify.erro(e)
            });
        } else {
            this.form = inicial;
            this.editando.set(false);
            this.atual.set(i);
            this.dialogo.set(true);
        }
    }

    listaTexto(nome: string): string {
        return ((this.form[nome] as string[]) ?? []).join(', ');
    }

    definirLista(nome: string, texto: string): void {
        this.form[nome] = texto.split(',').map((s) => s.trim()).filter((s) => s);
    }

    salvar(): void {
        const i = this.atual();
        if (!i) {
            return;
        }
        const faltando = i.campos.filter((c) => c.obrigatorio && !String(this.form[c.nome] ?? '').trim());
        if (faltando.length) {
            this.notify.aviso('Preencha: ' + faltando.map((c) => c.rotulo).join(', ') + '.');
            return;
        }
        this.salvando.set(true);
        const op = this.editando() ? this.api.updateIntegration(this.applicationId(), i.path, this.form) : this.api.createIntegration(this.applicationId(), i.path, this.form);
        op.subscribe({
            next: () => {
                this.salvando.set(false);
                this.dialogo.set(false);
                this.notify.sucesso(`Integração ${i.nome} salva.`);
                this.carregar();
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    remover(i: Integracao): void {
        this.notify.confirmarExclusao(`a integração ${i.nome}`, () =>
            this.api.deleteIntegration(this.applicationId(), i.path).subscribe({
                next: () => {
                    this.notify.sucesso('Integração removida.');
                    this.carregar();
                },
                error: (e) => this.notify.erro(e)
            })
        );
    }

    gerarCertificado(): void {
        this.gerando.set(true);
        this.api.generateMqttCertificate(this.applicationId()).subscribe({
            next: (c) => {
                this.gerando.set(false);
                this.certificado.set(c);
                this.dialogoCert.set(true);
            },
            error: (e) => {
                this.gerando.set(false);
                this.notify.erro(e);
            }
        });
    }

    partesCert(c: CertificateResponse) {
        return [
            { nome: 'ca.crt', rotulo: 'Certificado da CA', valor: c.caCert },
            { nome: 'client.crt', rotulo: 'Certificado do cliente', valor: c.tlsCert },
            { nome: 'client.key', rotulo: 'Chave privada do cliente', valor: c.tlsKey }
        ];
    }

    baixar(nome: string, valor: string): void {
        baixarArquivo(nome, valor, 'application/x-pem-file');
    }
}
