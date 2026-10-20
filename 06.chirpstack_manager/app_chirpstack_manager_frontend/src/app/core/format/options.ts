/**
 * Opções (rótulos em português) para os enums do ChirpStack.
 */
export interface Opcao<T = string> {
    label: string;
    value: T;
}

export const REGIOES: Opcao[] = [
    { label: 'AU915 (Brasil / Austrália)', value: 'AU915' },
    { label: 'US915', value: 'US915' },
    { label: 'EU868', value: 'EU868' },
    { label: 'EU433', value: 'EU433' },
    { label: 'AS923', value: 'AS923' },
    { label: 'AS923-2', value: 'AS923_2' },
    { label: 'AS923-3', value: 'AS923_3' },
    { label: 'AS923-4', value: 'AS923_4' },
    { label: 'CN470', value: 'CN470' },
    { label: 'CN779', value: 'CN779' },
    { label: 'IN865', value: 'IN865' },
    { label: 'KR920', value: 'KR920' },
    { label: 'RU864', value: 'RU864' },
    { label: 'ISM2400', value: 'ISM2400' }
];

export const VERSOES_MAC: Opcao[] = [
    { label: 'LoRaWAN 1.0.0', value: 'LORAWAN_1_0_0' },
    { label: 'LoRaWAN 1.0.1', value: 'LORAWAN_1_0_1' },
    { label: 'LoRaWAN 1.0.2', value: 'LORAWAN_1_0_2' },
    { label: 'LoRaWAN 1.0.3', value: 'LORAWAN_1_0_3' },
    { label: 'LoRaWAN 1.0.4', value: 'LORAWAN_1_0_4' },
    { label: 'LoRaWAN 1.1.0', value: 'LORAWAN_1_1_0' }
];

export const REVISOES_PARAMETROS: Opcao[] = [
    { label: 'A', value: 'A' },
    { label: 'B', value: 'B' },
    { label: 'RP002-1.0.0', value: 'RP002_1_0_0' },
    { label: 'RP002-1.0.1', value: 'RP002_1_0_1' },
    { label: 'RP002-1.0.2', value: 'RP002_1_0_2' },
    { label: 'RP002-1.0.3', value: 'RP002_1_0_3' },
    { label: 'RP002-1.0.4', value: 'RP002_1_0_4' }
];

export const CODECS: Opcao[] = [
    { label: 'Nenhum', value: 'NONE' },
    { label: 'Cayenne LPP', value: 'CAYENNE_LPP' },
    { label: 'Funções JavaScript', value: 'JS' }
];

export const TIPOS_MEDICAO: Opcao[] = [
    { label: 'Desconhecido (ignorar)', value: 'UNKNOWN' },
    { label: 'Contador', value: 'COUNTER' },
    { label: 'Absoluto', value: 'ABSOLUTE' },
    { label: 'Medidor (gauge)', value: 'GAUGE' },
    { label: 'Texto', value: 'STRING' }
];

export const TIPOS_MULTICAST: Opcao[] = [
    { label: 'Classe C', value: 'CLASS_C' },
    { label: 'Classe B', value: 'CLASS_B' }
];

export const AGENDAMENTO_CLASSE_C: Opcao[] = [
    { label: 'Atraso entre gateways (DELAY)', value: 'DELAY' },
    { label: 'Horário GPS (GPS_TIME)', value: 'GPS_TIME' }
];

export const PERIODICIDADE_PING_SLOT: Opcao<number>[] = [0, 1, 2, 3, 4, 5, 6, 7].map((v) => ({
    label: `A cada ${2 ** v} s (${v})`,
    value: v
}));

export const AGREGACOES: Opcao[] = [
    { label: 'Por minuto', value: 'MINUTE' },
    { label: 'Por hora', value: 'HOUR' },
    { label: 'Por dia', value: 'DAY' },
    { label: 'Por mês', value: 'MONTH' }
];

export const CODIFICACOES: Opcao[] = [
    { label: 'JSON', value: 'JSON' },
    { label: 'Protobuf', value: 'PROTOBUF' }
];

export const PERFIS_ACESSO: Opcao[] = [
    { label: 'Administrador', value: 'ADMIN' },
    { label: 'Operador', value: 'OPERADOR' },
    { label: 'Visualizador', value: 'VISUALIZADOR' }
];

export const TS003: Opcao[] = [
    { label: 'Não implementado', value: 'TS003_NOT_IMPLEMENTED' },
    { label: 'v1.0.0', value: 'TS003_V100' },
    { label: 'v2.0.0', value: 'TS003_v200' }
];
export const TS004: Opcao[] = [
    { label: 'Não implementado', value: 'TS004_NOT_IMPLEMENTED' },
    { label: 'v1.0.0', value: 'TS004_V100' },
    { label: 'v2.0.0', value: 'TS004_V200' }
];
export const TS005: Opcao[] = [
    { label: 'Não implementado', value: 'TS005_NOT_IMPLEMENTED' },
    { label: 'v1.0.0', value: 'TS005_V100' },
    { label: 'v2.0.0', value: 'TS005_V200' }
];

export const RELAY_CAD: Opcao[] = [
    { label: '1 s', value: 'SEC_1' },
    { label: '500 ms', value: 'MS_500' },
    { label: '250 ms', value: 'MS_250' },
    { label: '100 ms', value: 'MS_100' },
    { label: '50 ms', value: 'MS_50' },
    { label: '20 ms', value: 'MS_20' }
];
export const RELAY_ACK_OFFSET: Opcao[] = [
    { label: '0 kHz', value: 'KHZ_0' },
    { label: '200 kHz', value: 'KHZ_200' },
    { label: '400 kHz', value: 'KHZ_400' },
    { label: '800 kHz', value: 'KHZ_800' },
    { label: '1600 kHz', value: 'KHZ_1600' },
    { label: '3200 kHz', value: 'KHZ_3200' }
];
export const RELAY_ATIVACAO: Opcao[] = [
    { label: 'Desativar modo relay', value: 'DISABLE_RELAY_MODE' },
    { label: 'Ativar modo relay', value: 'ENABLE_RELAY_MODE' },
    { label: 'Dinâmico', value: 'DYNAMIC' },
    { label: 'Controlado pelo dispositivo', value: 'END_DEVICE_CONTROLLED' }
];

export const NOMES_INTEGRACAO: Record<string, string> = {
    HTTP: 'HTTP',
    INFLUX_DB: 'InfluxDB',
    THINGS_BOARD: 'ThingsBoard',
    MY_DEVICES: 'myDevices',
    GCP_PUB_SUB: 'GCP Pub/Sub',
    AWS_SNS: 'AWS SNS',
    AZURE_SERVICE_BUS: 'Azure Service Bus',
    PILOT_THINGS: 'Pilot Things',
    MQTT_GLOBAL: 'MQTT (global)',
    IFTTT: 'IFTTT',
    BLYNK: 'Blynk'
};

export function rotulo(opcoes: Opcao<unknown>[], valor: unknown): string {
    return opcoes.find((o) => o.value === valor)?.label ?? String(valor ?? '—');
}
