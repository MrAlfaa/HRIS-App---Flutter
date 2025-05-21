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
    
    private double checkInLatitude;
    
    private double checkInLongitude;
    
    private String checkInAddress;

    private LocalDateTime checkOutTime;
    
    private double checkOutLatitude;
    
    private double checkOutLongitude;
    
    private String checkOutAddress;
}