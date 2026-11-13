// Perfil staging: build de produção servido localmente (porta 4402) para conferência antes do deploy.
export const environment = {
    production: true,
    staging: true,
    /** Endereço público do site neste perfil (links absolutos). */
    siteUrl: 'http://localhost:4402',
    /** false = a página pede aos buscadores para não indexar (robots noindex). */
    indexar: false,
    appName: 'ChirpStack v3 e v4 na OCI Always Free',
    version: '1.0.0'
};
