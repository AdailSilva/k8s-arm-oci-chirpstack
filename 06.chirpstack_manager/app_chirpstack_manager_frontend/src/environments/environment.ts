/**
 * Arquivo padrão: substituído no build pelo environment.<perfil>.ts (angular.json).
 * Perfil development (backend :8081, frontend :4201). O frontend sempre fala com o backend pelo mesmo host (/api):
 * no ng serve pelo proxy (src/proxy-config.development.json) e no container pelo NGINX/Ingress.
 * Assim o cookie do refresh token é same-site.
 */
export const environment = {
    production: false,
    staging: false,
    perfil: 'development' as 'development' | 'staging' | 'production',
    appName: 'ChirpStack Manager',
    apiUrl: '/api/v1'
};
