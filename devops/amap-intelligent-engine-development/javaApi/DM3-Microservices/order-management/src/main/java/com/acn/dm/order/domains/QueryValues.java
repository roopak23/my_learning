package com.acn.dm.order.domains;


import java.time.LocalDate;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import lombok.Data;

@Data
public class QueryValues {

    private LocalDate startDate;
    private LocalDate endDate;
    private Set<String> adslotId;
    Map<String, Set<String>> conditions;
    private Set<String> event;
    private Set<String> city;
    private Set<String> state;
    private String metric;
    private Set<String> adserverId;

    public Set<String> getEvent() {
        return Objects.isNull(event) || event.isEmpty() ? Set.of("") : event;
    }

    public Set<String> getCity() {
        return Objects.isNull(city)  || city.isEmpty() ? Set.of("") : city;
    }

    public Set<String> getState() {
        return Objects.isNull(state) || state.isEmpty()? Set.of("") : state;
    }

    public Set<String> getAdserverId() {
        return Objects.isNull(adserverId) || adserverId.isEmpty()? Set.of("") : adserverId;
    }

    public Set<String> getAdslotId() {
        return Objects.isNull(adslotId) || adslotId.isEmpty()? Set.of("") : adslotId;
    }
}
