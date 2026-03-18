package org.perfecto.micro.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.Map;

@FeignClient(name = "iam-service")
public interface IamServiceClient {

    @GetMapping("/api/v1/auth/validate")
    ResponseEntity<Map<String, Object>> validateToken(@RequestHeader("Authorization") String token);
}
