/**
 * Perfil staging (homologação: backend :8082, frontend :4202). O frontend sempre fala com o backend pelo mesmo host (/api):
 * no ng serve pelo proxy (src/proxy-config.staging.json) e no container pelo NGINX/Ingress.
 * Assim o cookie do refresh token é same-site.
 */
export const environment = {
    production: false,
    staging: true,
    perfil: 'staging' as 'development' | 'staging' | 'production',
    appName: 'ChirpStack Manager',
    apiUrl: '/api/v1'
};
