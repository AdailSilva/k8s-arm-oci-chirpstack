/**
 * Tipos da REST API do ChirpStack v4.15 (chirpstack-rest-api).
 * Inteiros de 64 bits chegam como texto (protojson); por isso vários campos aceitam string | number.
 */

export type Int64 = number | string;
export type Tags = Record<string, string>;

export interface ListResponse<T> {
    result: T[];
    totalCount: Int64;
}

export interface IdResponse {
    id: string;
}

// ------------------------------------------------------------------ enums

export type Region = 'EU868' | 'US915' | 'CN779' | 'EU433' | 'AU915' | 'CN470' | 'AS923' | 'AS923_2' | 'AS923_3' | 'AS923_4' | 'KR920' | 'IN865' | 'RU864' | 'ISM2400';
export type MacVersion = 'LORAWAN_1_0_0' | 'LORAWAN_1_0_1' | 'LORAWAN_1_0_2' | 'LORAWAN_1_0_3' | 'LORAWAN_1_0_4' | 'LORAWAN_1_1_0';
export type RegParamsRevision = 'A' | 'B' | 'RP002_1_0_0' | 'RP002_1_0_1' | 'RP002_1_0_2' | 'RP002_1_0_3' | 'RP002_1_0_4';
export type CodecRuntime = 'NONE' | 'CAYENNE_LPP' | 'JS';
export type GatewayState = 'NEVER_SEEN' | 'ONLINE' | 'OFFLINE';
export type DeviceClass = 'CLASS_A' | 'CLASS_B' | 'CLASS_C';
export type Aggregation = 'HOUR' | 'DAY' | 'MONTH' | 'MINUTE';
export type Encoding = 'JSON' | 'PROTOBUF';
export type MeasurementKind = 'UNKNOWN' | 'COUNTER' | 'ABSOLUTE' | 'GAUGE' | 'STRING';
export type MulticastGroupType = 'CLASS_C' | 'CLASS_B';
export type MulticastSchedulingType = 'DELAY' | 'GPS_TIME';
export type LocationSource = 'UNKNOWN' | 'GPS' | 'CONFIG' | 'GEO_RESOLVER_TDOA' | 'GEO_RESOLVER_RSSI' | 'GEO_RESOLVER_GNSS' | 'GEO_RESOLVER_WIFI';
export type IntegrationKind = 'HTTP' | 'INFLUX_DB' | 'THINGS_BOARD' | 'MY_DEVICES' | 'GCP_PUB_SUB' | 'AWS_SNS' | 'AZURE_SERVICE_BUS' | 'PILOT_THINGS' | 'MQTT_GLOBAL' | 'IFTTT' | 'BLYNK';
export type RelayModeActivation = 'DISABLE_RELAY_MODE' | 'ENABLE_RELAY_MODE' | 'DYNAMIC' | 'END_DEVICE_CONTROLLED';
export type CadPeriodicity = 'SEC_1' | 'MS_500' | 'MS_250' | 'MS_100' | 'MS_50' | 'MS_20';
export type SecondChAckOffset = 'KHZ_0' | 'KHZ_200' | 'KHZ_400' | 'KHZ_800' | 'KHZ_1600' | 'KHZ_3200';
export type Ts003Version = 'TS003_NOT_IMPLEMENTED' | 'TS003_V100' | 'TS003_v200';
export type Ts004Version = 'TS004_NOT_IMPLEMENTED' | 'TS004_V100' | 'TS004_V200';
export type Ts005Version = 'TS005_NOT_IMPLEMENTED' | 'TS005_V100' | 'TS005_V200';
export type InfluxDbVersion = 'INFLUXDB_1' | 'INFLUXDB_2' | 'INFLUXDB_3';
export type InfluxDbPrecision = 'NS' | 'U' | 'MS' | 'S' | 'M' | 'H';

// ------------------------------------------------------------------ tenants

export interface Tenant {
    id?: string;
    name: string;
    description: string;
    canHaveGateways: boolean;
    maxGatewayCount: Int64;
    maxDeviceCount: Int64;
    privateGatewaysUp: boolean;
    privateGatewaysDown: boolean;
    tags: Tags;
    /** 4.19+: prefixos de DevAddr reservados ao tenant, ex.: "0000ff00/24". Vazio = usa os da rede. */
    devAddrPrefixes?: string[];
}

