/**
 * ============================================================================
 *  CONFIGURAÇÃO CENTRAL DO SITE — ChirpStack v3 e v4 na OCI Always Free
 *  Todos os dados vêm do README.md da raiz do repositório
 *  (AdailSilva/k8s-arm-oci-chirpstack). Ao mudar versões, portas, hosts ou
 *  recursos lá, atualize aqui — os componentes só leem estes dados.
 * ============================================================================
 */

export interface Contatos {
    /** Somente dígitos com DDI + DDD. Ex.: '5588999999999'. Vazio = oculta o canal. */
    whatsapp: string;
    /** Ex.: 'contato@adailsilva.com.br'. Vazio = oculta o canal. */
    email: string;
    linkedin: string;
    github: string;
    instagram: string;
}

export const CONTATOS: Contatos = {
    whatsapp: '5589994129256',
    email: '',
    linkedin: 'https://www.linkedin.com/in/adailsilva/',
    github: 'https://github.com/AdailSilva',
    instagram: 'https://www.instagram.com/adailsilva_101/'
};

export const PERFIL = {
    nome: 'Adail Silva',
    nomeCompleto: 'Adail dos Santos Silva',
    cargo: 'Desenvolvedor Full-Stack, DevOps & IoT',
    cidade: 'Tianguá · Ceará · Brasil'
};

/** Repositório documentado por este site. */
export const REPOSITORIO = {
    nome: 'k8s-arm-oci-chirpstack',
    url: 'https://github.com/AdailSilva/k8s-arm-oci-chirpstack',
    readme: 'https://github.com/AdailSilva/k8s-arm-oci-chirpstack#readme',
    licenca: 'MIT'
};

/** Domínio base dos Ingress deste repositório. */
export const DOMINIO = 'adailsilva.com.br';

export interface Numero {
    valor: string;
    rotulo: string;
    detalhe: string;
}

export const NUMEROS: Numero[] = [
    { valor: 'R$ 0', rotulo: 'de custo mensal', detalhe: 'Somente recursos Always Free da Oracle Cloud' },
    { valor: '4 + 24', rotulo: 'OCPUs + GB de RAM', detalhe: 'Ampere A1 ARM64 — exatamente o limite gratuito' },
    { valor: '2', rotulo: 'versões lado a lado', detalhe: 'ChirpStack v3 e v4 em namespaces separados' },
    { valor: '1', rotulo: 'comando para a infra', detalhe: 'Terraform / OpenTofu provisiona rede, VMs e Kubernetes' }
];

export const FAIXA_TECNOLOGIAS: string[] = [
    'ChirpStack v3',
    'ChirpStack v4',
    'LoRaWAN',
    'AU915 · sub-banda 1',
    'Semtech UDP',
    'MQTT · Mosquitto',
    'MQTT TLS :8883',
    'PostgreSQL',
    'Redis',
    'Kubernetes v1.31',
    'kubeadm',
    'Flannel',
    'NGINX Ingress',
    "cert-manager + Let's Encrypt",
    'OCI Always Free',
    'Ampere A1 ARM64',
    'OCI File Storage',
    'Terraform / OpenTofu',
    'GitHub Actions'
];

/* ─── Fluxo de rede ponta a ponta ───────────────────────────────────────── */

export interface CamadaRede {
    id: string;
    titulo: string;
    subtitulo: string;
    descricao: string;
    icone: string;
    tags: string[];
    /** Rótulo do enlace até a próxima camada. */
    enlace: string;
}

export const CAMADAS_REDE: CamadaRede[] = [
    {
        id: 'device',
        titulo: 'End-devices',
        subtitulo: 'Sensores LoRaWAN',
        descricao: 'Ativação OTAA ou ABP, Classes A, B e C, plano AU915 na sub-banda 1 (canais 8–15 + 65).',
        icone: 'pi pi-wifi',
        tags: ['OTAA / ABP', 'Class A · B · C'],
        enlace: 'LoRa · AU915'
    },
    {
        id: 'gateway',
        titulo: 'Gateway',
        subtitulo: 'Semtech Packet Forwarder',
        descricao: 'Recebe o rádio e encaminha os pacotes em UDP ao IP público reservado do Network Load Balancer da OCI.',
        icone: 'pi pi-sitemap',
        tags: ['UDP :1700 (v3)', 'UDP :1710 (v4)'],
        enlace: 'UDP · NLB'
    },
    {
        id: 'chirpstack',
        titulo: 'ChirpStack',
        subtitulo: 'Kubernetes ARM64',
        descricao: 'Gateway Bridge → MQTT → Network/Application Server (v3) ou servidor unificado (v4), nos workers ARM64.',
        icone: 'pi pi-server',
        tags: ['chirpstack-v3', 'chirpstack-v4'],
        enlace: 'MQTT · REST'
    },
    {
        id: 'app',
        titulo: 'Aplicações',
        subtitulo: 'Integrações',
        descricao: 'Uplinks e downlinks via tópicos MQTT, API gRPC/REST, ChirpStack Manager e Consumer.',
        icone: 'pi pi-desktop',
        tags: ['MQTT', 'REST API'],
        enlace: ''
    }
];

