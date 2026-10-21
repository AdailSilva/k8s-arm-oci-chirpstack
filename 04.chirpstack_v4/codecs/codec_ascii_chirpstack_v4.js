/**
 * Codec ChirpStack v4 — payload ASCII
 *
 * Device Profile > Codec > "JavaScript functions"
 *
 * Uplink de exemplo:
 *   data (base64): "QWRhaWxTaWx2YS1Jb1Q="
 *   bytes (hex)  : 41 64 61 69 6c 53 69 6c 76 61 2d 49 6f 54
 *   resultado    : { "text": "AdailSilva-IoT", ... }
 *
 * O ChirpStack já converte o base64 em array de bytes antes de chamar
 * decodeUplink (input.bytes), então aqui só traduzimos bytes -> texto.
 */

/**
 * Decodifica o uplink.
 * @param {object} input
 * @param {number[]} input.bytes     bytes do FRMPayload
 * @param {number}   input.fPort     porta da aplicação
 * @param {Date}     input.recvTime  horário de recepção
 * @param {object}   input.variables variáveis do device
 * @returns {{data?: object, warnings?: string[], errors?: string[]}}
 */
function decodeUplink(input) {
  var bytes = input.bytes || [];
  var warnings = [];

  if (bytes.length === 0) {
    return { errors: ["payload vazio"] };
  }

  var text = "";
  var hex = [];
  var nonPrintable = 0;

  for (var i = 0; i < bytes.length; i++) {
    var b = bytes[i] & 0xff;
    hex.push((b < 16 ? "0" : "") + b.toString(16));

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

  if (nonPrintable > 0) {
    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");
  }

  return {
    data: {
      text: text,
      length: bytes.length,
      hex: hex.join(""),
      fPort: input.fPort
    },
    warnings: warnings
  };
}

/**
 * Codifica o downlink: texto ASCII -> bytes.
 * Uso no ChirpStack (Queue > "JSON object"):
 *   { "text": "LED ON" }
 * @param {object} input
 * @param {object} input.data      objeto JSON enviado na fila
 * @param {object} input.variables variáveis do device
 * @returns {{bytes?: number[], warnings?: string[], errors?: string[]}}
 */
function encodeDownlink(input) {
  var text = input.data && input.data.text;

  if (typeof text !== "string" || text.length === 0) {
    return { errors: ["informe o campo 'text' (string não vazia)"] };
  }

  var bytes = [];
  for (var i = 0; i < text.length; i++) {
    var c = text.charCodeAt(i);
    if (c > 0x7e) {
      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };
    }
    bytes.push(c);
  }

  return { bytes: bytes };
}
