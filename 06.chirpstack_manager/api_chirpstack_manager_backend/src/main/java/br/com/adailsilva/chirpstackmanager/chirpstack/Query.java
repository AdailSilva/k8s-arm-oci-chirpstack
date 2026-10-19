package br.com.adailsilva.chirpstackmanager.chirpstack;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Montagem dos parâmetros de consulta repassados ao ChirpStack. Valores nulos ou vazios são ignorados.
 */
public final class Query {

    private final Map<String, Object> params = new LinkedHashMap<>();

    private Query() {
    }

    public static Query of() {
        return new Query();
    }

    public Query add(String name, Object value) {
        if (value != null && !(value instanceof String s && s.isBlank())) {
            params.put(name, value);
        }
        return this;
    }

    /**
     * Paginação: o ChirpStack exige {@code limit}; quando ausente usa 10, e o teto é {@code max}.
     */
    public Query page(Long limit, Long offset, int max) {
        long l = (limit == null || limit < 1) ? 10 : Math.min(limit, max);
        params.put("limit", l);
        params.put("offset", (offset == null || offset < 0) ? 0 : offset);
        return this;
    }

    public Map<String, Object> asMap() {
        return params;
    }
}