/* ─── Versões ───────────────────────────────────────────────────────────── */

export interface Componente {
    nome: string;
    imagem: string;
    portas: string;
    papel: string;
    icone: string;
}

export interface Recurso {
    kind: string;
    nome: string;
    detalhe: string;
}

export interface Passo {
    titulo: string;
    arquivos: string;
}

export interface Versao {
    id: 'v3' | 'v4';
    nome: string;
    rota: string;
    namespace: string;
    resumo: string;
    descricao: string;
    arquitetura: string;
    destaques: { icone: string; texto: string }[];
    componentes: Componente[];
    acessos: { rotulo: string; endereco: string; observacao: string; link: boolean }[];
    passos: Passo[];
    armazenamento: string;
    pasta: string;
    scripts: string[];
    recursos: Recurso[];
}

export const VERSOES: Versao[] = [
    {
        id: 'v3',
        nome: 'ChirpStack v3',
        rota: '/v3',
        namespace: 'chirpstack-v3',
        resumo: 'Microsserviços: Network Server + Application Server',
        descricao:
            'A arquitetura clássica do ChirpStack: cinco serviços que conversam por MQTT e gRPC, dois bancos PostgreSQL (NS e AS) e um Redis de sessões. Broker MQTT sem TLS na porta 1888 e Gateway Bridge em UDP 1700.',
        arquitetura: 'Gateway Bridge → Mosquitto → Network Server ⇄ (gRPC) ⇄ Application Server',
        destaques: [
            { icone: 'pi pi-th-large', texto: 'Network Server 3.16.8 e Application Server 3.17.9 separados' },
            { icone: 'pi pi-database', texto: '2 PostgreSQL 14-alpine (chirpstack_ns e chirpstack_as com pg_trgm + hstore)' },
            { icone: 'pi pi-megaphone', texto: 'Mosquitto 2.0.22 anônimo — TCP 1888 → 1883' },
            { icone: 'pi pi-globe', texto: 'Banda AU915 (sub-banda 1) · NetID FFFFFF' },
            { icone: 'pi pi-lock', texto: "UI e API Swagger em HTTPS via Ingress + Let's Encrypt" }
        ],
        componentes: [
            { nome: 'Gateway Bridge', imagem: 'chirpstack/chirpstack-gateway-bridge:3.14.8', portas: 'UDP 1700', papel: 'Converte o Semtech UDP em eventos MQTT', icone: 'pi pi-arrow-right-arrow-left' },
            { nome: 'Mosquitto', imagem: 'eclipse-mosquitto:2.0.22', portas: 'TCP 1888 → 1883', papel: 'Broker MQTT anônimo, sem TLS', icone: 'pi pi-megaphone' },
            { nome: 'Network Server', imagem: 'chirpstack/chirpstack-network-server:3.16.8', portas: 'TCP 8000', papel: 'MAC LoRaWAN, ADR, deduplicação, AU915', icone: 'pi pi-sitemap' },
            { nome: 'Application Server', imagem: 'chirpstack/chirpstack-application-server:3.17.9', portas: '8001 · 8003 · 8080→443 · 8101', papel: 'UI web, API REST/gRPC e join server', icone: 'pi pi-desktop' },
            { nome: 'PostgreSQL NS', imagem: 'postgres:14-alpine', portas: 'TCP 5437', papel: 'Banco chirpstack_ns · PV 10Gi', icone: 'pi pi-database' },
            { nome: 'PostgreSQL AS', imagem: 'postgres:14-alpine', portas: 'TCP 5438', papel: 'Banco chirpstack_as · PV 10Gi', icone: 'pi pi-database' },
            { nome: 'Redis', imagem: 'redis:7.2', portas: 'TCP 6384 → 6379', papel: 'Sessões dos dispositivos · PV 1Gi', icone: 'pi pi-bolt' },
            { nome: 'Toolbox', imagem: 'nicolaka/netshoot', portas: '—', papel: 'Pod de diagnóstico de rede', icone: 'pi pi-wrench' }
        ],
        acessos: [
            { rotulo: 'Interface web', endereco: 'chirpstack-v3.adailsilva.com.br', observacao: 'admin / admin — troque no primeiro acesso', link: true },
            { rotulo: 'API (Swagger)', endereco: 'chirpstack-v3.adailsilva.com.br/api', observacao: 'JWT via UI → Profile → API Keys', link: true },
            { rotulo: 'Gateway Bridge', endereco: '<IP_NLB>:1700/udp', observacao: 'Packet Forwarder dos gateways', link: false },
            { rotulo: 'Broker MQTT', endereco: '<IP_NLB>:1888', observacao: 'Sem TLS · allow_anonymous true', link: false }
        ],
        passos: [
            { titulo: 'Namespace', arquivos: '01' },
            { titulo: 'Mosquitto', arquivos: '02 · 03 · 04' },
            { titulo: 'PV/PVC + PostgreSQL NS e AS', arquivos: '08 → 14' },
            { titulo: 'Redis', arquivos: '15 · 16 · 17' },
            { titulo: 'Gateway Bridge', arquivos: '18 · 19 · 20' },
            { titulo: 'kubectl wait nas dependências', arquivos: 'Mosquitto · PostgreSQL · Redis' },
            { titulo: 'Network Server', arquivos: '21 · 22 · 23' },
            { titulo: 'Application Server + Secret', arquivos: '25 → 28' },
            { titulo: 'Ingress TLS', arquivos: '31' },
            { titulo: 'Toolbox', arquivos: '32' }
        ],
        armazenamento: '~21,1 Gi no OCI File Storage',
        pasta: '03.chirpstack_v3',
        scripts: ['01.deploy_chirpstack-v3_script.sh', '02.destroy_chirpstack-v3_script.sh', '03.back-up_chirpstack-v3_script.sh', '04.restore_chirpstack-v3_script.sh'],
        recursos: [
            { kind: 'Deployment', nome: 'chirpstack-v3-mosquitto-deployment', detalhe: 'eclipse-mosquitto:2.0.22' },
            { kind: 'Deployment', nome: 'chirpstack-v3-ns-postgresql-deployment', detalhe: 'postgres:14-alpine' },
            { kind: 'Deployment', nome: 'chirpstack-v3-as-postgresql-deployment', detalhe: 'postgres:14-alpine' },
            { kind: 'Deployment', nome: 'chirpstack-v3-redis-deployment', detalhe: 'redis:7.2' },
            { kind: 'Deployment', nome: 'chirpstack-v3-gateway-bridge-deployment', detalhe: 'gateway-bridge:3.14.8' },
            { kind: 'Deployment', nome: 'chirpstack-v3-network-server-deployment', detalhe: 'network-server:3.16.8' },
            { kind: 'Deployment', nome: 'chirpstack-v3-application-server-deployment', detalhe: 'application-server:3.17.9' },
            { kind: 'Secret', nome: 'chirpstack-v3-application-server-secrets', detalhe: 'JWT, DSNs e credenciais MQTT' },
            { kind: 'PV / PVC', nome: 'oci-fss-postgresql-data-chirpstack-v3-ns / -as', detalhe: '10Gi cada · OCI FSS' },
            { kind: 'PV / PVC', nome: 'oci-fss-redis-data-chirpstack-v3', detalhe: '1Gi · OCI FSS' },
            { kind: 'Ingress', nome: 'chirpstack-v3-application-server-ingress', detalhe: "HTTPS · Let's Encrypt" }
        ]
    },
    {
        id: 'v4',
        nome: 'ChirpStack v4',
        rota: '/v4',
        namespace: 'chirpstack-v4',
        resumo: 'Servidor unificado, multi-região e MQTT com TLS',
        descricao:
            'A refatoração completa do ChirpStack: Network Server e Application Server num único binário, várias regiões LoRaWAN na mesma instância, broker MQTT com TLS e autenticação na porta 8883 e uma REST API separada.',
        arquitetura: 'Gateway Bridge → Mosquitto (TLS) → ChirpStack (NS + AS) → REST API',
        destaques: [
            { icone: 'pi pi-box', texto: 'ChirpStack 4.15: Network + Application Server num binário só' },
            { icone: 'pi pi-globe', texto: 'Várias regiões ao mesmo tempo (AS923, AU915, EU868, US915…)' },
            { icone: 'pi pi-lock', texto: 'Mosquitto com TLS :8883, usuário/senha e CA própria' },
            { icone: 'pi pi-code', texto: 'REST API (chirpstack-rest-api 4.15) em domínio próprio' },
            { icone: 'pi pi-database', texto: '1 PostgreSQL 17.5 (banco chirpstack) + Redis 7.2' }
        ],
        componentes: [
            { nome: 'Gateway Bridge', imagem: 'chirpstack/chirpstack-gateway-bridge:4.1', portas: 'UDP 1710 → 1700', papel: 'Publica em au915_1/gateway/{id}/event/…', icone: 'pi pi-arrow-right-arrow-left' },
            { nome: 'Mosquitto TLS', imagem: 'eclipse-mosquitto:2.0.22', portas: 'TCP 8883 (MQTTS)', papel: 'CA + server.crt · passwd · sem anônimo', icone: 'pi pi-lock' },
            { nome: 'ChirpStack', imagem: 'chirpstack/chirpstack:4.15', portas: 'TCP 8080 → 443', papel: 'NS + AS unificados · UI + API gRPC', icone: 'pi pi-server' },
            { nome: 'REST API', imagem: 'chirpstack/chirpstack-rest-api:4.15', portas: 'TCP 8090 → 443', papel: 'Proxy gRPC → REST HTTP', icone: 'pi pi-code' },
            { nome: 'PostgreSQL', imagem: 'postgres:17.5', portas: 'TCP 5442 → 5432', papel: 'Banco único chirpstack · PV 10Gi', icone: 'pi pi-database' },
            { nome: 'Redis', imagem: 'redis:7.2', portas: 'TCP 6389 → 6379', papel: 'Cache e filas · PV 1Gi', icone: 'pi pi-bolt' },
            { nome: 'Dispositivos', imagem: 'PV oci-fss-chirpstack-devices', portas: '—', papel: 'Dados de dispositivos · 500Mi', icone: 'pi pi-folder' },
            { nome: 'Toolbox', imagem: 'nicolaka/netshoot', portas: '—', papel: 'Pod de diagnóstico de rede', icone: 'pi pi-wrench' }
        ],
        acessos: [
            { rotulo: 'Interface web + gRPC', endereco: 'chirpstack-v4.adailsilva.com.br', observacao: 'admin / admin — troque no primeiro acesso', link: true },
            { rotulo: 'REST API', endereco: 'chirpstack-v4-rest-api.adailsilva.com.br', observacao: 'Bearer token gerado na UI', link: true },
            { rotulo: 'Gateway Bridge', endereco: '<IP_NLB>:1710/udp', observacao: 'Packet Forwarder dos gateways', link: false },
            { rotulo: 'Broker MQTT TLS', endereco: '<IP_NLB>:8883', observacao: 'Certificado da CA própria + usuário/senha', link: false }
        ],
        passos: [
            { titulo: 'Secrets TLS e passwd do Mosquitto', arquivos: 'pré-requisito' },
            { titulo: 'Namespace', arquivos: '01' },
            { titulo: 'Mosquitto com TLS', arquivos: '02 · 03 · 04' },
            { titulo: 'PV/PVC + PostgreSQL', arquivos: '05 → 08' },
            { titulo: 'Redis', arquivos: '09 · 10 · 11' },
            { titulo: 'Gateway Bridge v4', arquivos: '12 · 13 · 14' },
            { titulo: 'kubectl wait nas dependências', arquivos: 'Mosquitto · PostgreSQL · Redis' },
            { titulo: 'ChirpStack (NS + AS)', arquivos: '15 → 18' },
            { titulo: 'Ingress UI + gRPC', arquivos: '21' },
            { titulo: 'REST API + Ingress', arquivos: '22 · 23 · 26' },
            { titulo: 'Toolbox', arquivos: '27' }
        ],
        armazenamento: '~11,5 Gi no OCI File Storage',
        pasta: '04.chirpstack_v4',
        scripts: ['01.deploy_chirpstack-v4_script.sh', '02.destroy_chirpstack-v4_script.sh', '03.back-up_chirpstack-v4_script.sh', '04.restore_chirpstack-v4_script.sh'],
        recursos: [
            { kind: 'Deployment', nome: 'chirpstack-v4-mosquitto-deployment', detalhe: 'eclipse-mosquitto:2.0.22 · TLS' },
            { kind: 'Deployment', nome: 'chirpstack-v4-postgresql-deployment', detalhe: 'postgres:17.5' },
            { kind: 'Deployment', nome: 'chirpstack-v4-redis-deployment', detalhe: 'redis:7.2' },
            { kind: 'Deployment', nome: 'chirpstack-v4-gateway-bridge-deployment', detalhe: 'gateway-bridge:4.1' },
            { kind: 'Deployment', nome: 'chirpstack-v4-deployment', detalhe: 'chirpstack:4.15' },
            { kind: 'Deployment', nome: 'chirpstack-v4-rest-api-deployment', detalhe: 'chirpstack-rest-api:4.15' },
            { kind: 'ConfigMap', nome: 'chirpstack-v4-config-map', detalhe: 'chirpstack.toml + arquivos de região' },
            { kind: 'PV / PVC', nome: 'oci-fss-postgresql-data-chirpstack-v4-ns-as', detalhe: '10Gi · OCI FSS' },
            { kind: 'PV / PVC', nome: 'oci-fss-redis-data-chirpstack-v4', detalhe: '1Gi · OCI FSS' },
            { kind: 'PV / PVC', nome: 'oci-fss-chirpstack-devices-chirpstack-v4', detalhe: '500Mi · OCI FSS' },
            { kind: 'Ingress', nome: 'chirpstack-v4-ingress · chirpstack-v4-rest-api-ingress', detalhe: "HTTPS · Let's Encrypt" }
        ]
    }
];

