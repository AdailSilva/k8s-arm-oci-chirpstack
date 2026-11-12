// Perfil production: imagem Nginx publicada no cluster.
export const environment = {
    production: true,
    staging: false,
    /** Endereço público do site neste perfil (links absolutos). */
    siteUrl: 'https://chirpstack.adailsilva.com.br',
    /** false = a página pede aos buscadores para não indexar (robots noindex). */
    indexar: true,
    appName: 'ChirpStack v3 e v4 na OCI Always Free',
    version: '1.0.0'
};
