package org.perfecto.micro.filter;

import org.perfecto.micro.client.IamServiceClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import org.springframework.web.server.ServerWebExchange;

import java.util.Map;

@Component
public class JwtAuthenticationFilter extends AbstractGatewayFilterFactory<JwtAuthenticationFilter.Config> {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    @Autowired
    private IamServiceClient iamServiceClient;

    public JwtAuthenticationFilter() {
        super(Config.class);
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            ServerHttpRequest request = exchange.getRequest();
            String path = request.getURI().getPath();

            if (path.startsWith("/api/v1/auth/")) {
                return chain.filter(exchange);
            }

            if (!request.getHeaders().containsKey(HttpHeaders.AUTHORIZATION)) {
                return onError(exchange, "Missing authorization header", HttpStatus.UNAUTHORIZED);
            }

            String authHeader = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return onError(exchange, "Invalid authorization header format", HttpStatus.UNAUTHORIZED);
            }

            // Using boundedElastic as OpenFeign represents a blocking operation.
            return Mono.fromCallable(() -> iamServiceClient.validateToken(authHeader))
                    .subscribeOn(Schedulers.boundedElastic())
                    .flatMap(response -> {
                        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                            Map<String, Object> claims = response.getBody();
                            ServerHttpRequest mutatedRequest = populateRequestWithHeaders(exchange, claims);
                            log.debug("Token validation successful. Proxied to downstream with user claims.");
                            return chain.filter(exchange.mutate().request(mutatedRequest).build());
                        } else {
                            return onError(exchange, "Invalid or expired token", HttpStatus.UNAUTHORIZED);
                        }
                    })
                    .onErrorResume(e -> {
                        log.error("Error validating token via IAM service", e);
                        return onError(exchange, "Authentication service unavailable or token is invalid", HttpStatus.UNAUTHORIZED);
                    });
        };
    }

    private Mono<Void> onError(ServerWebExchange exchange, String err, HttpStatus httpStatus) {
        log.warn("Authentication Error: {}", err);
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(httpStatus);
        return response.setComplete();
    }

    private ServerHttpRequest populateRequestWithHeaders(ServerWebExchange exchange, Map<String, Object> claims) {
        String uid = claims.get("uid") != null ? claims.get("uid").toString() : "";
        String role = claims.get("role") != null ? claims.get("role").toString() : "";

        return exchange.getRequest()
                .mutate()
                .header("X-User-Id", uid)
                .header("X-User-Roles", role)
                .build();
    }

    public static class Config {
        // Configuration properties if needed
    }
}
