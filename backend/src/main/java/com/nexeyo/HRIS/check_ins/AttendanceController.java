package com.nexeyo.HRIS.check_ins;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

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



}
