# ChirpStack Manager · Web

Frontend Angular 21 com o tema **Avalon** (PrimeNG 21). Veja o README da raiz do projeto.

| Perfil | Rodar | Porta | Proxy de `/api` | Build |
|---|---|---|---|---|
| development | `npm start` ou `npm run start:development` | 4201 | `http://localhost:8081` | `npm run build:development` |
| staging | `npm run start:staging` | 4202 | `http://localhost:8082` | `npm run build:staging` |
| production | `npm run start:production` | 4203 | `http://localhost:8083` | `npm run build:production` |

Cada perfil troca `src/environments/environment.ts` pelo `environment.<perfil>.ts` e usa o proxy
`src/proxy-config.<perfil>.json`. Em desenvolvimento e homologação um selo no topo indica o perfil.
O build vai para `dist/chirpstack-manager/browser`.

Organização (mesmo padrão do CSLab BackOffice): `src/app/core` (auth, http, sessao, format, i18n,
notificacao, tenant), `src/app/pages/<tela>`, `src/app/shared/<grupo>` e `src/app/layout`.
A imagem usa `nginx.conf` e `mime.types` desta pasta; os manifests ficam em `kubernetes/`.

O tema Avalon é licenciado pela PrimeTek (veja `LICENSE.md`).
