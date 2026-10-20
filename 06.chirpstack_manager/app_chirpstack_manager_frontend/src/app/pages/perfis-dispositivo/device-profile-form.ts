import { Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { MessageModule } from 'primeng/message';
import { MultiSelectModule } from 'primeng/multiselect';
import { TagModule } from 'primeng/tag';
import { SelectModule } from 'primeng/select';
import { TableModule } from 'primeng/table';
import { TabsModule } from 'primeng/tabs';
import { TextareaModule } from 'primeng/textarea';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { map, Observable } from 'rxjs';
import { ChirpstackService } from '@/app/core/http/chirpstack.service';
import { AdrAlgorithm, DeviceProfile, DeviceProfileListItem, Measurement } from '@/app/core/http/models';
import { AuthService } from '@/app/core/auth/auth.service';
import { NotifyService } from '@/app/core/notificacao/notify.service';
import { TenantContextService } from '@/app/core/tenant/tenant-context.service';
import { num } from '@/app/core/format/format';
import { CODECS, PERIODICIDADE_PING_SLOT, REGIOES, RELAY_ACK_OFFSET, RELAY_ATIVACAO, RELAY_CAD, REVISOES_PARAMETROS, TIPOS_MEDICAO, TS003, TS004, TS005, VERSOES_MAC } from '@/app/core/format/options';
import { PageHeader } from '@/app/shared/visual/page-header';
import { TagsEditor } from '@/app/shared/campos/tags-editor';

const CODEC_EXEMPLO = `/**
 * Decodifica o uplink (bytes) em um objeto.
 * input.bytes: array de bytes · input.fPort: porta · input.variables: variáveis do dispositivo
 */
function decodeUplink(input) {
    var b = input.bytes;
    return {
        data: {
            temperatura: ((b[0] << 8) | b[1]) / 100,
            umidade: b[2]
        }
    };
}

/**
 * Codifica um objeto (downlink) em bytes.
 */
function encodeDownlink(input) {
    return {
        bytes: [input.data.rele ? 1 : 0]
    };
}
`;

/** Campos que chegam como texto (int64) e precisam virar número no formulário. */
const NUMERICOS: (keyof DeviceProfile)[] = [
    'uplinkInterval', 'deviceStatusReqInterval', 'classBTimeout', 'classBPingSlotPeriodicity', 'classBPingSlotDr', 'classBPingSlotFreq', 'classCTimeout',
    'abpRx1Delay', 'abpRx1DrOffset', 'abpRx2Dr', 'abpRx2Freq', 'rx1Delay', 'relayDefaultChannelIndex', 'relaySecondChannelFreq', 'relaySecondChannelDr',
    'relayEdSmartEnableLevel', 'relayEdBackOff', 'relayEdUplinkLimitBucketSize', 'relayEdUplinkLimitReloadRate', 'relayJoinReqLimitReloadRate',
    'relayNotifyLimitReloadRate', 'relayGlobalUplinkLimitReloadRate', 'relayOverallLimitReloadRate', 'relayJoinReqLimitBucketSize',
    'relayNotifyLimitBucketSize', 'relayGlobalUplinkLimitBucketSize', 'relayOverallLimitBucketSize'
];

export function novoPerfil(tenantId = ''): DeviceProfile {
    return {
        tenantId, name: '', description: '', region: 'AU915', regionConfigId: '', macVersion: 'LORAWAN_1_0_3', regParamsRevision: 'A', adrAlgorithmId: 'default',
        payloadCodecRuntime: 'NONE', payloadCodecScript: '', flushQueueOnActivate: true, uplinkInterval: 3600, deviceStatusReqInterval: 1,
        supportsOtaa: true, supportsClassB: false, supportsClassC: false, classBTimeout: 5, classBPingSlotPeriodicity: 0, classBPingSlotDr: 0, classBPingSlotFreq: 0,
        classCTimeout: 5, abpRx1Delay: 1, abpRx1DrOffset: 0, abpRx2Dr: 0, abpRx2Freq: 0, tags: {}, measurements: {}, autoDetectMeasurements: true,
        allowRoaming: false, rx1Delay: 0, appLayerParams: { ts003Version: 'TS003_NOT_IMPLEMENTED', ts003FPort: 202, ts004Version: 'TS004_NOT_IMPLEMENTED', ts004FPort: 201, ts005Version: 'TS005_NOT_IMPLEMENTED', ts005FPort: 200 },
        isRelay: false, isRelayEd: false, relayEdRelayOnly: false, relayEnabled: false, relayCadPeriodicity: 'SEC_1', relayDefaultChannelIndex: 0,
        relaySecondChannelFreq: 0, relaySecondChannelDr: 0, relaySecondChannelAckOffset: 'KHZ_0', relayEdActivationMode: 'DISABLE_RELAY_MODE',
        relayEdSmartEnableLevel: 0, relayEdBackOff: 0, relayEdUplinkLimitBucketSize: 0, relayEdUplinkLimitReloadRate: 0, relayJoinReqLimitReloadRate: 0,
        relayNotifyLimitReloadRate: 0, relayGlobalUplinkLimitReloadRate: 0, relayOverallLimitReloadRate: 0, relayJoinReqLimitBucketSize: 0,
        relayNotifyLimitBucketSize: 0, relayGlobalUplinkLimitBucketSize: 0, relayOverallLimitBucketSize: 0,
        supportedUplinkDataRates: [], classBDownlinkOnly: false
    };
}

interface LinhaMedicao {
    chave: string;
    name: string;
    kind: Measurement['kind'];
}

/**
 * Formulário de perfil de dispositivo ou de template de perfil ({@code data.modo = 'template'}).
 */
@Component({
    selector: 'app-device-profile-form',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule, ButtonModule, DialogModule, InputNumberModule, InputTextModule, MessageModule, MultiSelectModule, SelectModule, TableModule, TabsModule, TagModule, TextareaModule, ToggleSwitchModule, PageHeader, TagsEditor],
    template: `
        <app-page-header [title]="titulo()" [subtitle]="template ? 'Template global de perfil' : global() ? 'Perfil global do catálogo · vale para todos os tenants' : 'Perfil do tenant ' + (ctx.tenant()?.name ?? '')" [icon]="template ? 'pi pi-copy' : 'pi pi-id-card'">
            <p-button label="Voltar" icon="pi pi-arrow-left" severity="secondary" [outlined]="true" (onClick)="voltar()" />
            @if (podeEditar()) {
                @if (!template && !id()) {
                    <p-button label="Importar de template" icon="pi pi-download" severity="secondary" (onClick)="abrirTemplates()" />
                }
                <p-button label="Salvar" icon="pi pi-check" (onClick)="salvar()" [loading]="salvando()" />
            }
        </app-page-header>

        @if (!podeEditar()) {
            <p-message severity="info" [text]="global() ? 'Perfil global do catálogo: somente o administrador pode alterá-lo.' : 'Modo somente leitura: seu perfil de acesso não permite alterar este registro.'" styleClass="mb-4 w-full" />
        }

        @if (catalogo(); as c) {
            <div class="card mb-4! flex flex-wrap items-center gap-x-8 gap-y-2">
                <div class="font-semibold flex items-center gap-2"><i class="pi pi-box text-primary"></i> Catálogo de dispositivos</div>
                <div><span class="text-surface-500">Fabricante:</span> {{ c.fabricante || '—' }}</div>
                <div><span class="text-surface-500">Modelo:</span> {{ c.modelo || '—' }}</div>
                <div><span class="text-surface-500">Firmware:</span> {{ form.firmwareVersion || '—' }}</div>
                @if (global()) {
                    <p-tag value="Global" severity="contrast" />
                }
                <small class="text-surface-500 basis-full">Vínculo definido na importação do catálogo; não é alterado por este formulário.</small>
            </div>
        }

        <div class="card">
            <p-tabs value="geral" [scrollable]="true">
                <p-tablist>
                    <p-tab value="geral">Geral</p-tab>
                    <p-tab value="join">Join (OTAA / ABP)</p-tab>
                    <p-tab value="classeb">Classe B</p-tab>
                    <p-tab value="classec">Classe C</p-tab>
                    <p-tab value="codec">Codec</p-tab>
                    <p-tab value="medicoes">Medições</p-tab>
                    @if (!template) {
                        <p-tab value="relay">Relay</p-tab>
                        <p-tab value="aplicacao">Camada de aplicação</p-tab>
                    }
                    <p-tab value="tags">Tags</p-tab>
                </p-tablist>
                <p-tabpanels>
                    <!-- Geral -->
                    <p-tabpanel value="geral">
                        <fieldset [disabled]="!podeEditar()" class="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-5xl border-0 p-0 m-0">
                            @if (template) {
                                <div>
                                    <label class="block font-medium mb-2">ID do template <span class="text-red-500">*</span></label>
                                    <input pInputText class="w-full font-mono" [(ngModel)]="templateId" [disabled]="!!id()" placeholder="fabricante-modelo-firmware" />
                                    <small class="text-surface-500">Identificador único (letras, números, ponto, hífen, dois-pontos).</small>
                                </div>
                                <div></div>
                                <div>
                                    <label class="block font-medium mb-2">Fabricante <span class="text-red-500">*</span></label>
                                    <input pInputText class="w-full" [(ngModel)]="form.vendor" />
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">Firmware <span class="text-red-500">*</span></label>
                                    <input pInputText class="w-full" [(ngModel)]="form.firmware" />
                                </div>
                            }
                            <div class="md:col-span-2">
                                <label class="block font-medium mb-2">Nome <span class="text-red-500">*</span></label>
                                <input pInputText class="w-full" [(ngModel)]="form.name" maxlength="100" />
                            </div>
                            <div class="md:col-span-2">
                                <label class="block font-medium mb-2">Descrição</label>
                                <textarea pTextarea class="w-full" rows="2" [(ngModel)]="form.description"></textarea>
                            </div>
                            <div>
                                <label class="block font-medium mb-2">Região</label>
                                <p-select [options]="regioes" optionLabel="label" optionValue="value" [(ngModel)]="form.region" styleClass="w-full" [disabled]="!podeEditar()" />
                            </div>
                            @if (!template) {
                                <div>
                                    <label class="block font-medium mb-2">Configuração da região (opcional)</label>
                                    <input pInputText class="w-full" [(ngModel)]="form.regionConfigId" placeholder="ex.: au915_1" />
                                    <small class="text-surface-500">ID da região no chirpstack.toml quando há mais de uma configuração para a mesma região (ex.: sub-bandas AU915).</small>
                                </div>
                            } @else {
                                <div></div>
                            }
                            <div>
                                <label class="block font-medium mb-2">Versão MAC LoRaWAN</label>
                                <p-select [options]="versoes" optionLabel="label" optionValue="value" [(ngModel)]="form.macVersion" styleClass="w-full" [disabled]="!podeEditar()" />
                            </div>
                            <div>
                                <label class="block font-medium mb-2">Revisão dos parâmetros regionais</label>
                                <p-select [options]="revisoes" optionLabel="label" optionValue="value" [(ngModel)]="form.regParamsRevision" styleClass="w-full" [disabled]="!podeEditar()" />
                            </div>
                            <div>
                                <label class="block font-medium mb-2">Algoritmo ADR</label>
                                <p-select [options]="adr()" optionLabel="name" optionValue="id" [(ngModel)]="form.adrAlgorithmId" styleClass="w-full" [disabled]="!podeEditar()" />
                            </div>
                            <div>
                                <label class="block font-medium mb-2">Intervalo esperado de uplink (s)</label>
                                <p-inputnumber [(ngModel)]="form.uplinkInterval" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                <small class="text-surface-500">Usado para indicar se o dispositivo está ativo ou inativo.</small>
                            </div>
                            <div>
                                <label class="block font-medium mb-2">Pedidos de status por dia</label>
                                <p-inputnumber [(ngModel)]="form.deviceStatusReqInterval" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                <small class="text-surface-500">Frequência do DevStatusReq (bateria e margem). 0 desliga.</small>
                            </div>
                            @if (!template) {
                                <div>
                                    <label class="block font-medium mb-2">RX1 delay (s)</label>
                                    <p-inputnumber [(ngModel)]="form.rx1Delay" [min]="0" [max]="15" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    <small class="text-surface-500">0 usa o padrão da região/servidor.</small>
                                </div>
                            }
                            @if (!template) {
                                <div class="md:col-span-2">
                                    <label class="block font-medium mb-2">Data rates de uplink suportados</label>
                                    <p-multiselect [options]="dataRates" optionLabel="label" optionValue="value" [(ngModel)]="form.supportedUplinkDataRates" placeholder="Padrão da região (DR mínimo a máximo)" display="chip" [maxSelectedLabels]="16" [showToggleAll]="true" styleClass="w-full" [disabled]="!podeEditar()" />
                                    <small class="text-surface-500">Deixe vazio para usar os data rates padrão da região. Preencha para incluir data rates extras (ex.: SF5/SF6 na EU868: DR0–7, 12 e 13).</small>
                                </div>
                            }
                            <div class="md:col-span-2 flex flex-col gap-3">
                                <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.flushQueueOnActivate" [disabled]="!podeEditar()" /> Limpar a fila de downlink ao (re)ativar</label>
                                @if (!template) {
                                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.allowRoaming" [disabled]="!podeEditar()" /> Permitir roaming</label>
                                }
                            </div>
                        </fieldset>
                    </p-tabpanel>

                    <!-- Join -->
                    <p-tabpanel value="join">
                        <div class="max-w-4xl flex flex-col gap-5">
                            <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.supportsOtaa" [disabled]="!podeEditar()" /> O dispositivo suporta OTAA (join)</label>
                            @if (!form.supportsOtaa) {
                                <p-message severity="info" text="Parâmetros usados pelos dispositivos ABP (sem join)." styleClass="w-full" />
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                                    <div>
                                        <label class="block font-medium mb-2">RX1 delay (s)</label>
                                        <p-inputnumber [(ngModel)]="form.abpRx1Delay" [min]="0" [max]="15" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">RX1 DR offset</label>
                                        <p-inputnumber [(ngModel)]="form.abpRx1DrOffset" [min]="0" [max]="7" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">RX2 data rate</label>
                                        <p-inputnumber [(ngModel)]="form.abpRx2Dr" [min]="0" [max]="15" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">RX2 frequência (Hz)</label>
                                        <p-inputnumber [(ngModel)]="form.abpRx2Freq" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" placeholder="923300000" />
                                    </div>
                                </div>
                            }
                        </div>
                    </p-tabpanel>

                    <!-- Classe B -->
                    <p-tabpanel value="classeb">
                        <div class="max-w-4xl flex flex-col gap-5">
                            <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.supportsClassB" [disabled]="!podeEditar()" /> O dispositivo suporta classe B</label>
                            @if (form.supportsClassB) {
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                                    <div>
                                        <label class="block font-medium mb-2">Timeout de confirmação (s)</label>
                                        <p-inputnumber [(ngModel)]="form.classBTimeout" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">Periodicidade do ping-slot</label>
                                        <p-select [options]="periodicidades" optionLabel="label" optionValue="value" [(ngModel)]="form.classBPingSlotPeriodicity" styleClass="w-full" [disabled]="!podeEditar()" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">Data rate do ping-slot</label>
                                        <p-inputnumber [(ngModel)]="form.classBPingSlotDr" [min]="0" [max]="15" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    </div>
                                    <div>
                                        <label class="block font-medium mb-2">Frequência do ping-slot (Hz)</label>
                                        <p-inputnumber [(ngModel)]="form.classBPingSlotFreq" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        <small class="text-surface-500">0 usa o salto de frequência padrão.</small>
                                    </div>
                                </div>
                                @if (!template) {
                                    <div>
                                        <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.classBDownlinkOnly" [disabled]="!podeEditar()" /> Payload de aplicação somente pelos ping slots da classe B</label>
                                        <small class="text-surface-500 block mt-1 ml-14">Em classe B, a resposta a um uplink classe A leva só mac-commands. Evita downlinks fora de ordem entre ping slot e janela RX.</small>
                                    </div>
                                }
                            }
                        </div>
                    </p-tabpanel>

                    <!-- Classe C -->
                    <p-tabpanel value="classec">
                        <div class="max-w-4xl flex flex-col gap-5">
                            <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.supportsClassC" [disabled]="!podeEditar()" /> O dispositivo suporta classe C</label>
                            @if (form.supportsClassC) {
                                <div class="max-w-sm">
                                    <label class="block font-medium mb-2">Timeout de confirmação (s)</label>
                                    <p-inputnumber [(ngModel)]="form.classCTimeout" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                    <small class="text-surface-500">Tempo de espera pelo ACK de um downlink confirmado.</small>
                                </div>
                            }
                        </div>
                    </p-tabpanel>

                    <!-- Codec -->
                    <p-tabpanel value="codec">
                        <div class="flex flex-col gap-5">
                            <div class="flex flex-wrap items-end gap-3">
                                <div class="w-72">
                                    <label class="block font-medium mb-2">Codec do payload</label>
                                    <p-select [options]="codecs" optionLabel="label" optionValue="value" [(ngModel)]="form.payloadCodecRuntime" styleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                                @if (form.payloadCodecRuntime === 'JS' && podeEditar()) {
                                    <p-button label="Inserir exemplo" icon="pi pi-code" severity="secondary" [outlined]="true" (onClick)="exemploCodec()" />
                                }
                            </div>
                            @if (form.payloadCodecRuntime === 'JS') {
                                <textarea pTextarea class="w-full font-mono text-sm leading-relaxed" rows="22" spellcheck="false" [(ngModel)]="form.payloadCodecScript" [readonly]="!podeEditar()"></textarea>
                                <small class="text-surface-500">Funções <code>decodeUplink(input)</code> e <code>encodeDownlink(input)</code> executadas pelo ChirpStack (QuickJS).</small>
                            }
                            @if (form.payloadCodecRuntime === 'CAYENNE_LPP') {
                                <p-message severity="info" text="Os uplinks serão decodificados no formato Cayenne LPP." styleClass="w-full" />
                            }
                        </div>
                    </p-tabpanel>

                    <!-- Medições -->
                    <p-tabpanel value="medicoes">
                        <div class="flex flex-col gap-4 max-w-5xl">
                            <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.autoDetectMeasurements" [disabled]="!podeEditar()" /> Detectar medições automaticamente a partir do objeto decodificado</label>
                            <p class="text-surface-500 text-sm m-0">As medições viram gráficos na tela do dispositivo. A chave é o caminho no objeto decodificado (ex.: <code>temperatura</code> ou <code>sensores_0_valor</code>).</p>
                            <p-table [value]="medicoes()">
                                <ng-template #header>
                                    <tr><th>Chave</th><th>Nome</th><th>Tipo</th><th class="w-16"></th></tr>
                                </ng-template>
                                <ng-template #body let-m let-i="rowIndex">
                                    <tr>
                                        <td><input pInputText class="w-full font-mono" [(ngModel)]="m.chave" [disabled]="!podeEditar()" /></td>
                                        <td><input pInputText class="w-full" [(ngModel)]="m.name" [disabled]="!podeEditar()" /></td>
                                        <td><p-select [options]="tiposMedicao" optionLabel="label" optionValue="value" [(ngModel)]="m.kind" styleClass="w-full" appendTo="body" [disabled]="!podeEditar()" /></td>
                                        <td>
                                            @if (podeEditar()) {
                                                <p-button icon="pi pi-trash" severity="danger" [text]="true" [rounded]="true" (onClick)="removerMedicao(i)" />
                                            }
                                        </td>
                                    </tr>
                                </ng-template>
                                <ng-template #emptymessage>
                                    <tr><td colspan="4" class="text-center py-6 text-surface-500">Nenhuma medição configurada.</td></tr>
                                </ng-template>
                            </p-table>
                            @if (podeEditar()) {
                                <div><p-button label="Adicionar medição" icon="pi pi-plus" size="small" severity="secondary" [outlined]="true" (onClick)="adicionarMedicao()" /></div>
                            }
                        </div>
                    </p-tabpanel>

                    @if (!template) {
                        <!-- Relay -->
                        <p-tabpanel value="relay">
                            <div class="flex flex-col gap-5 max-w-5xl">
                                <div class="flex flex-col gap-3">
                                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.isRelay" [disabled]="!podeEditar()" /> O dispositivo é um relay (TS011)</label>
                                    <label class="flex items-center gap-3"><p-toggleswitch [(ngModel)]="form.isRelayEd" [disabled]="!podeEditar()" /> O dispositivo pode operar através de um relay</label>
                                </div>
                                @if (form.isRelay) {
                                    <div class="font-semibold mt-2">Relay</div>
                                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                                        <label class="flex items-center gap-3 md:col-span-3"><p-toggleswitch [(ngModel)]="form.relayEnabled" [disabled]="!podeEditar()" /> Relay habilitado</label>
                                        <div>
                                            <label class="block font-medium mb-2">Periodicidade do CAD</label>
                                            <p-select [options]="relayCad" optionLabel="label" optionValue="value" [(ngModel)]="form.relayCadPeriodicity" styleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">Canal padrão (índice)</label>
                                            <p-inputnumber [(ngModel)]="form.relayDefaultChannelIndex" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">2º canal: frequência (Hz)</label>
                                            <p-inputnumber [(ngModel)]="form.relaySecondChannelFreq" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">2º canal: data rate</label>
                                            <p-inputnumber [(ngModel)]="form.relaySecondChannelDr" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">2º canal: offset do ACK</label>
                                            <p-select [options]="relayAck" optionLabel="label" optionValue="value" [(ngModel)]="form.relaySecondChannelAckOffset" styleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                    </div>
                                    <div class="font-semibold mt-2">Limites do relay (bucket / reload rate)</div>
                                    <div class="grid grid-cols-2 md:grid-cols-4 gap-5">
                                        @for (l of limitesRelay; track l.campo) {
                                            <div>
                                                <label class="block text-sm font-medium mb-2">{{ l.rotulo }}</label>
                                                <p-inputnumber [(ngModel)]="$any(form)[l.campo]" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                            </div>
                                        }
                                    </div>
                                }
                                @if (form.isRelayEd) {
                                    <div class="font-semibold mt-2">Dispositivo atrás de relay</div>
                                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                                        <label class="flex items-center gap-3 md:col-span-3"><p-toggleswitch [(ngModel)]="form.relayEdRelayOnly" [disabled]="!podeEditar()" /> Somente através de relay</label>
                                        <div>
                                            <label class="block font-medium mb-2">Modo de ativação</label>
                                            <p-select [options]="relayAtivacao" optionLabel="label" optionValue="value" [(ngModel)]="form.relayEdActivationMode" styleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">Smart enable level</label>
                                            <p-inputnumber [(ngModel)]="form.relayEdSmartEnableLevel" [min]="0" [max]="3" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">Back-off</label>
                                            <p-inputnumber [(ngModel)]="form.relayEdBackOff" [min]="0" [max]="63" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">Uplink limit: bucket</label>
                                            <p-inputnumber [(ngModel)]="form.relayEdUplinkLimitBucketSize" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                        <div>
                                            <label class="block font-medium mb-2">Uplink limit: reload rate</label>
                                            <p-inputnumber [(ngModel)]="form.relayEdUplinkLimitReloadRate" [min]="0" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                        </div>
                                    </div>
                                }
                            </div>
                        </p-tabpanel>

                        <!-- Camada de aplicação -->
                        <p-tabpanel value="aplicacao">
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-4xl">
                                <div>
                                    <label class="block font-medium mb-2">TS003 · sincronização de relógio</label>
                                    <p-select [options]="ts003" optionLabel="label" optionValue="value" [(ngModel)]="form.appLayerParams!.ts003Version" styleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">TS003 · FPort</label>
                                    <p-inputnumber [(ngModel)]="form.appLayerParams!.ts003FPort" [min]="1" [max]="223" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">TS004 · fragmentação (FUOTA)</label>
                                    <p-select [options]="ts004" optionLabel="label" optionValue="value" [(ngModel)]="form.appLayerParams!.ts004Version" styleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">TS004 · FPort</label>
                                    <p-inputnumber [(ngModel)]="form.appLayerParams!.ts004FPort" [min]="1" [max]="223" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">TS005 · multicast remoto</label>
                                    <p-select [options]="ts005" optionLabel="label" optionValue="value" [(ngModel)]="form.appLayerParams!.ts005Version" styleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                                <div>
                                    <label class="block font-medium mb-2">TS005 · FPort</label>
                                    <p-inputnumber [(ngModel)]="form.appLayerParams!.ts005FPort" [min]="1" [max]="223" [useGrouping]="false" styleClass="w-full" inputStyleClass="w-full" [disabled]="!podeEditar()" />
                                </div>
                            </div>
                        </p-tabpanel>
                    }

                    <!-- Tags -->
                    <p-tabpanel value="tags">
                        <div class="max-w-3xl">
                            <app-tags-editor label="Tags" hint="Copiadas para os eventos dos dispositivos que usam este perfil." [(value)]="form.tags" [disabled]="!podeEditar()" />
                        </div>
                    </p-tabpanel>
                </p-tabpanels>
            </p-tabs>
        </div>

        <p-dialog [(visible)]="dialogoTemplates" header="Importar de template" [modal]="true" [style]="{ width: '50rem' }" [breakpoints]="{ '768px': '95vw' }">
            <p-table [value]="templates()" [paginator]="templates().length > 8" [rows]="8" selectionMode="single" (onRowSelect)="importar($any($event.data))" dataKey="id">
                <ng-template #header><tr><th>Nome</th><th>Fabricante</th><th>Firmware</th><th>Região</th></tr></ng-template>
                <ng-template #body let-t>
                    <tr [pSelectableRow]="t" class="cursor-pointer">
                        <td>{{ t.name }}</td>
                        <td>{{ t.vendor }}</td>
                        <td>{{ t.firmware }}</td>
                        <td>{{ t.region }}</td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage><tr><td colspan="4" class="text-center py-6 text-surface-500">Nenhum template cadastrado.</td></tr></ng-template>
            </p-table>
        </p-dialog>
    `
})
export class DeviceProfileForm implements OnInit {
    id = input<string>();

