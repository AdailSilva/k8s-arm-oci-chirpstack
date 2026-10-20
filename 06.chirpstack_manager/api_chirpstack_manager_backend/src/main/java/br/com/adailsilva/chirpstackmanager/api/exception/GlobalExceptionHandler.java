package br.com.adailsilva.chirpstackmanager.api.exception;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import br.com.adailsilva.chirpstackmanager.api.service.chirpstack.ChirpStackException;
import br.com.adailsilva.chirpstackmanager.api.domain.dto.response.ApiError;

/**
 * Converte exceções em {@link ApiError} com mensagens em português.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ChirpStackException.class)
    public ResponseEntity<ApiError> chirpstack(ChirpStackException e) {
        Integer code = e.getGrpcCode();
        String detalhe = e.getChirpstackMessage();
        HttpStatus status;
        String erro;
        String msg;
        if (code == null) {
            status = HttpStatus.resolve(e.getHttpStatus());
            if (status == null) {
                status = HttpStatus.BAD_GATEWAY;
            }
            erro = "CHIRPSTACK";
            msg = "O ChirpStack retornou um erro.";
        } else {
            switch (code) {
                case 3, 11 -> { status = HttpStatus.BAD_REQUEST; erro = "DADOS_INVALIDOS"; msg = "O ChirpStack recusou os dados enviados."; }
                case 5 -> { status = HttpStatus.NOT_FOUND; erro = "NAO_ENCONTRADO"; msg = "Registro não encontrado no ChirpStack."; }
                case 6 -> { status = HttpStatus.CONFLICT; erro = "JA_EXISTE"; msg = "Já existe um registro com esse identificador."; }
                case 9 -> { status = HttpStatus.CONFLICT; erro = "PRE_CONDICAO"; msg = "A operação não é permitida no estado atual do registro."; }
                case 8 -> { status = HttpStatus.TOO_MANY_REQUESTS; erro = "LIMITE"; msg = "Limite do ChirpStack atingido (por exemplo, máximo de dispositivos ou gateways do tenant)."; }
                case 7, 16 -> {
                    // Não devolve 401/403: o frontend entenderia como sessão expirada do próprio usuário.
                    status = HttpStatus.BAD_GATEWAY; erro = "CREDENCIAL_CHIRPSTACK";
                    msg = "O ChirpStack recusou a credencial configurada no backend (API key ausente, inválida ou sem permissão).";
                }
                case 14, 4 -> { status = HttpStatus.SERVICE_UNAVAILABLE; erro = "INDISPONIVEL"; msg = "ChirpStack indisponível no momento. Tente novamente."; }
                case 12 -> { status = HttpStatus.NOT_IMPLEMENTED; erro = "NAO_SUPORTADO"; msg = "Operação não suportada por esta versão do ChirpStack."; }
                default -> { status = HttpStatus.BAD_GATEWAY; erro = "CHIRPSTACK"; msg = "O ChirpStack retornou um erro."; }
            }
        }
        if (status.is5xxServerError()) {
            log.warn("Erro do ChirpStack: {}", e.getMessage());
        }
        return ResponseEntity.status(status).body(ApiError.of(status.value(), erro, msg, detalhe));
    }

    @ExceptionHandler(br.com.adailsilva.chirpstackmanager.api.exception.CookieClearingException.class)
    public ResponseEntity<ApiError> cookieClearing(br.com.adailsilva.chirpstackmanager.api.exception.CookieClearingException e) {
        HttpStatus status = e.getOriginal() instanceof BusinessException b ? b.getStatus() : HttpStatus.UNAUTHORIZED;
        ResponseEntity.BodyBuilder r = ResponseEntity.status(status)
                .header(org.springframework.http.HttpHeaders.SET_COOKIE, e.getCookie().toString());
        String erro = "SESSAO";
        if (e.getOriginal() instanceof SessaoEncerradaException s) {
            r.header(SessaoEncerradaException.HEADER, SessaoEncerradaException.ENCERRADA)
                    .header(SessaoEncerradaException.HEADER_MOTIVO, s.getMotivo().name());
            erro = SessaoEncerradaException.CODIGO;
        }
        return r.body(ApiError.of(status.value(), erro, e.getOriginal().getMessage(), null));
    }

    @ExceptionHandler(SessaoEncerradaException.class)
    public ResponseEntity<ApiError> sessaoEncerrada(SessaoEncerradaException e) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .header(SessaoEncerradaException.HEADER, SessaoEncerradaException.ENCERRADA)
                .header(SessaoEncerradaException.HEADER_MOTIVO, e.getMotivo().name())
                .body(ApiError.of(401, SessaoEncerradaException.CODIGO, e.getMessage(), null));
    }

    @ExceptionHandler(br.com.adailsilva.chirpstackmanager.api.service.googledrive.GoogleDriveException.class)
    public ResponseEntity<ApiError> googleDrive(br.com.adailsilva.chirpstackmanager.api.service.googledrive.GoogleDriveException e) {
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(ApiError.of(502, "GOOGLE_DRIVE", e.getMessage(), null));
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiError> uploadGrande(MaxUploadSizeExceededException e) {
        return ResponseEntity.status(HttpStatus.CONTENT_TOO_LARGE).body(ApiError.of(413, "ARQUIVO_GRANDE",
                "O arquivo enviado passa do tamanho máximo permitido.", null));
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiError> business(BusinessException e) {
        return ResponseEntity.status(e.getStatus())
                .body(ApiError.of(e.getStatus().value(), "REGRA_NEGOCIO", e.getMessage(), null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> validation(MethodArgumentNotValidException e) {
        List<ApiError.Campo> campos = e.getBindingResult().getFieldErrors().stream()
                .map(f -> new ApiError.Campo(f.getField(), f.getDefaultMessage()))
                .toList();
        return ResponseEntity.badRequest().body(new ApiError(java.time.Instant.now(), 400, "VALIDACAO",
                "Verifique os campos informados.", null, campos));
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ApiError> methodValidation(HandlerMethodValidationException e) {
        return ResponseEntity.badRequest().body(ApiError.of(400, "IDENTIFICADOR_INVALIDO",
                "Identificador ou parâmetro em formato inválido.", null));
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ApiError> unreadable(Exception e) {
        return ResponseEntity.badRequest().body(ApiError.of(400, "REQUISICAO_INVALIDA",
                "Requisição em formato inválido.", null));
    }

    @ExceptionHandler({AccessDeniedException.class, AuthorizationDeniedException.class})
    public ResponseEntity<ApiError> denied(Exception e) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiError.of(403, "ACESSO_NEGADO",
                "Seu perfil não tem permissão para esta operação.", null));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiError> method(HttpRequestMethodNotSupportedException e) {
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(ApiError.of(405, "METODO",
                "Método não permitido.", null));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiError> notFound(NoResourceFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiError.of(404, "NAO_ENCONTRADO",
                "Recurso não encontrado.", null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> generic(Exception e) {
        log.error("Erro inesperado", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiError.of(500, "ERRO_INTERNO",
                "Erro inesperado no servidor.", null));
    }
}
