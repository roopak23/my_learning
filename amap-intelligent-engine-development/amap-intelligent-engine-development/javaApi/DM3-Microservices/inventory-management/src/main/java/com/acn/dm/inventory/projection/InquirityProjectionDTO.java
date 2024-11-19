package com.acn.dm.inventory.projection;

public interface InquirityProjectionDTO {

    String getMetric();
    Long getAvailable();
    Long getCapacity();
    Long getReserved();
    Long getBooked();

}
