package br.com.adailsilva.chirpstackmanager.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * ChirpStack Manager API.
 * <p>
 * Backend-for-frontend que expõe, com autenticação própria e controle de acesso por perfil,
 * todas as operações da REST API do ChirpStack v4. A API key do ChirpStack fica somente aqui.
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class ChirpstackManagerApplication {

    public static void main(String[] args) {
        SpringApplication.run(ChirpstackManagerApplication.class, args);
    }
}