/* ─── Comparativo v3 × v4 (README → "Comparativo v3 vs v4") ─────────────── */

export const COMPARATIVO: { aspecto: string; v3: string; v4: string }[] = [
    { aspecto: 'Arquitetura', v3: 'Microsserviços separados (NS + AS)', v4: 'Servidor unificado (NS + AS num binário)' },
    { aspecto: 'Banco de dados', v3: '2 instâncias PostgreSQL (NS e AS)', v4: '1 instância PostgreSQL (chirpstack)' },
    { aspecto: 'PostgreSQL', v3: '14-alpine', v4: '17.5' },
    { aspecto: 'Gateway Bridge', v3: '3.14.8', v4: '4.1' },
    { aspecto: 'MQTT', v3: 'Sem TLS — 1883, anônimo', v4: 'Com TLS — 8883, usuário/senha' },
    { aspecto: 'Regiões LoRaWAN', v3: '1 região por instância', v4: 'Várias regiões simultâneas' },
    { aspecto: 'REST API', v3: 'Integrada ao Application Server', v4: 'Serviço separado (chirpstack-rest-api)' },
    { aspecto: 'gRPC', v3: ':8000 (NS) e :8001 (AS)', v4: ':8080 (unificado)' },
    { aspecto: 'Porta UDP do gateway', v3: ':1700', v4: ':1710 → 1700' },
    { aspecto: 'Armazenamento total', v3: '~21,1 Gi', v4: '~11,5 Gi' },
    { aspecto: 'Namespace', v3: 'chirpstack-v3', v4: 'chirpstack-v4' }
];

