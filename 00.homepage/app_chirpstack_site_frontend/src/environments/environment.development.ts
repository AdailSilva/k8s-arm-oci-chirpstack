// Perfil development: ng serve local (porta 4401), sem otimização.
export const environment = {
    production: false,
    staging: false,
    /** Endereço público do site neste perfil (links absolutos). */
    siteUrl: 'http://localhost:4401',
    /** false = a página pede aos buscadores para não indexar (robots noindex). */
    indexar: false,
    appName: 'ChirpStack v3 e v4 na OCI Always Free',
    version: '1.0.0'
};