    private api = inject(ChirpstackService);
    private notify = inject(NotifyService);
    private router = inject(Router);
    private route = inject(ActivatedRoute);
    ctx = inject(TenantContextService);
    auth = inject(AuthService);

    readonly template = this.route.snapshot.data['modo'] === 'template';
    /** Perfil global (sem tenant, vindo do catálogo): vale para todos os tenants e só o ADMIN altera. */
    global = signal(false);
    catalogo = signal<{ fabricante: string; modelo: string } | null>(null);
    podeEditar = computed(() => (this.template || this.global() ? this.auth.isAdmin() : this.auth.podeEscrever()));
    dataRates = Array.from({ length: 16 }, (_, i) => ({ label: `DR${i}`, value: i }));
    titulo = computed(() => {
        const base = this.template ? 'template' : 'perfil de dispositivo';
        return this.id() ? (this.podeEditar() ? `Editar ${base}` : this.form.name || base) : `Novo ${base}`;
    });

    regioes = REGIOES;
    versoes = VERSOES_MAC;
    revisoes = REVISOES_PARAMETROS;
    codecs = CODECS;
    periodicidades = PERIODICIDADE_PING_SLOT;
    tiposMedicao = TIPOS_MEDICAO;
    relayCad = RELAY_CAD;
    relayAck = RELAY_ACK_OFFSET;
    relayAtivacao = RELAY_ATIVACAO;
    ts003 = TS003;
    ts004 = TS004;
    ts005 = TS005;
    limitesRelay = [
        { campo: 'relayJoinReqLimitBucketSize', rotulo: 'Join-request: bucket' },
        { campo: 'relayJoinReqLimitReloadRate', rotulo: 'Join-request: reload' },
        { campo: 'relayNotifyLimitBucketSize', rotulo: 'Notify: bucket' },
        { campo: 'relayNotifyLimitReloadRate', rotulo: 'Notify: reload' },
        { campo: 'relayGlobalUplinkLimitBucketSize', rotulo: 'Uplink global: bucket' },
        { campo: 'relayGlobalUplinkLimitReloadRate', rotulo: 'Uplink global: reload' },
        { campo: 'relayOverallLimitBucketSize', rotulo: 'Geral: bucket' },
        { campo: 'relayOverallLimitReloadRate', rotulo: 'Geral: reload' }
    ];

