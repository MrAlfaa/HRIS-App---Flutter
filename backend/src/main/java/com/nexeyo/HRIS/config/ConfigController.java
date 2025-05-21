package com.nexeyo.HRIS.config;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.HashMap;
import java.util.Map;

@RestController
public class ConfigController {

    @GetMapping("/api/status")
    public Map<String, Object> getApiStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "online");
        response.put("message", "API is running");
        response.put("version", "1.0.0");
        return response;
    }
    
    @GetMapping("/test-connection")
    public Map<String, Object> testConnection() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Successfully connected to the backend");
        return response;
    }
};