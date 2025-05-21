package com.nexeyo.HRIS.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;



@Service
public class UserService {

    @Autowired
    private UserRepo userRepo;

    public User saveUser(User user) {
        // Basic validation
        if (user.getUsername() == null || user.getUsername().trim().isEmpty()) {
            throw new RuntimeException("Username cannot be empty");
        }
        
        if (user.getPassword() == null || user.getPassword().length() < 6) {
            throw new RuntimeException("Password must be at least 6 characters long");
        }
        
        // Check if username already exists
        if (userRepo.findByUsername(user.getUsername()) != null) {
            throw new RuntimeException("Username already exists!");
        }
        
        try {
            return userRepo.save(user);
        } catch (Exception e) {
            throw new RuntimeException("Failed to save user: " + e.getMessage());
        }
    }

//    public User findUserByUsername(String username) {
//        return userRepo.findByUsername(username);
//    }

    public User validateUser(String username, String password) {
        if (username == null || username.trim().isEmpty()) {
            return null;
        }
        
        if (password == null || password.isEmpty()) {
            return null;
        }
        
        try {
            User user = userRepo.findByUsername(username);
            if (user != null && user.getPassword().equals(password)) {
                return user;
            } else {
                return null;
            }
        } catch (Exception e) {
            // Log the exception
            System.err.println("Error validating user: " + e.getMessage());
            return null;
        }
    }
}