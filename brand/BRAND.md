# ChirpStack na OCI · Guia de identidade visual

> Rede LoRaWAN própria (ChirpStack v3/v4) no Kubernetes ARM da OCI Always Free.
> Vale para o site chirpstack.adailsilva.com.br (`00.homepage/app_chirpstack_site_frontend`), o **ChirpStack Consumer** (`05.chirpstack_consumer/`), o **ChirpStack Manager** (`06.chirpstack_manager/`) e qualquer material novo da rede.

## 1. Identificadores

antena LoRa (mastro com ponto) entre duas ondas de rádio de cada lado (85% e 50% de opacidade) sobre bloco arredondado em degradê teal.

## 2. Logotipo

Todos os arquivos saem do mesmo símbolo 40×40 usado no site (`00.homepage/app_chirpstack_site_frontend/src/app/shared/logo.ts`
e `public/favicon.svg`). Os textos dos logotipos usam a fonte **Archivo** (a mesma do site), com
`Inter`/`Arial` como reserva — **não estão convertidos em curvas**: para material impresso, abra o
SVG num editor vetorial com a fonte instalada e converta o texto antes de enviar.

| Arquivo | Uso |
|---|---|
| `chirpstack-logo-horizontal.svg` / `-1200.png` | Marca principal: símbolo à esquerda do nome, fundos claros. |
| `chirpstack-logo-horizontal-negativo.svg` / `-1200.png` | Horizontal para fundos escuros. |
| `chirpstack-logo.svg` / `-1200.png` | Marca vertical (símbolo sobre o nome), fundos claros. |
| `chirpstack-logo-negativo.svg` / `-1200.png` | Vertical para fundos escuros. |
| `chirpstack-simbolo.svg` / `-256.png` | Só o símbolo — favicon, topo do menu, marca d'água. |
| `chirpstack-simbolo-negativo.svg` / `-256.png` | Símbolo para fundos escuros (bloco branco, traço na cor escura). |
| `chirpstack-icone.svg` / `-512.png` / `-1024.png` | Ícone em fundo escuro — avatar, redes sociais. |
| `chirpstack-icone-claro.svg` / `-512.png` / `-1024.png` | Ícone em fundo branco. |

- **Símbolo**: _
- Área de proteção: ao redor do símbolo, no mínimo 1/4 da altura dele. Tamanho mínimo: 16 px (favicon).

## 3. Cores

| Papel | Cor | Uso |
|---|---|---|
| Primária clara | `#2dd4bf` | Início do degradê do símbolo, destaques no tema escuro. |
| Primária escura | `#0f766e` | Fim do degradê, botões e links no tema claro. |
| Fundo escuro | `#042f2e` | Fundo do ícone e das áreas escuras. |
| Texto | `#0b1220` / `#64748b` | Título e subtítulo nos fundos claros. |

No site, a cor primária vem do preset do PrimeNG (`src/app.config.ts`), então as telas seguem a
mesma paleta sem cor fixa no código.

## 4. Padrão entre repositórios

Mesmo conjunto de arquivos e mesma nomenclatura (`<projeto>-<peça>[-variação][-tamanho].ext`) das
pastas `brand/` do CSLab, da 3T Sensors e da ASE Soluções. Ao criar um sistema novo neste
repositório, acrescente `chirpstack-<sistema>-icone*.svg/png` e `chirpstack-<sistema>-logo-horizontal*.svg/png`,
como em `cslab-<sistema>-*`.
