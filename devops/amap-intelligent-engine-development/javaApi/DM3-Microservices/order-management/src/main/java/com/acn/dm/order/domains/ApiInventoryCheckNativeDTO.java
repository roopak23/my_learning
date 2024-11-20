package com.acn.dm.order.domains;
import java.time.LocalDateTime;

public interface ApiInventoryCheckNativeDTO {

    public Long getId();
    public String getClash();
    public LocalDateTime getDate();
    public String getAdServerId();
    public String getMetric();
    public String getAdServerAdslotId();
    public String getAdServerAdslotName();
    public String getCity();
    public String getState();
    public String getEvent();
    public String getAudienceName();
    public String getPodPosition();
    public String getVideoPosition();
    public Integer getFutureCapacity();
    public Integer getReserved();
    public Integer getBooked();
    public String getOverwriting();
    public String getPercentageOfOverwriting();
    public Integer getOverwrittenImpressions();
    public String getOverwritingReason();
    public String getUseOverwrite();
    public Double getAvgPercent();
    public Double getFactor();
    public LocalDateTime getOverwrittenExpiryDate();
    public String getUpdatedBy();
    public String getMissingForecast();
    public Long getVersion();



}
