package org.perfecto.micro.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Slf4j
@Component
public class GlobalLoggingFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        log.info("Incoming request: {} {}", exchange.getRequest().getMethod(), exchange.getRequest().getURI());
        
        long startTime = System.currentTimeMillis();
        
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            long executionTime = System.currentTimeMillis() - startTime;
            log.info("Outgoing response: {} {} with status code {} in {}ms", 
                    exchange.getRequest().getMethod(), 
                    exchange.getRequest().getURI(), 
                    exchange.getResponse().getStatusCode(),
                    executionTime);
        }));
    }

    @Override
    public int getOrder() {
        return -1; // Highest precedence
    }
}
