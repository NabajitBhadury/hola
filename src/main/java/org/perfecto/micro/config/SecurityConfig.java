package org.perfecto.micro.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            // The API Gateway delegates all actual endpoint security to downstream microservices
            // or we use custom GatewayFilters for route-specific security. We permit all natively
            // at the Spring Security level to avoid WebFlux blocking the filters.
            .authorizeExchange(exchanges -> exchanges.anyExchange().permitAll());

        return http.build();
    }
}