export interface TenantListItem {
    id: string;
    name: string;
    canHaveGateways: boolean;
    privateGatewaysUp: boolean;
    privateGatewaysDown: boolean;
    maxGatewayCount: Int64;
    maxDeviceCount: Int64;
    createdAt: string;
    updatedAt: string;
}

export interface GetTenantResponse {
    tenant: Tenant;
    createdAt: string;
    updatedAt: string;
}

export interface TenantUser {
    tenantId?: string;
    userId: string;
    email: string;
    isAdmin: boolean;
    isDeviceAdmin: boolean;
    isGatewayAdmin: boolean;
}

export interface TenantUserListItem extends TenantUser {
    createdAt: string;
    updatedAt: string;
}

export interface GetTenantUserResponse {
    tenantUser: TenantUser;
    createdAt: string;
    updatedAt: string;
}

// ------------------------------------------------------------------ users (ChirpStack)

export interface CsUser {
    id?: string;
    email: string;
    isActive: boolean;
    isAdmin: boolean;
    note: string;
}

export interface CsUserListItem {
    id: string;
    email: string;
    isActive: boolean;
    isAdmin: boolean;
    createdAt: string;
    updatedAt: string;
}

export interface UserTenant {
    tenantId: string;
    isAdmin: boolean;
    isDeviceAdmin: boolean;
    isGatewayAdmin: boolean;
}

export interface GetCsUserResponse {
    user: CsUser;
    createdAt: string;
    updatedAt: string;
}

// ------------------------------------------------------------------ applications

export interface Application {
    id?: string;
    name: string;
    description: string;
    tenantId: string;
    tags: Tags;
}

export interface ApplicationListItem {
    id: string;
    name: string;
    description: string;
    createdAt: string;
    updatedAt: string;
}

export interface GetApplicationResponse {
    application: Application;
    createdAt: string;
    updatedAt: string;
    measurementKeys: string[];
}

export interface IntegrationListItem {
    kind: IntegrationKind;
}

export interface CertificateResponse {
    tlsCert: string;
    tlsKey: string;
    caCert: string;
    expiresAt: string;
}

// ------------------------------------------------------------------ device profiles

export interface Measurement {
    name: string;
    kind: MeasurementKind;
}

export interface AppLayerParams {
    ts003Version?: Ts003Version;
    ts003FPort?: number;
    ts004Version?: Ts004Version;
    ts004FPort?: number;
    ts005Version?: Ts005Version;
    ts005FPort?: number;
}

export interface DeviceProfile {
    id?: string;
    tenantId: string;
    name: string;
    description: string;
    region: Region;
    regionConfigId?: string;
    macVersion: MacVersion;
    regParamsRevision: RegParamsRevision;
    adrAlgorithmId: string;
    payloadCodecRuntime: CodecRuntime;
    payloadCodecScript: string;
    flushQueueOnActivate: boolean;
    uplinkInterval: number;
    deviceStatusReqInterval: number;
    supportsOtaa: boolean;
    supportsClassB: boolean;
    supportsClassC: boolean;
    classBTimeout: number;
    classBPingSlotPeriodicity: number;
    classBPingSlotDr: number;
    classBPingSlotFreq: number;
    classCTimeout: number;
    abpRx1Delay: number;
    abpRx1DrOffset: number;
    abpRx2Dr: number;
    abpRx2Freq: number;
    tags: Tags;
    measurements: Record<string, Measurement>;
    autoDetectMeasurements: boolean;
    allowRoaming: boolean;
    rx1Delay: number;
    appLayerParams?: AppLayerParams;
    isRelay: boolean;
    isRelayEd: boolean;
    relayEdRelayOnly: boolean;
    relayEnabled: boolean;
    relayCadPeriodicity: CadPeriodicity;
    relayDefaultChannelIndex: number;
    relaySecondChannelFreq: number;
    relaySecondChannelDr: number;
    relaySecondChannelAckOffset: SecondChAckOffset;
    relayEdActivationMode: RelayModeActivation;
    relayEdSmartEnableLevel: number;
    relayEdBackOff: number;
    relayEdUplinkLimitBucketSize: number;
    relayEdUplinkLimitReloadRate: number;
    relayJoinReqLimitReloadRate: number;
    relayNotifyLimitReloadRate: number;
    relayGlobalUplinkLimitReloadRate: number;
    relayOverallLimitReloadRate: number;
    relayJoinReqLimitBucketSize: number;
    relayNotifyLimitBucketSize: number;
    relayGlobalUplinkLimitBucketSize: number;
    relayOverallLimitBucketSize: number;
    /** 4.19+: modelo do catálogo de dispositivos ao qual o perfil pertence. */
    deviceId?: string;
    /** 4.19+: versão de firmware à qual o perfil se aplica. */
    firmwareVersion?: string;
    /** 4.19+: data rates de uplink suportados pelo dispositivo (vazio = todos da região). */
    supportedUplinkDataRates?: number[];
    /** 4.19+: classe B só para downlink (o dispositivo não usa ping slots para uplink). */
    classBDownlinkOnly?: boolean;
    /** Somente em templates. */
    vendor?: string;
    firmware?: string;
}