    adr = signal<AdrAlgorithm[]>([]);
    medicoes = signal<LinhaMedicao[]>([]);
    templates = signal<DeviceProfileListItem[]>([]);
    salvando = signal(false);
    dialogoTemplates = signal(false);
    form: DeviceProfile = novoPerfil();
    templateId = '';

    ngOnInit(): void {
        this.form = novoPerfil(this.ctx.tenantId() ?? '');
        this.api.listAdrAlgorithms().subscribe({ next: (r) => this.adr.set(r.result) });
        const id = this.id();
        if (id) {
            const op: Observable<DeviceProfile> = this.template
                ? this.api.getDeviceProfileTemplate(id).pipe(map((r) => r.deviceProfileTemplate))
                : this.api.getDeviceProfile(id).pipe(map((r) => r.deviceProfile));
            op.subscribe({
                next: (dp) => {
                    this.aplicar(dp);
                    this.templateId = id;
                    if (!this.template) {
                        this.global.set(!dp.tenantId);
                        this.carregarCatalogo(dp.deviceId);
                    }
                },
                error: (e) => this.notify.erro(e)
            });
        }
    }

    private aplicar(dp: DeviceProfile, manterIdentidade = false): void {
        const base = novoPerfil(this.form.tenantId);
        const novo: DeviceProfile = { ...base, ...dp, supportedUplinkDataRates: (dp.supportedUplinkDataRates ?? []).map((v) => num(v)), appLayerParams: { ...base.appLayerParams, ...(dp.appLayerParams ?? {}) }, tags: { ...(dp.tags ?? {}) } };
        for (const k of NUMERICOS) {
            (novo as unknown as Record<string, number>)[k] = num((dp as unknown as Record<string, number | string>)[k] ?? (base as unknown as Record<string, number>)[k]);
        }
        if (manterIdentidade) {
            novo.tenantId = this.form.tenantId;
            novo.id = undefined;
            novo.deviceId = undefined;
            novo.firmwareVersion = undefined;
        }
        this.form = novo;
        this.medicoes.set(Object.entries(dp.measurements ?? {}).map(([chave, m]) => ({ chave, name: m.name, kind: m.kind })));
    }

