package br.com.adailsilva.chirpstack.consumer;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
        "chirpstack.base-url=http://localhost:9999",
        "chirpstack.api-key=test-key"
})
class ChirpStackConsumerApplicationTests {

    @Test
    void contextLoads() {
    }
}
