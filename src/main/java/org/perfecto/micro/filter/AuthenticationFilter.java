package org.perfecto.micro.filter;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class AuthenticationFilter extends AbstractGatewayFilterFactory<AuthenticationFilter.Config> {

    public AuthenticationFilter() {
        super(Config.class);
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            
            // Example Placeholder Logic: Check for Authorization Header
            String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            if (authHeader == null) {
                // If no authorization header, return 401 Unauthorized immediately
                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                return exchange.getResponse().setComplete();
            }
            
            // Example Placeholder Logic: Validate JWT token here
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                // try {
                //    jwtUtil.validateToken(token);
                // } catch (Exception e) {
                //    exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                //    return exchange.getResponse().setComplete();
                // }
            }

            // Pass the request if authenticated
            return chain.filter(exchange);
        };
    }

    public static class Config {
        // Configuration properties for the filter can be added here
    }
}