export interface DeviceProfileListItem {
    id: string;
    name: string;
    region: Region;
    macVersion: MacVersion;
    regParamsRevision: RegParamsRevision;
    supportsOtaa: boolean;
    supportsClassB: boolean;
    supportsClassC: boolean;
    createdAt: string;
    updatedAt: string;
    vendor?: string;
    firmware?: string;
    /** 4.19+: preenchidos quando o perfil é do catálogo de dispositivos. */
    vendorId?: string;
    vendorName?: string;
    deviceId?: string;
    deviceName?: string;
    firmwareVersion?: string;
}

export interface GetDeviceProfileByProfileIdResponse {
    deviceProfile: DeviceProfile;
    createdAt: string;
    updatedAt: string;
}

// ------------------------------------------------------------------ catálogo de dispositivos (4.19+)

export interface DeviceProfileVendor {
    id: string;
    name: string;
    /** LoRa Alliance Vendor ID. */
    vendorId: number;
    ouis: string[];
    metadata: Tags;
}

export interface DeviceProfileVendorListItem extends DeviceProfileVendor {
    createdAt: string;
    updatedAt: string;
}

export interface GetDeviceProfileVendorResponse {
    vendor: DeviceProfileVendor;
    createdAt: string;
    updatedAt: string;
}

export interface DeviceProfileDevice {
    id: string;
    vendorId: string;
    name: string;
    description: string;
    metadata: Tags;
}

export interface DeviceProfileDeviceListItem {
    id: string;
    name: string;
    createdAt: string;
    updatedAt: string;
}

export interface GetDeviceProfileDeviceResponse {
    device: DeviceProfileDevice;
    createdAt: string;
    updatedAt: string;
}

// ------------------------------------------------------------------ relays (TS011, 4.19+)

export interface RelayListItem {
    devEui: string;
    name: string;
}

export interface RelayDeviceListItem {
    devEui: string;
    name: string;
    createdAt: string;
}

export interface GetDeviceProfileResponse {
    deviceProfile: DeviceProfile;
    createdAt: string;
    updatedAt: string;
}

export interface GetDeviceProfileTemplateResponse {
    deviceProfileTemplate: DeviceProfile;
    createdAt: string;
    updatedAt: string;
}

export interface AdrAlgorithm {
    id: string;
    name: string;
}

// ------------------------------------------------------------------ devices

export interface Device {
    devEui: string;
    name: string;
    description: string;
    applicationId: string;
    deviceProfileId: string;
    skipFcntCheck: boolean;
    isDisabled: boolean;
    variables: Tags;
    tags: Tags;
    joinEui: string;
}

export interface DeviceStatus {
    margin: number;
    externalPowerSource: boolean;
    batteryLevel: number;
}

export interface DeviceListItem {
    devEui: string;
    name: string;
    description: string;
    deviceProfileId: string;
    deviceProfileName: string;
    deviceStatus?: DeviceStatus;
    lastSeenAt?: string;
    createdAt: string;
    updatedAt: string;
    tags: Tags;
}