/* ─── Mapa de serviços (README → "Mapa de Serviços e Links de Acesso") ──── */

export interface Servico {
    nome: string;
    endereco: string;
    protocolo: string;
    observacao: string;
    namespace: string;
    link: boolean;
}

export const SERVICOS_WEB: Servico[] = [
    { nome: 'ChirpStack v3 — UI', endereco: 'chirpstack-v3.adailsilva.com.br', protocolo: 'HTTPS', observacao: 'Application Server', namespace: 'chirpstack-v3', link: true },
    { nome: 'ChirpStack v4 — UI', endereco: 'chirpstack-v4.adailsilva.com.br', protocolo: 'HTTPS', observacao: 'UI + API gRPC', namespace: 'chirpstack-v4', link: true },
    { nome: 'ChirpStack v4 — REST API', endereco: 'chirpstack-v4-rest-api.adailsilva.com.br', protocolo: 'HTTPS', observacao: 'Bearer token', namespace: 'chirpstack-v4', link: true },
    { nome: 'ChirpStack Manager', endereco: 'chirpstack-manager.adailsilva.com.br', protocolo: 'HTTPS', observacao: 'Painel de administração do v4', namespace: 'chirpstack-manager', link: true },
    { nome: 'Kubernetes Dashboard', endereco: 'k8s.adailsilva.com.br/dashboard', protocolo: 'HTTPS', observacao: 'Token do admin-user', namespace: 'kubernetes-dashboard', link: true },
    { nome: 'Este site', endereco: 'chirpstack.adailsilva.com.br', protocolo: 'HTTPS', observacao: 'Homepage do repositório', namespace: 'chirpstack-site', link: true }
];

