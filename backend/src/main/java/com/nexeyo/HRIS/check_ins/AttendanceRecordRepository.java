package com.nexeyo.HRIS.check_ins;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;

public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, Long> {
    
    @Query("SELECT a FROM AttendanceRecord a WHERE a.userId = :userId AND a.checkInTime BETWEEN :startOfDay AND :endOfDay")
    Optional<AttendanceRecord> findFirstByUserIdAndCheckInTimeBetween(
        @Param("userId") int userId, 
        @Param("startOfDay") LocalDateTime startOfDay, 
        @Param("endOfDay") LocalDateTime endOfDay);

    @Query("SELECT a FROM AttendanceRecord a WHERE a.userId = :userId AND a.checkInTime BETWEEN :startOfDay AND :endOfDay AND a.checkOutTime IS NULL")
    Optional<AttendanceRecord> findFirstByUserIdAndCheckInTimeBetweenAndCheckOutTimeIsNull(
        @Param("userId") int userId, 
        @Param("startOfDay") LocalDateTime startOfDay, 
        @Param("endOfDay") LocalDateTime endOfDay);
}
