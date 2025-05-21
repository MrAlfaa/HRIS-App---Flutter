package com.nexeyo.HRIS.check_ins;

import com.nexeyo.HRIS.check_ins.AttendanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, Long> {
    Optional<AttendanceRecord> findFirstByUserIdAndCheckInTimeBetween(int userId, LocalDateTime startOfDay, LocalDateTime endOfDay);

    Optional<AttendanceRecord> findFirstByUserIdAndCheckInTimeBetweenAndCheckOutTimeIsNull(int userId, LocalDateTime startOfDay, LocalDateTime endOfDay);
}