export const SERVICOS_REDE: Servico[] = [
    { nome: 'Gateway Bridge v3', endereco: '<IP_NLB>:1700', protocolo: 'UDP', observacao: 'Packet Forwarder', namespace: 'chirpstack-v3', link: false },
    { nome: 'Gateway Bridge v4', endereco: '<IP_NLB>:1710', protocolo: 'UDP', observacao: 'Packet Forwarder', namespace: 'chirpstack-v4', link: false },
    { nome: 'MQTT v3', endereco: '<IP_NLB>:1888', protocolo: 'TCP', observacao: 'Sem TLS · anônimo', namespace: 'chirpstack-v3', link: false },
    { nome: 'MQTT v4', endereco: '<IP_NLB>:8883', protocolo: 'TCP/TLS', observacao: 'CA própria + usuário/senha', namespace: 'chirpstack-v4', link: false },
    { nome: 'API Server', endereco: '<IP_NLB>:6443', protocolo: 'TCP', observacao: 'kubectl', namespace: '—', link: false },
    { nome: 'SSH (leader)', endereco: '<IP_NLB>:22', protocolo: 'TCP', observacao: 'Bastion para os workers', namespace: '—', link: false }
];

/* ─── LoRaWAN: AU915 e classes ──────────────────────────────────────────── */

