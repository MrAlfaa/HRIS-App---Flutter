package com.nexeyo.HRIS.check_ins;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    @Autowired
    private AttendanceService attendanceService;

    @PostMapping("/checkin")
    public ResponseEntity<?> checkIn(@RequestParam int id) {
        try {
            AttendanceRecord record = attendanceService.checkIn(id);
            return ResponseEntity.ok(record);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/checkout/{id}")
    public ResponseEntity<?> checkOut(@RequestParam int id) {
        try {
            AttendanceRecord record = attendanceService.checkOut(id);
            return ResponseEntity.ok(record);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/status/{id}")
    public ResponseEntity<?> getAttendanceStatus(@PathVariable int id) {
        try {
            AttendanceRecord record = attendanceService.getAttendanceStatus(id);
            return ResponseEntity.ok(record);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
      @PostMapping("/face-checkin")
      public ResponseEntity<?> faceCheckIn(@RequestBody Map<String, Object> request) {
          try {
              Integer userId = (Integer) request.get("userId");
              if (userId == null) {
                  Map<String, Object> response = new HashMap<>();
                  response.put("error", "User ID is required");
                  return ResponseEntity.badRequest().body(response);
              }
            
              // Check if user already has an open check-in today
              AttendanceRecord existingRecord = attendanceService.getAttendanceStatus(userId);
              if (existingRecord != null && existingRecord.getCheckInTime() != null && existingRecord.getCheckOutTime() == null) {
                  Map<String, Object> response = new HashMap<>();
                  response.put("error", "You are already checked in today");
                  return ResponseEntity.badRequest().body(response);
              }
            
              Double latitude = 0.0;
              Double longitude = 0.0;
              String address = "";
            
              if (request.containsKey("location")) {
                  Map<String, Object> location = (Map<String, Object>) request.get("location");
                  latitude = (Double) location.getOrDefault("latitude", 0.0);
                  longitude = (Double) location.getOrDefault("longitude", 0.0);
                  address = (String) location.getOrDefault("address", "");
              }
            
              AttendanceRecord record = attendanceService.checkIn(userId, latitude, longitude, address);
            
              Map<String, Object> response = new HashMap<>();
              response.put("success", true);
              response.put("record", record);
              return ResponseEntity.ok(response);
            
          } catch (RuntimeException e) {
              Map<String, Object> response = new HashMap<>();
              response.put("error", e.getMessage());
              return ResponseEntity.badRequest().body(response);
          } catch (Exception e) {
              Map<String, Object> response = new HashMap<>();
              response.put("error", "Unexpected error: " + e.getMessage());
              return ResponseEntity.internalServerError().body(response);
          }
    }

    @PostMapping("/face-checkout")
    public ResponseEntity<?> faceCheckOut(@RequestBody Map<String, Object> request) {
        try {
            Integer userId = (Integer) request.get("userId");
            if (userId == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "User ID is required");
                return ResponseEntity.badRequest().body(response);
            }
            
            Double latitude = 0.0;
            Double longitude = 0.0;
            String address = "";
            
            if (request.containsKey("location")) {
                Map<String, Object> location = (Map<String, Object>) request.get("location");
                latitude = (Double) location.getOrDefault("latitude", 0.0);
                longitude = (Double) location.getOrDefault("longitude", 0.0);
                address = (String) location.getOrDefault("address", "");
            }
            
            AttendanceRecord record = attendanceService.checkOut(userId, latitude, longitude, address);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("record", record);
            return ResponseEntity.ok(response);
            
        } catch (RuntimeException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Unexpected error: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
