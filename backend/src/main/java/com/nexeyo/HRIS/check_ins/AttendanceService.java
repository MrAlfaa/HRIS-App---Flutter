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
    private AttendanceRecordRepository attendanceRecordRepository;

    public AttendanceRecord checkIn(int userId) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MIDNIGHT);
        LocalDateTime endOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);

        // Check if already checked in today
        Optional<AttendanceRecord> existingRecord = attendanceRecordRepository
                .findFirstByUserIdAndCheckInTimeBetween(userId, startOfDay, endOfDay);

        if (existingRecord.isPresent()) {
            return existingRecord.get(); // Already checked in
        }

        // Create new check-in record
        AttendanceRecord record = new AttendanceRecord();
        record.setUserId(userId);
        record.setCheckInTime(now);
        return attendanceRecordRepository.save(record);
    }

    public AttendanceRecord checkOut(int userId) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MIDNIGHT);
        LocalDateTime endOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);

        // Find today's attendance record with null check-out time
        Optional<AttendanceRecord> existingRecord = attendanceRecordRepository
                .findFirstByUserIdAndCheckInTimeBetweenAndCheckOutTimeIsNull(userId, startOfDay, endOfDay);

        if (existingRecord.isPresent()) {
            AttendanceRecord record = existingRecord.get();
            record.setCheckOutTime(now);
            return attendanceRecordRepository.save(record);
        }

        return null; // No check-in record found
    }

    public AttendanceRecord getAttendanceStatus(int userId) {
        LocalDateTime startOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MIDNIGHT);
        LocalDateTime endOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);

        Optional<AttendanceRecord> todaysRecord = attendanceRecordRepository
                .findFirstByUserIdAndCheckInTimeBetween(userId, startOfDay, endOfDay);

        return todaysRecord.orElse(new AttendanceRecord());
    }
}
