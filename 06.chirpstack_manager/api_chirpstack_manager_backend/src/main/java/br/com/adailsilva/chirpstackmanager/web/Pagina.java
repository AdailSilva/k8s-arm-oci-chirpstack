package br.com.adailsilva.chirpstackmanager.web;

import java.util.List;
import java.util.function.Function;

import org.springframework.data.domain.Page;

/**
 * Página de resultados no mesmo formato das listas do ChirpStack ({@code result} + {@code totalCount}),
 * para que o frontend trate todas as tabelas da mesma forma.
 */
public record Pagina<T>(List<T> result, long totalCount) {

    public static <E, T> Pagina<T> of(Page<E> page, Function<E, T> mapper) {
        return new Pagina<>(page.getContent().stream().map(mapper).toList(), page.getTotalElements());
    }
}