export interface GetDeviceResponse {
    device: Device;
    createdAt: string;
    updatedAt: string;
    lastSeenAt?: string;
    deviceStatus?: DeviceStatus;
    classEnabled: DeviceClass;
}

export interface DeviceKeys {
    devEui?: string;
    nwkKey: string;
    appKey: string;
    genAppKey: string;
}

export interface GetDeviceKeysResponse {
    deviceKeys: DeviceKeys;
    createdAt: string;
    updatedAt: string;
}

export interface DeviceActivation {
    devEui?: string;
    devAddr: string;
    appSKey: string;
    nwkSEncKey: string;
    sNwkSIntKey: string;
    fNwkSIntKey: string;
    fCntUp: number;
    nFCntDown: number;
    aFCntDown: number;
}

export interface GetDeviceActivationResponse {
    deviceActivation?: DeviceActivation | null;
    joinServerContext?: unknown;
}

export interface DeviceQueueItem {
    id?: string;
    devEui?: string;
    confirmed: boolean;
    fPort: number;
    data?: string;
    object?: unknown;
    isPending?: boolean;
    fCntDown?: Int64;
    isEncrypted?: boolean;
    expiresAt?: string | null;
}

export interface GetDeviceQueueItemsResponse {
    result: DeviceQueueItem[];
    totalCount: Int64;
}

// ------------------------------------------------------------------ métricas

export interface MetricDataset {
    label: string;
    data: number[];
}

export interface Metric {
    name: string;
    timestamps: string[];
    datasets: MetricDataset[];
    kind: 'COUNTER' | 'ABSOLUTE' | 'GAUGE';
}

export interface GetDeviceMetricsResponse {
    metrics: Record<string, Metric>;
    states: Record<string, { name: string; value: string }>;
}

export interface GetDeviceLinkMetricsResponse {
    rxPackets: Metric;
    gwRssi: Metric;
    gwSnr: Metric;
    rxPacketsPerFreq: Metric;
    rxPacketsPerDr: Metric;
    errors: Metric;
}

export interface GetGatewayMetricsResponse {
    rxPackets: Metric;
    txPackets: Metric;
    txPacketsPerFreq: Metric;
    rxPacketsPerFreq: Metric;
    txPacketsPerDr: Metric;
    rxPacketsPerDr: Metric;
    txPacketsPerStatus: Metric;
}

export interface GetGatewayDutyCycleMetricsResponse {
    maxLoadPercentage: Metric;
    windowPercentage: Metric;
}

// ------------------------------------------------------------------ gateways

export interface Location {
    latitude: number;
    longitude: number;
    altitude: number;
    source?: LocationSource;
    accuracy?: number;
}

export interface Gateway {
    gatewayId: string;
    name: string;
    description: string;
    location: Location;
    tenantId: string;
    tags: Tags;
    metadata?: Tags;
    statsInterval: number;
    /** 4.19+: prioridade de downlink (menor = preferido quando vários gateways recebem o uplink). */
    downlinkPriority?: number;
}

export interface GatewayListItem {
    tenantId: string;
    gatewayId: string;
    name: string;
    description: string;
    location?: Location;
    properties?: Tags;
    createdAt: string;
    updatedAt: string;
    lastSeenAt?: string;
    state: GatewayState;
    downlinkPriority?: number;
}

export interface GetGatewayResponse {
    gateway: Gateway;
    createdAt: string;
    updatedAt: string;
    lastSeenAt?: string;
}

export interface RelayGateway {
    tenantId: string;
    relayId: string;
    name: string;
    description: string;
    statsInterval: number;
    regionConfigId: string;
}

export interface RelayGatewayListItem extends RelayGateway {
    createdAt: string;
    updatedAt: string;
    lastSeenAt?: string;
    state: GatewayState;
}

export interface GetRelayGatewayResponse {
    relayGateway: RelayGateway;
    createdAt: string;
    updatedAt: string;
    lastSeenAt?: string;
}

// ------------------------------------------------------------------ multicast

