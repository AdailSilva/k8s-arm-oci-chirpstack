package br.com.adailsilva.chirpstack.consumer.service;

import br.com.adailsilva.chirpstack.consumer.client.ChirpStackClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserService {

    private final ChirpStackClient client;

    public Mono<JsonNode> listUsers(int limit, int offset) {
        return client.get(String.format("/api/users?limit=%d&offset=%d", limit, offset));
    }

    public Mono<JsonNode> createUser(Map<String, Object> body) {
        return client.post("/api/users", body);
    }

    public Mono<JsonNode> getUser(String id) {
        return client.get("/api/users/" + id);
    }

    public Mono<JsonNode> updateUser(String id, Map<String, Object> body) {
        return client.put("/api/users/" + id, body);
    }

    public Mono<JsonNode> deleteUser(String id) {
        return client.delete("/api/users/" + id);
    }

    public Mono<JsonNode> updatePassword(String userId, Map<String, Object> body) {
        return client.put("/api/users/" + userId + "/password", body);
    }
}
