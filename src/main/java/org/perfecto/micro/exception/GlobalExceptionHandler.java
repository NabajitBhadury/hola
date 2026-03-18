package org.perfecto.micro.exception;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.web.server.WebExceptionHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.core.io.buffer.DataBufferFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Configuration
@Order(-2) // Gives it higher priority than the DefaultErrorWebExceptionHandler
public class GlobalExceptionHandler implements WebExceptionHandler {

    private final ObjectMapper objectMapper;

    public GlobalExceptionHandler() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule()); // Support Java 8 Date/Time
    }

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;

        if (ex instanceof ResponseStatusException) {
            status = (HttpStatus) ((ResponseStatusException) ex).getStatusCode();
        }

        ErrorResponse errorResponse = ErrorResponse.builder()
                .status(status.value())
                .error(status.getReasonPhrase())
                .message(ex.getMessage() != null ? ex.getMessage() : "An unexpected error occurred")
                .path(exchange.getRequest().getPath().value())
                .build();

        exchange.getResponse().setStatusCode(status);
        exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);

        DataBufferFactory bufferFactory = exchange.getResponse().bufferFactory();
        try {
            byte[] errorBytes = objectMapper.writeValueAsBytes(errorResponse);
            DataBuffer dataBuffer = bufferFactory.wrap(errorBytes);
            return exchange.getResponse().writeWith(Mono.just(dataBuffer));
        } catch (JsonProcessingException e) {
            DataBuffer dataBuffer = bufferFactory.wrap(new byte[0]);
            return exchange.getResponse().writeWith(Mono.just(dataBuffer));
        }
    }
}
