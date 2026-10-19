package br.com.adailsilva.chirpstackmanager.chirpstack;

/**
 * Erro devolvido pela REST API do ChirpStack (ou falha ao falar com ela).
 * <p>
 * A chirpstack-rest-api responde erros no formato gRPC: {@code {"code": 5, "message": "...", "details": []}}.
 */
public class ChirpStackException extends RuntimeException {

    private final int httpStatus;
    private final Integer grpcCode;
    private final String chirpstackMessage;

    public ChirpStackException(int httpStatus, Integer grpcCode, String chirpstackMessage) {
        super("ChirpStack respondeu HTTP " + httpStatus + (grpcCode != null ? " (gRPC " + grpcCode + ")" : "")
                + (chirpstackMessage != null ? ": " + chirpstackMessage : ""));
        this.httpStatus = httpStatus;
        this.grpcCode = grpcCode;
        this.chirpstackMessage = chirpstackMessage;
    }

    public int getHttpStatus() {
        return httpStatus;
    }

    public Integer getGrpcCode() {
        return grpcCode;
    }

    public String getChirpstackMessage() {
        return chirpstackMessage;
    }
}
