package com.acn.dm.inventory.projection;

public interface CheckProjectionDTO {

    String getMetric();
    Long getAvailable();
    Long getCapacity();
    Long getReserved();
    Long getBooked();
    String getClash();
}
