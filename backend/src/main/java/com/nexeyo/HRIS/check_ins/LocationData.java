package com.nexeyo.HRIS.check_ins;

import lombok.Data;

@Data
public class LocationData {
    private double latitude;
    private double longitude;
    private String address;
    
    // Default constructor
    public LocationData() {
    }
    
    // Constructor with all fields
    public LocationData(double latitude, double longitude, String address) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
    }
}