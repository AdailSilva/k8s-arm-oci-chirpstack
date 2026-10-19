/**
 * Perfil production (backend :8083, frontend :4203). O frontend sempre fala com o backend pelo mesmo host (/api):
 * no ng serve pelo proxy (src/proxy-config.production.json) e no container pelo NGINX/Ingress.
 * Assim o cookie do refresh token é same-site.
 */
export const environment = {
    production: true,
    staging: false,
    perfil: 'production' as 'development' | 'staging' | 'production',
    appName: 'ChirpStack Manager',
    apiUrl: '/api/v1'
};
