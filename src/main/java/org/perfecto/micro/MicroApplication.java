package org.perfecto.micro;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients
public class MicroApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicroApplication.class, args);
    }

}
