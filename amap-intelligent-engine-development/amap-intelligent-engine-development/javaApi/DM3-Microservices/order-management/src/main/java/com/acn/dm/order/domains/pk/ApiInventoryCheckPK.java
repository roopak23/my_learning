package com.acn.dm.order.domains.pk;

import java.time.LocalDateTime;
import java.util.Objects;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApiInventoryCheckPK {

    private String adserverAdslotId;
    private LocalDateTime date;
    private String metric;
    private String state;
    private String city;
    private String event;
    private String videoPosition;
    private String podPosition;
    private String adserverId;

    public ApiInventoryCheckPK(LocalDateTime date, String adserverId, String metric, String adserverAdslotId, String city, String state, String event, String podPosition, String videoPosition) {
        this.date = date;
        this.adserverId = adserverId;
        this.metric = metric;
        this.adserverAdslotId = adserverAdslotId;
        this.city = city;
        this.state = state;
        this.event = event;
        this.podPosition = podPosition;
        this.videoPosition = videoPosition;
    }

    public ApiInventoryCheckPK(LocalDateTime date, String adserverId, String metric, String adserverAdslotId) {
        this.date = date;
        this.adserverId = adserverId;
        this.metric = metric;
        this.adserverAdslotId = adserverAdslotId;
    }


    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ApiInventoryCheckPK that = (ApiInventoryCheckPK) o;
        return Objects.equals(decorateString(adserverAdslotId), decorateString(that.adserverAdslotId))
                && Objects.equals(date, that.date)
                && Objects.equals(decorateString(metric), decorateString(that.metric))
                && Objects.equals(decorateString(state), decorateString(that.state))
                && Objects.equals(decorateString(city), decorateString(that.city))
                && Objects.equals(decorateString(event), decorateString(that.event))
                && Objects.equals(decorateString(videoPosition), decorateString(that.videoPosition))
                && Objects.equals(decorateString(podPosition), decorateString(that.podPosition))
                && Objects.equals(decorateString(adserverId), decorateString(that.adserverId));
    }

    @Override
    public int hashCode() {
        return Objects.hash(decorateString(adserverAdslotId)
                , date
                , decorateString(metric)
                , decorateString(state)
                , decorateString(city)
                , decorateString(event)
                , decorateString(videoPosition)
                , decorateString(podPosition)
                , decorateString(adserverId));
    }

    private String decorateString(String value) {
        return Objects.nonNull(value) ? value.toLowerCase() : value;
    }
}
