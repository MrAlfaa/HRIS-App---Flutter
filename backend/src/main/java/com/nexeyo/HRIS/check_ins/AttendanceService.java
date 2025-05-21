package com.nexeyo.HRIS.check_ins;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Optional;

@Service
public class AttendanceService {

    @Autowired
    private AttendanceRecordRepository attendanceRepository;

    public AttendanceRecord checkIn(int userId) {
        return checkIn(userId, 0.0, 0.0, "");
    }
    
    public AttendanceRecord checkIn(int userId, double latitude, double longitude, String address) {
        // Get the start and end of the current day
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().atTime(LocalTime.MAX);

        // Check if the user has already checked in today
        Optional<AttendanceRecord> existingRecord = attendanceRepository
                .findFirstByUserIdAndCheckInTimeBetween(userId, startOfDay, endOfDay);

        if (existingRecord.isPresent()) {
            if (existingRecord.get().getCheckOutTime() == null) {
                throw new RuntimeException("User already checked in today");
            } else {
                throw new RuntimeException("User has already completed check-in/check-out for today");
            }
        }

        // Create a new attendance record
        AttendanceRecord record = new AttendanceRecord();
        record.setUserId(userId);
        record.setCheckInTime(LocalDateTime.now());
        record.setCheckInLatitude(latitude);
        record.setCheckInLongitude(longitude);
        record.setCheckInAddress(address);
        
        return attendanceRepository.save(record);
    }

    public AttendanceRecord checkOut(int userId) {
        return checkOut(userId, 0.0, 0.0, "");
    }
    
    public AttendanceRecord checkOut(int userId, double latitude, double longitude, String address) {
        // Get the start and end of the current day
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().atTime(LocalTime.MAX);

        // Find the user's check-in record for today that doesn't have a check-out time
        Optional<AttendanceRecord> record = attendanceRepository
                .findFirstByUserIdAndCheckInTimeBetweenAndCheckOutTimeIsNull(userId, startOfDay, endOfDay);

        if (!record.isPresent()) {
            throw new RuntimeException("No active check-in found for today");
        }

        // Update the record with check-out information
        AttendanceRecord attendanceRecord = record.get();
        attendanceRecord.setCheckOutTime(LocalDateTime.now());
        attendanceRecord.setCheckOutLatitude(latitude);
        attendanceRecord.setCheckOutLongitude(longitude);
        attendanceRecord.setCheckOutAddress(address);
        
        return attendanceRepository.save(attendanceRecord);
    }
    
    public AttendanceRecord getAttendanceStatus(int userId) {
        // Get the start and end of the current day
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().atTime(LocalTime.MAX);

        // Find today's attendance record for the user
        Optional<AttendanceRecord> record = attendanceRepository
                .findFirstByUserIdAndCheckInTimeBetween(userId, startOfDay, endOfDay);

        if (!record.isPresent()) {
            // Return an empty record if no attendance found
            AttendanceRecord emptyRecord = new AttendanceRecord();
            emptyRecord.setUserId(userId);
            return emptyRecord;
        }

        return record.get();
    }
}