    /** Nome do fabricante e do modelo do catálogo a que o perfil está vinculado. */
    private carregarCatalogo(deviceId?: string): void {
        if (!deviceId) {
            this.catalogo.set(null);
            return;
        }
        this.catalogo.set({ fabricante: '', modelo: '' });
        this.api.getDeviceProfileDevice(deviceId).subscribe({
            next: (r) => {
                this.catalogo.set({ fabricante: '', modelo: r.device.name });
                this.api.getDeviceProfileVendor(r.device.vendorId).subscribe({
                    next: (v) => this.catalogo.update((c) => ({ modelo: c?.modelo ?? '', fabricante: v.vendor.name })),
                    error: () => undefined
                });
            },
            error: () => undefined
        });
    }

    exemploCodec(): void {
        if (!this.form.payloadCodecScript?.trim() || confirm('Substituir o script atual pelo exemplo?')) {
            this.form.payloadCodecScript = CODEC_EXEMPLO;
        }
    }

    adicionarMedicao(): void {
        this.medicoes.update((l) => [...l, { chave: '', name: '', kind: 'GAUGE' }]);
    }

    removerMedicao(i: number): void {
        this.medicoes.update((l) => l.filter((_, idx) => idx !== i));
    }

    abrirTemplates(): void {
        this.api.listDeviceProfileTemplates({ limit: 1000 }).subscribe({
            next: (r) => {
                this.templates.set(r.result);
                this.dialogoTemplates.set(true);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    importar(t: DeviceProfileListItem): void {
        this.api.getDeviceProfileTemplate(t.id).subscribe({
            next: (r) => {
                this.aplicar(r.deviceProfileTemplate, true);
                this.dialogoTemplates.set(false);
                this.notify.info(`Configuração do template "${t.name}" importada. Revise e salve.`);
            },
            error: (e) => this.notify.erro(e)
        });
    }

    salvar(): void {
        if (!this.form.name.trim()) {
            this.notify.aviso('Informe o nome.');
            return;
        }
        if (this.template && (!this.templateId.trim() || !this.form.vendor?.trim() || !this.form.firmware?.trim())) {
            this.notify.aviso('Informe o ID, o fabricante e o firmware do template.');
            return;
        }
        if (this.form.payloadCodecRuntime === 'JS' && !this.form.payloadCodecScript?.trim()) {
            this.notify.aviso('Escreva o script do codec JavaScript.');
            return;
        }
        const measurements: Record<string, Measurement> = {};
        for (const m of this.medicoes()) {
            if (m.chave.trim()) {
                measurements[m.chave.trim()] = { name: m.name.trim() || m.chave.trim(), kind: m.kind };
            }
        }
        const dados: DeviceProfile = { ...this.form, name: this.form.name.trim(), measurements };
        const id = this.id();
        this.salvando.set(true);

        let op: Observable<unknown>;
        if (this.template) {
            const { tenantId: _t, regionConfigId: _r, allowRoaming: _a, appLayerParams: _p, ...resto } = dados;
            const tpl = { ...resto, id: this.templateId.trim() } as DeviceProfile;
            delete (tpl as unknown as Record<string, unknown>)['createdAt'];
            delete (tpl as unknown as Record<string, unknown>)['updatedAt'];
            for (const k of Object.keys(tpl)) {
                if (k.startsWith('relay') || ['isRelay', 'isRelayEd', 'rx1Delay', 'deviceId', 'firmwareVersion', 'supportedUplinkDataRates', 'classBDownlinkOnly'].includes(k)) {
                    delete (tpl as unknown as Record<string, unknown>)[k];
                }
            }
            op = id ? this.api.updateDeviceProfileTemplate(id, tpl) : this.api.createDeviceProfileTemplate(tpl);
        } else {
            // vendor/firmware só existem em templates; datas são somente leitura.
            const { vendor: _v, firmware: _f, ...perfil } = dados as DeviceProfile & { createdAt?: string; updatedAt?: string };
            delete (perfil as Record<string, unknown>)['createdAt'];
            delete (perfil as Record<string, unknown>)['updatedAt'];
            // Perfil global continua sem tenant; perfil novo vai para o tenant selecionado.
            perfil.tenantId = this.global() ? '' : perfil.tenantId || this.ctx.tenantId() || '';
            perfil.supportedUplinkDataRates = [...(perfil.supportedUplinkDataRates ?? [])].sort((a, b) => a - b);
            op = id ? this.api.updateDeviceProfile(id, perfil) : this.api.createDeviceProfile(perfil);
        }
        op.subscribe({
            next: (r) => {
                this.salvando.set(false);
                this.notify.sucesso('Salvo com sucesso.');
                if (!id) {
                    const novoId = this.template ? this.templateId.trim() : (r as { id: string }).id;
                    this.router.navigate([this.template ? '/templates-perfil' : '/perfis-dispositivo', novoId], { replaceUrl: true });
                }
            },
            error: (e) => {
                this.salvando.set(false);
                this.notify.erro(e);
            }
        });
    }

    voltar(): void {
        this.router.navigate([this.template ? '/templates-perfil' : '/perfis-dispositivo']);
    }
}
