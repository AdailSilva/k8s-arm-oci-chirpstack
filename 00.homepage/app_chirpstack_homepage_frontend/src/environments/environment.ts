// This file can be replaced during build by using the `fileReplacements` array.
// `ng build --configuration production` replaces `environment.ts` with `environment.production.ts`.
// The list of file replacements can be found in `angular.json`.

export const environment = {
    production: false,
    staging: false,
    /** Endereço público do site neste perfil (links absolutos). */
    siteUrl: 'http://localhost:4401',
    /** false = a página pede aos buscadores para não indexar (robots noindex). */
    indexar: false,
    appName: 'ChirpStack v3 e v4 na OCI Always Free',
    version: '0.0.1'
};
