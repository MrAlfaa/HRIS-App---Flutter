package com.nexeyo.HRIS.check_ins;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class AttendanceService {

    @Autowired
    private AttendanceRecordRepository attendanceRecordRepository;

    public AttendanceRecord checkIn(int id) {

        LocalDate today = LocalDate.now();

        Optional<AttendanceRecord> existingRecordOpt = attendanceRecordRepository
                .findFirstByUserIdAndCheckInTimeBetween(id, today.atStartOfDay(), today.plusDays(1).atStartOfDay());

        if (existingRecordOpt.isPresent()) {
            throw new RuntimeException("User with id: " + id + " has already checked in today.");
        }

        AttendanceRecord record = new AttendanceRecord();
        record.setUserId(id);
        record.setCheckInTime(LocalDateTime.now());
        return attendanceRecordRepository.save(record);
    }

    public AttendanceRecord checkOut(int id) {

        LocalDate today = LocalDate.now();

        Optional<AttendanceRecord> recordOpt = attendanceRecordRepository
                .findFirstByUserIdAndCheckInTimeBetweenAndCheckOutTimeIsNull(id, today.atStartOfDay(), today.plusDays(1).atStartOfDay());

        if (recordOpt.isPresent()) {
            AttendanceRecord record = recordOpt.get();
            record.setCheckOutTime(LocalDateTime.now());
            return attendanceRecordRepository.save(record);
        } else {
            throw new RuntimeException("No check-in record found for user with id: " + id + " for today.");
        }
    }
    public AttendanceRecord getAttendanceStatus(int userId) {
        LocalDate today = LocalDate.now();
        Optional<AttendanceRecord> recordOpt = attendanceRecordRepository
                .findFirstByUserIdAndCheckInTimeBetween(userId, today.atStartOfDay(), today.plusDays(1).atStartOfDay());

        return recordOpt.orElseThrow(() -> new RuntimeException("No attendance record found for user with id: " + userId));
    }
}
