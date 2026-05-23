package br.com.adailsilva.chirpstack.consumer.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "chirpstack")
public class ChirpStackProperties {

    private String baseUrl;
    private String apiKey;
}
