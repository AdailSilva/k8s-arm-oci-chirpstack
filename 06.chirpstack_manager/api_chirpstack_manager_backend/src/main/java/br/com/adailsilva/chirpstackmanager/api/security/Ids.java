package br.com.adailsilva.chirpstackmanager.api.security;

/**
 * Formatos aceitos nos identificadores de caminho. Validar antes de repassar ao ChirpStack
 * impede que valores arbitrários alterem o caminho da requisição.
 */
public final class Ids {

    /** UUID (tenants, aplicações, perfis, usuários, grupos multicast). */
    public static final String UUID = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$";
    /** EUI-64 em hexadecimal (DevEUI, Gateway ID). */
    public static final String EUI64 = "^[0-9a-fA-F]{16}$";
    /** Relay ID (4 bytes em hexadecimal). */
    public static final String RELAY_ID = "^[0-9a-fA-F]{8}$";
    /** ID de template de device-profile (texto livre, sem barras). */
    public static final String TEMPLATE_ID = "^[A-Za-z0-9._:-]{1,128}$";

    /** Prefixo de DevAddr com máscara, ex.: 0000ff00/24. */
    public static final String DEVADDR_PREFIX = "^[0-9a-fA-F]{8}/([0-9]|[12][0-9]|3[0-2])$";
    /** Filtro de tag de dispositivo no formato chave=valor (sem caracteres de URI template). */
    public static final String TAG_FILTRO = "^[A-Za-z0-9 _.:-]{1,64}=[A-Za-z0-9 _.:@/-]{0,128}$";

    private Ids() {
    }
}