export interface MulticastGroup {
    id?: string;
    name: string;
    applicationId: string;
    region: Region;
    mcAddr: string;
    mcNwkSKey: string;
    mcAppSKey: string;
    fCnt: number;
    groupType: MulticastGroupType;
    dr: number;
    frequency: number;
    classBPingSlotPeriodicity: number;
    classCSchedulingType: MulticastSchedulingType;
}

export interface MulticastGroupListItem {
    id: string;
    name: string;
    region: Region;
    groupType: MulticastGroupType;
    createdAt: string;
    updatedAt: string;
    /** 4.19+: aplicação dona do grupo (útil na listagem por tenant). */
    applicationId?: string;
    applicationName?: string;
}

export interface GetMulticastGroupResponse {
    multicastGroup: MulticastGroup;
    createdAt: string;
    updatedAt: string;
}

export interface MulticastGroupQueueItem {
    multicastGroupId?: string;
    fCnt?: Int64;
    fPort: number;
    data: string;
    expiresAt?: string | null;
}

// ------------------------------------------------------------------ resumo (backend)

export interface Resumo {
    gateways: { total: number; online: number; offline: number; nuncaVisto: number };
    aplicacoes: number;
    perfis: number;
    dispositivos: { total: number; ativos24h: number; nuncaVistos: number };
    dispositivosPorAplicacao: { id: string; name: string; total: number; ativos24h: number }[];
}

// ------------------------------------------------------------------ painel (usuários e auditoria)

export type PerfilAcesso = 'ADMIN' | 'OPERADOR' | 'VISUALIZADOR';

export interface UsuarioSistema {
    id: number;
    nome: string;
    email: string;
    perfil: PerfilAcesso;
    ativo: boolean;
    bloqueado: boolean;
    bloqueadoAte?: string;
    motivoBloqueio?: string;
    ultimoLogin?: string;
    criadoEm: string;
    atualizadoEm: string;
}

export interface RegistroAuditoria {
    id: number;
    usuario?: string;
    acao: string;
    recurso: string;
    metodo?: string;
    statusHttp?: number;
    sucesso: boolean;
    detalhe?: string;
    ip?: string;
    criadoEm: string;
}

// ── Sessão e controle de logoff ─────────────────────────────────────────────

/** Sessão atual: o que o navegador precisa para controlar o logoff. */
export interface SessaoInfo {
    id: string;
    /** 0 = sem limite de inatividade. */
    inatividadeSegundos: number;
    avisoSegundos: number;
    expiraEm: string;
    ultimaAtividade: string;
    manterConectado: boolean;
    /** Relógio do servidor (compensa relógio errado no computador). */
    agora: string;
}

export interface PoliticaSessao {
    inatividadeMinutos: number;
    avisoSegundos: number;
    duracaoMaximaHoras: number;
    maxSessoesPorUsuario: number;
    manterConectado: boolean;
    atualizadoEm?: string;
    atualizadoPor?: string;
    /** Só no envio: encerra as sessões abertas (exceto a sua) para valer na hora. */
    encerrarSessoesAbertas?: boolean;
}

export type MotivoEncerramento =
    | 'LOGOUT'
    | 'INATIVIDADE'
    | 'EXPIRADA'
    | 'ENCERRADA_ADMIN'
    | 'LIMITE_SESSOES'
    | 'SENHA_ALTERADA'
    | 'USUARIO_DESATIVADO'
    | 'USUARIO_BLOQUEADO'
    | 'USUARIO_EXCLUIDO'
    | 'REUSO_TOKEN'
    | 'RESTAURACAO_BACKUP'
    | 'INVALIDA';

// ── Visitantes ───────────────────────────────────────────────────────────────

export interface SessaoVisitante {
    id: string;
    usuarioId?: number;
    usuarioNome: string;
    usuarioEmail: string;
    ip?: string;
    dispositivo?: string;
    userAgent?: string;
    iniciadaEm: string;
    ultimaAtividade: string;
    ultimoSinal: string;
    expiraEm: string;
    encerradaEm?: string;
    motivoEncerramento?: MotivoEncerramento;
    motivoDescricao?: string;
    encerradaPor?: string;
    aberta: boolean;
    online: boolean;
    atual: boolean;
    duracaoSegundos: number;
    ociosoSegundos: number;
}

