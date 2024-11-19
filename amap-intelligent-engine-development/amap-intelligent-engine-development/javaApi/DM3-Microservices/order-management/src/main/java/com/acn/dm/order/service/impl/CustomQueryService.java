package com.acn.dm.order.service.impl;

import com.acn.dm.order.domains.ApiInventoryCheck;
import com.acn.dm.order.domains.ApiInventoryCheckNativeDTO;
import com.acn.dm.order.domains.pk.ApiInventoryCheckPK;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.LocalDate;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@AllArgsConstructor
public class CustomQueryService {

    private final ApiInventoryCheckRepository repository;
    private EntityManager entityManager;

    public List<ApiInventoryCheck> findEntitiesByCompositeKeys(Collection<ApiInventoryCheckPK> keys) {
        if (Objects.isNull(keys) || keys.isEmpty()) {
            return List.of();
        }
        List<ApiInventoryCheckPK> list = keys.stream().toList();
        log.info(list.toString());
        StringBuilder jpql = new StringBuilder("SELECT t FROM ApiInventoryCheck t WHERE ");
        for (int i = 0; i < list.size(); i++) {
            jpql.append("(t.adserverAdslotId = :adserverAdslotId").append(i)
                    .append(" AND t.date = :date").append(i)
                    .append(" AND t.metric = :metric").append(i)
                    .append(" AND t.state = :state").append(i)
                    .append(" AND t.city = :city").append(i)
                    .append(" AND t.event = :event").append(i)
                    .append(" AND t.videoPosition = :videoPosition").append(i)
                    .append(" AND t.podPosition = :podPosition").append(i)
                    .append(" AND t.adserverId = :adserverId").append(i)
                    .append(")");
            if (i < list.size() - 1) {
                jpql.append(" OR ");
            }
        }
        TypedQuery<ApiInventoryCheck> query = entityManager.createQuery(jpql.toString(), ApiInventoryCheck.class);
        for (int i = 0; i < keys.size(); i++) {
            query.setParameter("adserverAdslotId" + i, list.get(i).getAdserverAdslotId());
            query.setParameter("date" + i, list.get(i).getDate());
            query.setParameter("metric" + i, list.get(i).getMetric());
            query.setParameter("state" + i, list.get(i).getState());
            query.setParameter("city" + i, list.get(i).getCity());
            query.setParameter("event" + i, list.get(i).getEvent());
            query.setParameter("videoPosition" + i, list.get(i).getVideoPosition());
            query.setParameter("podPosition" + i, list.get(i).getPodPosition());
            query.setParameter("adserverId" + i, list.get(i).getAdserverId());

        }
        return query.getResultList();
    }

    public List<ApiInventoryCheck> findEntitiesByKey(Collection<ApiInventoryCheckPK> keys) {
        if (Objects.isNull(keys) || keys.isEmpty()) {
            return List.of();
        }

        log.info("before prepare query");
        Set<ApiInventoryCheckPK> hashKeys = new HashSet<>(keys);
        String metric = hashKeys.stream().findFirst().map(ApiInventoryCheckPK::getMetric).orElse(null);
        LocalDate startDate = null;
        LocalDate endDate = null;
        Set<String> adSlot = new HashSet<>();
        Set<String> city = new HashSet<>();
        Set<String> adServer = new HashSet<>();
        Set<String> state = new HashSet<>();
        Set<String> event = new HashSet<>();
        Set<String> videoPos = new HashSet<>();
        Set<String> podPos = new HashSet<>();

        for (ApiInventoryCheckPK key : hashKeys) {
            adSlot.add(key.getAdserverAdslotId());
            adServer.add(key.getAdserverId());
            city.add(key.getCity());
            state.add(key.getState());
            event.add(key.getEvent());
            videoPos.add(key.getVideoPosition());
            podPos.add(key.getPodPosition());
            LocalDate currentDate = key.getDate().toLocalDate();
            if (Objects.isNull(startDate) || currentDate.isBefore(startDate)) {
                startDate = currentDate;
            }
            if (Objects.isNull(endDate) || currentDate.isAfter(endDate)) {
                endDate = currentDate;
            }
        }
        log.info("after prepare query - {}", hashKeys.size());

        log.info("before custom query");
        List<ApiInventoryCheck> results = repository.inventorySelectByKey(metric
                , adSlot
                , adServer
                , city
                , state
                , event
                , videoPos
                , podPos
                , startDate
                , endDate);
        log.info("after custom query");
        List<ApiInventoryCheck> apiInventoryChecks = new HashSet<>(results).stream()
                .filter(result -> compareKeys(result, hashKeys))
                .toList();
        log.info("after map custom query results");
        return apiInventoryChecks;
    }

    private boolean compareKeys(ApiInventoryCheck result, Set<ApiInventoryCheckPK> keys) {
        ApiInventoryCheckPK apiInventoryCheckPK = new ApiInventoryCheckPK(result.getDate()
                , result.getAdserverId()
                , result.getMetric()
                , result.getAdserverAdslotId()
                , result.getCity()
                , result.getState()
                , result.getEvent()
                , result.getPodPosition()
                , result.getVideoPosition());
        return keys.contains(apiInventoryCheckPK);
    }

    private ApiInventoryCheck mapToCheckFromDTO(ApiInventoryCheckNativeDTO dto) {
        return ApiInventoryCheck.builder()
                .id(dto.getId())
                .adserverAdslotId(dto.getAdServerAdslotId())
                .adserverId(dto.getAdServerId())
                .audienceName(dto.getAudienceName())
                .date(dto.getDate())
                .city(dto.getCity())
                .state(dto.getState())
                .event(dto.getEvent())
                .videoPosition(dto.getVideoPosition())
                .podPosition(dto.getPodPosition())
                .metric(dto.getMetric())
                .futureCapacity(dto.getFutureCapacity())
                .reserved(dto.getReserved())
                .booked(dto.getBooked())
                .useOverwrite(dto.getUseOverwrite())
                .overwritingReason(dto.getOverwritingReason())
                .percentageOfOverwriting(dto.getPercentageOfOverwriting())
                .overwriting(dto.getOverwriting())
                .overwrittenImpressions(dto.getOverwrittenImpressions())
                .updatedBy(null)
                .overwrittenExpiryDate(dto.getOverwrittenExpiryDate())
                .missingForecast(dto.getMissingForecast())
                .adServerAdslotName(dto.getAdServerAdslotName())
                .version(dto.getVersion())
                .build();
    }

}
