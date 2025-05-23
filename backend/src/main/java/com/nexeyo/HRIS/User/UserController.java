
package com.nexeyo.HRIS.User;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;


@RestController
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody User user1) {
        try {
            if (user1.getUsername() == null || user1.getUsername().isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "Username cannot be empty");
                return ResponseEntity.badRequest().body(response);
            }
            
            if (user1.getPassword() == null || user1.getPassword().isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "Password cannot be empty");
                return ResponseEntity.badRequest().body(response);
            }
            
            User savedUser = userService.saveUser(user1);
            
            Map<String, Object> response = new HashMap<>();
            response.put("id", savedUser.getId());
            response.put("username", savedUser.getUsername());
            response.put("message", "User registered successfully");
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "An unexpected error occurred: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginUser(@RequestBody LoginRequest loginRequest) {
        try {
            User user = userService.validateUser(loginRequest.getUsername(), loginRequest.getPassword());

            if (user != null) {
                Map<String, Object> response = new HashMap<>();
                response.put("id", user.getId());
                response.put("username", user.getUsername());
                response.put("message", "User login successfully");
                return ResponseEntity.ok(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("message", "Invalid username or password");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "An unexpected error occurred: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    
    // Simple endpoint to test if authentication is working
    @GetMapping("/auth-test")
    public ResponseEntity<?> testAuthentication() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Authentication system is working");
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/api/users/verify-username")
    public ResponseEntity<?> verifyUsername(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        
        if (username == null || username.trim().isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Username cannot be empty");
            return ResponseEntity.badRequest().body(response);
        }
        
        User user = userService.findUserByUsername(username);
        
        if (user != null) {
            Map<String, Object> response = new HashMap<>();
            response.put("id", user.getId());
            response.put("username", user.getUsername());
            response.put("message", "Username verified");
            return ResponseEntity.ok(response);
        } else {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Username not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    }
}