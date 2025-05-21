package com.nexeyo.HRIS.check_ins;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Data;
import java.time.LocalDateTime;


@Entity
@Data
public class AttendanceRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)  // This works for SQLite
    private Long id;

    private int userId;

    private LocalDateTime checkInTime;

    private LocalDateTime checkOutTime;
}