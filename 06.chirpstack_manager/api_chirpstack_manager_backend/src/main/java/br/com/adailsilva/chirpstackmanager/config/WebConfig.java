package br.com.adailsilva.chirpstackmanager.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import br.com.adailsilva.chirpstackmanager.auditoria.AuditoriaInterceptor;

@Configuration
@EnableScheduling
public class WebConfig implements WebMvcConfigurer {

    private final AuditoriaInterceptor auditoria;

    public WebConfig(AuditoriaInterceptor auditoria) {
        this.auditoria = auditoria;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(auditoria).addPathPatterns("/api/v1/chirpstack/**", "/api/v1/usuarios/**");
    }
}