export const SUB_BANDAS: { id: string; canais: string; bw500: string; faixa: string; usada: boolean }[] = [
    { id: 'au915_0', canais: '0 – 7', bw500: '64', faixa: '915.2 – 916.6', usada: false },
    { id: 'au915_1', canais: '8 – 15', bw500: '65', faixa: '916.8 – 918.2', usada: true },
    { id: 'au915_2', canais: '16 – 23', bw500: '66', faixa: '918.4 – 919.8', usada: false },
    { id: 'au915_3', canais: '24 – 31', bw500: '67', faixa: '920.0 – 921.4', usada: false },
    { id: 'au915_4', canais: '32 – 39', bw500: '68', faixa: '921.6 – 923.0', usada: false },
    { id: 'au915_5', canais: '40 – 47', bw500: '69', faixa: '923.2 – 924.6', usada: false },
    { id: 'au915_6', canais: '48 – 55', bw500: '70', faixa: '924.8 – 926.2', usada: false },
    { id: 'au915_7', canais: '56 – 63', bw500: '71', faixa: '926.4 – 927.8', usada: false }
];

export interface Classe {
    id: 'A' | 'B' | 'C';
    nome: string;
    recepcao: string;
    latencia: string;
    energia: number;
    alimentacao: string;
    icone: string;
}

export const CLASSES: Classe[] = [
    { id: 'A', nome: 'Aloha', recepcao: 'Só após o uplink (RX1 + RX2)', latencia: 'Alta — até o próximo uplink', energia: 1, alimentacao: 'Bateria', icone: 'pi pi-battery' },
    { id: 'B', nome: 'Beacon', recepcao: 'RX1 + RX2 + ping slots periódicos', latencia: 'Previsível (período do ping slot)', energia: 2, alimentacao: 'Bateria / solar', icone: 'pi pi-clock' },
    { id: 'C', nome: 'Continuous', recepcao: 'RX2 contínuo + RX1 após uplink', latencia: 'Mínima (< 1 s)', energia: 3, alimentacao: 'Contínua', icone: 'pi pi-bolt' }
];

/* ─── MQTT ──────────────────────────────────────────────────────────────── */

export const TOPICOS_MQTT: { topico: string; direcao: 'up' | 'down'; descricao: string }[] = [
    { topico: 'application/{id}/device/{eui}/event/up', direcao: 'up', descricao: 'Uplink recebido' },
    { topico: 'application/{id}/device/{eui}/event/join', direcao: 'up', descricao: 'JOIN OTAA aceito' },
    { topico: 'application/{id}/device/{eui}/event/ack', direcao: 'up', descricao: 'ACK de downlink confirmado' },
    { topico: 'application/{id}/device/{eui}/event/txack', direcao: 'up', descricao: 'Transmissão confirmada pelo gateway (v4)' },
    { topico: 'application/{id}/device/{eui}/command/down', direcao: 'down', descricao: 'Enfileirar downlink' }
];

