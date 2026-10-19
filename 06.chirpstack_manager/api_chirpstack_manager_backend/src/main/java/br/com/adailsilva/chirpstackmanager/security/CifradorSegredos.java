package br.com.adailsilva.chirpstackmanager.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Cifragem reversível de segredos de configuração (AES-256-GCM).
 * <p>
 * Senhas de usuário usam hash porque o sistema só precisa CONFERIR o que é digitado. Já o refresh
 * token do Google e o Client Secret precisam ser ENTREGUES de volta ao Google, então são cifrados:
 * no banco fica só o texto cifrado e a chave mora fora dele ({@code APP_CHAVE_CIFRAGEM}). Um dump
 * do banco — inclusive os próprios backups — não revela os segredos.
 * <p>
 * Formato: {@code v1:BASE64(IV[12] || CIFRADO || TAG[16])}. A finalidade entra como AAD: um valor
 * cifrado para um campo não decifra em outro.
 * <p>
 * Sem {@code APP_CHAVE_CIFRAGEM}, a chave é derivada do segredo do JWT (com aviso no log): trocar o
 * segredo do JWT obriga a reconectar a conta Google.
 */
@Component
public class CifradorSegredos {

    private static final Logger log = LoggerFactory.getLogger(CifradorSegredos.class);
    private static final String PREFIXO = "v1:";
    private static final String ALGORITMO = "AES/GCM/NoPadding";
    private static final int IV_BYTES = 12;
    private static final int TAG_BITS = 128;

    private final SecureRandom aleatorio = new SecureRandom();
    private final SecretKey chave;
    private final boolean chaveDedicada;

    public CifradorSegredos(@Value("${app.security.chave-cifragem:}") String chaveConfigurada,
                            @Value("${app.security.jwt-secret:}") String segredoJwt) {
        if (chaveConfigurada != null && !chaveConfigurada.isBlank()) {
            this.chave = new SecretKeySpec(derivar(chaveConfigurada.trim()), "AES");
            this.chaveDedicada = true;
        } else {
            log.warn("APP_CHAVE_CIFRAGEM não definida: a chave que protege os segredos do Google Drive será "
                    + "derivada do segredo do JWT. Gere uma chave dedicada com: openssl rand -base64 32");
            this.chave = new SecretKeySpec(sha256("chirpstack-manager|config|" + (segredoJwt == null ? "" : segredoJwt)),
                    "AES");
            this.chaveDedicada = false;
        }
    }

    public boolean isChaveDedicada() {
        return chaveDedicada;
    }

    public String cifrar(String textoPlano, String finalidade) {
        try {
            byte[] iv = new byte[IV_BYTES];
            aleatorio.nextBytes(iv);
            Cipher c = Cipher.getInstance(ALGORITMO);
            c.init(Cipher.ENCRYPT_MODE, chave, new GCMParameterSpec(TAG_BITS, iv));
            c.updateAAD(finalidade.getBytes(StandardCharsets.UTF_8));
            byte[] cifrado = c.doFinal(textoPlano.getBytes(StandardCharsets.UTF_8));
            byte[] saida = new byte[iv.length + cifrado.length];
            System.arraycopy(iv, 0, saida, 0, iv.length);
            System.arraycopy(cifrado, 0, saida, iv.length, cifrado.length);
            return PREFIXO + Base64.getEncoder().encodeToString(saida);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao cifrar o segredo.", e);
        }
    }

    /**
     * Lança {@link IllegalStateException} se o valor foi gravado com outra chave, adulterado ou
     * pertence a outra finalidade.
     */
    public String decifrar(String valorGravado, String finalidade) {
        if (valorGravado == null || !valorGravado.startsWith(PREFIXO)) {
            throw new IllegalStateException("Formato de segredo desconhecido.");
        }
        try {
            byte[] dados = Base64.getDecoder().decode(valorGravado.substring(PREFIXO.length()));
            if (dados.length <= IV_BYTES) {
                throw new IllegalStateException("Segredo truncado.");
            }
            Cipher c = Cipher.getInstance(ALGORITMO);
            c.init(Cipher.DECRYPT_MODE, chave, new GCMParameterSpec(TAG_BITS, dados, 0, IV_BYTES));
            c.updateAAD(finalidade.getBytes(StandardCharsets.UTF_8));
            return new String(c.doFinal(dados, IV_BYTES, dados.length - IV_BYTES), StandardCharsets.UTF_8);
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Não foi possível decifrar o segredo (chave diferente ou valor adulterado).", e);
        }
    }

    private static byte[] derivar(String configurada) {
        try {
            byte[] b = Base64.getDecoder().decode(configurada);
            if (b.length == 32) {
                return b;
            }
        } catch (IllegalArgumentException ignorado) {
            // não é Base64: trata como frase
        }
        return sha256(configurada);
    }

    private static byte[] sha256(String texto) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(texto.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