export interface VisitanteUsuario {
    usuarioId: number;
    nome: string;
    email: string;
    perfil: PerfilAcesso;
    ativo: boolean;
    bloqueado: boolean;
    bloqueadoAte?: string;
    motivoBloqueio?: string;
    online: boolean;
    sessoesAbertas: number;
    totalAcessos: number;
    acessosHoje: number;
    acessos7Dias: number;
    ultimoAcesso?: string;
    ultimoIp?: string;
    ultimoDispositivo?: string;
}

export interface ResumoVisitantes {
    dias: number;
    onlineAgora: number;
    usuariosOnline: number;
    sessoesAbertas: number;
    acessosHoje: number;
    visitantesHoje: number;
    visitantes7Dias: number;
    acessosPeriodo: number;
    visitantesPeriodo: number;
    falhasLoginHoje: number;
    usuariosBloqueados: number;
    duracaoMediaMinutos: number;
    serie: { dia: string; acessos: number; visitantes: number }[];
    dispositivos: { nome: string; total: number }[];
    encerramentos: { nome: string; total: number }[];
    porHora: number[];
}

export interface FalhaLogin {
    id: number;
    email?: string;
    acao: string;
    statusHttp?: number;
    detalhe?: string;
    ip?: string;
    criadoEm: string;
}

// ── Backup ───────────────────────────────────────────────────────────────────

export interface VerificacaoBackup {
    item: string;
    ok: boolean;
    detalhe: string;
}

export interface BackupVisaoGeral {
    motor: string;
    formatos: string[];
    verificacoes: VerificacaoBackup[];
    emAndamento: boolean;
    diretorio: string;
}

export interface ArquivoBackup {
    pasta: 'manuais' | 'agendados' | 'seguranca';
    nome: string;
    formato: string;
    tamanho: number;
    modificadoEm: string;
}

export type StatusJob = 'PENDENTE' | 'EXECUTANDO' | 'SUCESSO' | 'PARCIAL' | 'ERRO' | 'IGNORADO';

export interface BackupJob {
    id: string;
    tipo: 'BACKUP' | 'RESTORE';
    origem: 'MANUAL' | 'AGENDADO' | 'EXECUTAR_AGORA';
    status: StatusJob;
    progresso: number;
    mensagem?: string;
    erro?: string;
    formatos: string[];
    arquivos: string[];
    tamanhoBytes?: number;
    enviarDrive: boolean;
    driveStatus?: string;
    driveMensagem?: string;
    removidos: number;
    solicitadoPor?: string;
    instancia?: string;
    agendadoPara?: string;
    criadoEm: string;
    iniciadoEm?: string;
    finalizadoEm?: string;
    emAndamento: boolean;
}

export interface HorarioBackup {
    /** 1 = segunda ... 7 = domingo */
    dia: number;
    /** HH:mm */
    hora: string;
}

export interface AgendamentoBackup {
    ativo: boolean;
    formatos: string[];
    destinoServidor: boolean;
    destinoDrive: boolean;
    retencaoDias: number;
    manterMinimo: number;
    horarios: HorarioBackup[];
    proximaExecucao?: string;
    fusoHorario?: string;
    atualizadoEm?: string;
    atualizadoPor?: string;
    driveConectado?: boolean;
    formatosDisponiveis?: string[];
}

export interface GoogleDriveConfig {
    credenciaisDefinidas: boolean;
    origemCredenciais?: 'TELA' | 'AMBIENTE';
    clientId?: string;
    clientSecretDefinido: boolean;
    conectado: boolean;
    contaEmail?: string;
    contaNome?: string;
    conectadoEm?: string;
    conectadoPor?: string;
    erroConexao?: string;
    pastaNome: string;
    pastaLink?: string;
    enviarManuais: boolean;
    retencaoDias: number;
    manterMinimo: number;
    redirectUri: string;
    chaveCifragemDedicada: boolean;
    ultimoEnvioEm?: string;
    ultimoEnvioStatus?: string;
    ultimoEnvioMensagem?: string;
}

export interface ResultadoEnvioDrive {
    sucesso: boolean;
    mensagem: string;
    enviados: number;
    removidos: number;
}
