/**
 * Codec ChirpStack v3 — payload ASCII
 *
 * Device-profiles > (perfil) > aba CODEC >
 *   Payload codec: "Custom JavaScript codec functions"
 *
 * Motor JS do v3: otto (somente ES5 — sem let/const, arrow functions,
 * template strings, TextDecoder etc.).
 *
 * Uplink de exemplo:
 *   data (base64): "QWRhaWxTaWx2YS1Jb1Q="
 *   bytes (hex)  : 416461696c53696c76612d496f54
 *   object       : { "text": "AdailSilva-IoT", "length": 14, ... }
 */

/**
 * Decodifica o uplink (bytes -> objeto).
 * @param {number}   fPort     porta da aplicação
 * @param {number[]} bytes     bytes do FRMPayload
 * @param {object}   variables variáveis do device
 * @returns {object} vira o campo "object" do evento de uplink
 */
function Decode(fPort, bytes, variables) {
  if (!bytes || bytes.length === 0) {
    // No v3, lançar erro gera um evento "error" com tipo UPLINK_CODEC
    throw new Error("payload vazio");
  }

  var text = "";
  var hex = "";
  var nonPrintable = 0;

  for (var i = 0; i < bytes.length; i++) {
    var b = bytes[i] & 0xff;
    hex += (b < 16 ? "0" : "") + b.toString(16);

    if (b >= 0x20 && b <= 0x7e) {
      // ASCII imprimível
      text += String.fromCharCode(b);
    } else if (b === 0x0a || b === 0x0d || b === 0x09) {
      // \n, \r, \t
      text += String.fromCharCode(b);
    } else if (b === 0x00 && i === bytes.length - 1) {
      // terminador '\0' no fim (comum em firmware C): ignora
    } else {
      text += "?";
      nonPrintable++;
    }
  }

  var result = {
    text: text,
    length: bytes.length,
    hex: hex,
    fPort: fPort
  };

  // O v3 não tem campo "warnings": o aviso vai dentro do próprio objeto
  if (nonPrintable > 0) {
    result.warning = nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'";
  }

  return result;
}

/**
 * Codifica o downlink (objeto -> bytes).
 * Uso no ChirpStack v3 (Device > Queue > "JSON object"):
 *   { "text": "LED ON" }
 * @param {number} fPort     porta do downlink
 * @param {object} obj       objeto JSON enfileirado
 * @param {object} variables variáveis do device
 * @returns {number[]} bytes do FRMPayload
 */
function Encode(fPort, obj, variables) {
  var text = obj && obj.text;

  if (typeof text !== "string" || text.length === 0) {
    throw new Error("informe o campo 'text' (string não vazia)");
  }

  var bytes = [];
  for (var i = 0; i < text.length; i++) {
    var c = text.charCodeAt(i);
    if (c > 0x7e) {
      throw new Error("caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'");
    }
    bytes.push(c);
  }

  return bytes;
}