export const EXEMPLO_DOWNLINK_V3 = `mosquitto_pub -h <IP_NLB> -p 1888 \\
  -t "application/1/device/<DEV_EUI>/command/down" \\
  -m '{
        "devEui": "<DEV_EUI>",
        "confirmed": false,
        "fPort": 1,
        "data": "AQ=="
      }'

# acompanhar os eventos do dispositivo
mosquitto_sub -h <IP_NLB> -p 1888 -v \
  -t "application/1/device/<DEV_EUI>/event/#"`;

export const EXEMPLO_DOWNLINK_V4 = `mosquitto_pub -h <IP_NLB> -p 8883 \\
  --cafile ca.crt -u <usuario> -P <senha> \\
  -t "application/<APP_UUID>/device/<DEV_EUI>/command/down" \\
  -m '{
        "devEui": "<DEV_EUI>",
        "confirmed": false,
        "fPort": 1,
        "data": "AQ=="
      }'

# acompanhar os eventos do dispositivo
mosquitto_sub -h <IP_NLB> -p 8883 -v \
  --cafile ca.crt -u <usuario> -P <senha> \
  -t "application/<APP_UUID>/device/<DEV_EUI>/event/#"`;

/* ─── Aplicações do ecossistema neste repositório ───────────────────────── */

export const APLICACOES = [
    {
        nome: 'ChirpStack Manager',
        pasta: '06.chirpstack_manager',
        descricao: 'Painel web para administrar o ChirpStack v4 pela REST API: login próprio, perfis de acesso, auditoria, controle de visitantes e de logoff, backup e restauração agendados com envio ao Google Drive.',
        stack: ['Spring Boot 4.1', 'Java 21', 'Angular 21', 'PrimeNG · Avalon', 'PostgreSQL'],
        icone: 'pi pi-sliders-h',
        url: 'https://chirpstack-manager.adailsilva.com.br'
    },
    {
        nome: 'ChirpStack Consumer',
        pasta: '05.chirpstack_consumer',
        descricao: 'Backend Spring Boot e frontend Angular que consomem os eventos do ChirpStack para exibir e processar os dados dos dispositivos, com pipeline próprio no GitHub Actions.',
        stack: ['Spring Boot', 'Angular 21', 'Kubernetes', 'GitHub Actions'],
        icone: 'pi pi-inbox',
        url: 'https://app-chirpstack-consumer.adailsilva.com.br'
    }
];

/* ─── Perguntas frequentes ──────────────────────────────────────────────── */

export interface Pergunta {
    pergunta: string;
    resposta: string;
}

export const PERGUNTAS: Pergunta[] = [
    {
        pergunta: 'Isso realmente não tem custo?',
        resposta:
            'Sim. O cluster usa só recursos Always Free da OCI: 4 instâncias Ampere A1 (1 OCPU/3 GB no leader e 1 OCPU/7 GB em cada worker), Network Load Balancer, IP público reservado, VCN e Container Registry. O IP reservado e as instâncias têm prevent_destroy no Terraform para evitar remoção acidental.'
    },
    {
        pergunta: 'Posso rodar o ChirpStack v3 e o v4 ao mesmo tempo?',
        resposta:
            'Pode. Cada versão fica no seu namespace (chirpstack-v3 e chirpstack-v4), com portas distintas: o Gateway Bridge da v3 escuta em UDP 1700 e o da v4 em UDP 1710; o MQTT da v3 fica na 1888 e o da v4 na 8883 com TLS.'
    },
    {
        pergunta: 'Qual versão devo usar num projeto novo?',
        resposta:
            'A v4: servidor unificado, menos componentes para operar, várias regiões na mesma instância, MQTT com TLS e REST API separada. A v3 continua documentada para quem tem dispositivos e integrações legadas.'
    },
    {
        pergunta: 'Por que os gateways usam a sub-banda 1 do AU915?',
        resposta:
            'É o padrão de fato adotado no Brasil (canais 8–15 + 65, de 916.8 a 918.2 MHz). Isso aparece em três lugares: enabled_uplink_channels no Network Server da v3, o arquivo region_au915_1.toml da v4 e a configuração dos gateways e dispositivos.'
    },
    {
        pergunta: 'Onde ficam os dados do PostgreSQL e do Redis?',
        resposta:
            'No OCI File Storage Service (NFS), montado em todos os nós. Assim um pod pode ser reagendado em qualquer worker sem perder dados. Cada versão tem scripts de backup e restore em 00.UsefulScripts.'
    },
    {
        pergunta: 'Preciso cadastrar DNS antes do deploy?',
        resposta:
            "Sim, para os serviços HTTPS. O cert-manager usa o desafio HTTP-01 do Let's Encrypt, então cada subdomínio precisa apontar para o IP do NLB antes. O ideal é cadastrar durante o terraform/tofu apply, logo que o IP reservado é criado. O MQTT TLS usa CA própria e não depende de DNS."
    }
];

