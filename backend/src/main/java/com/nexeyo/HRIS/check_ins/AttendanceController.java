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
    public AttendanceRecord checkIn(@RequestParam int id) {
        return attendanceService.checkIn(id);
    }

    @PostMapping("/checkout/{id}")
    public AttendanceRecord checkOut(@RequestParam int id) {
        return attendanceService.checkOut(id);
    }
    
    @GetMapping("/status/{id}")
    public AttendanceRecord getAttendanceStatus(@PathVariable int id) {
        return attendanceService.getAttendanceStatus(id);
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
            
            AttendanceRecord record = attendanceService.checkIn(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("record", record);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
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
            
            AttendanceRecord record = attendanceService.checkOut(userId);
            if (record == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "No active check-in found");
                return ResponseEntity.badRequest().body(response);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("record", record);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}