/* ─── Infraestrutura (README → Arquitetura, Recursos Always Free, Tecnologias) */

export const CLUSTER = {
    dominio: 'k8s.adailsilva.com.br',
    provedor: 'Oracle Cloud Infrastructure',
    regiao: 'sa-saopaulo-1 (São Paulo)',
    kubernetes: 'v1.31',
    nos: 4,
    arquitetura: 'ARM64 (Ampere A1)',
    vcpus: 4,
    memoriaGb: 24,
    componentes: [
        { nome: 'Provisionamento', valor: 'kubeadm · v1.31', icone: 'pi pi-cog' },
        { nome: 'Sistema operacional', valor: 'Ubuntu 24.04 LTS · AArch64', icone: 'pi pi-desktop' },
        { nome: 'Container runtime', valor: 'containerd', icone: 'pi pi-box' },
        { nome: 'Rede (CNI)', valor: 'Flannel · 10.244.0.0/16', icone: 'pi pi-share-alt' },
        { nome: 'Ingress', valor: 'NGINX · NodePort 30080/30443', icone: 'pi pi-sign-in' },
        { nome: 'Certificados', valor: "cert-manager + Let's Encrypt", icone: 'pi pi-lock' },
        { nome: 'Armazenamento', valor: 'OCI File Storage (NFS)', icone: 'pi pi-database' },
        { nome: 'Registry', valor: 'OCI Container Registry', icone: 'pi pi-images' },
        { nome: 'Infra como código', valor: 'Terraform / OpenTofu', icone: 'pi pi-code' },
        { nome: 'CI/CD', valor: 'GitHub Actions · runner ARM64', icone: 'pi pi-sync' }
    ],
    nosDetalhe: [
        { nome: 'leader', papel: 'Control plane · 1 OCPU · 3 GB' },
        { nome: 'worker-0', papel: 'Worker · runner CI · 1 OCPU · 7 GB' },
        { nome: 'worker-1', papel: 'Worker · 1 OCPU · 7 GB' },
        { nome: 'worker-2', papel: 'Worker · 1 OCPU · 7 GB' }
    ],
    portasNlb: [
        { porta: 'TCP 22', destino: 'leader', uso: 'SSH' },
        { porta: 'TCP 6443', destino: 'leader', uso: 'API Server / kubectl' },
        { porta: 'TCP 80', destino: 'workers · 30080', uso: 'HTTP (ACME)' },
        { porta: 'TCP 443', destino: 'workers · 30443', uso: 'HTTPS' },
        { porta: 'UDP 1700', destino: 'workers', uso: 'Gateway Bridge v3' },
        { porta: 'UDP 1710', destino: 'workers', uso: 'Gateway Bridge v4' }
    ],
    modulos: [
        { nome: 'compartment', papel: 'Compartimento k8s-on-arm-oci-always-free' },
        { nome: 'network', papel: 'VCN, subnet, Security Lists, NLB e IP reservado' },
        { nome: 'compute', papel: '1 leader + 3 workers Ubuntu 24.04 AArch64' },
        { nome: 'k8s', papel: 'kubeadm, join dos workers, Flannel, kubeconfig' },
        { nome: 'k8s_scaffold', papel: 'Ingress NGINX, cert-manager, Dashboard' },
        { nome: 'oci-infra_ci_cd', papel: 'Repositórios ARM64 no OCIR' }
    ],
    pipeline: [
        { titulo: 'Push na master', descricao: 'paths-filter detecta a pasta alterada', icone: 'pi pi-filter' },
        { titulo: 'Versão + tag Git', descricao: 'prefixo por projeto (ex.: app-…-1.4)', icone: 'pi pi-tag' },
        { titulo: 'Build ARM64', descricao: 'Docker Buildx no runner self-hosted', icone: 'pi pi-box' },
        { titulo: 'Push no OCIR', descricao: 'tag da versão + latest', icone: 'pi pi-cloud-upload' },
        { titulo: 'kubectl apply', descricao: 'rollout no cluster da OCI', icone: 'pi pi-check-circle' }
    ]
};
