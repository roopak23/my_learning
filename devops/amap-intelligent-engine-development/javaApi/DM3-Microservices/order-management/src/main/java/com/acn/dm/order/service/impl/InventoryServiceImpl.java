package com.acn.dm.order.service.impl;

import com.acn.dm.common.rest.input.inventory.AdServers;
import com.acn.dm.common.rest.input.inventory.AdSlots;
import com.acn.dm.common.rest.input.inventory.Target;
import com.acn.dm.order.domains.ApiEvent;
import com.acn.dm.order.domains.ApiInventoryCheckNativeDTO;
import com.acn.dm.order.domains.pk.ApiInventoryCheckPK;
import com.acn.dm.order.repository.ApiEventRepository;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import com.acn.dm.order.rest.input.FrequencyCap;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.service.InventoryService;
import com.acn.dm.order.utils.Dimension;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;


import static com.acn.dm.order.utils.Const.EVENT_JOIN_VALUE;

@Slf4j
@Service
public class InventoryServiceImpl implements InventoryService {

    private ApiInventoryCheckRepository checkRepo;
    private ApiEventRepository eventRepo;

    public InventoryServiceImpl(ApiInventoryCheckRepository checkRepo, ApiEventRepository eventRepo) {
        this.checkRepo = checkRepo;
        this.eventRepo = eventRepo;
    }


    @Override
    public Optional<LocalDateTime> takeForecastFromRepoById(List<ApiInventoryCheckNativeDTO> dto) {
        return getMaxDate(dto);
    }

    public boolean isAllClash(List<ApiInventoryCheckNativeDTO> dtoList) {
        return !dtoList.isEmpty() && dtoList.stream().allMatch(dto -> "Y".equalsIgnoreCase(dto.getClash()));
    }

    @Override
    public List<ApiInventoryCheckNativeDTO> takeValuesFromRepoById(MarketOrderLineDetailsRequest request) {
        return makeQuery(request);
    }

    public List<ApiInventoryCheckNativeDTO> makeQuery(MarketOrderLineDetailsRequest request) {
        List<ApiInventoryCheckNativeDTO> results = buildAndExecCheckQuery(request);
        log.info("buildAndExecCheckQuery after");
        return results;
    }

    private List<ApiInventoryCheckNativeDTO> buildAndExecCheckQuery(MarketOrderLineDetailsRequest request) {

        log.info("before mapTargetsFromRequest");
        Map<String, List<String>> targets = mapTargetsFromRequest(request.getAdserver());
        log.info("after mapTargetsFromRequest");
        filterEvents(targets);
        filterCountry(targets);
        log.info("buildAndExecCheckQuery.inventorySelect");
        return checkRepo.inventorySelect(request.getMetric()
                , mapAdSlotFromRequest(request.getAdserver(), checkRepo)
                , request.getAppliedLabels()
                , request.getMarketOrderId()
                , mapAdServerFromRequest(request.getAdserver())
                , getCities(targets)
                , getExcludedCity(targets)
                , getStates(targets)
                , getExcludedState(targets)
                , getEvents(targets)
                , getVideoPositions(targets)
                , getPodPositions(targets)
                , getAudience(targets)
                , request.getStartDate()
                , request.getEndDate()
                , mapFrequencyCapFromRequest(request.getFrequencyCap()));

    }

    private static List<String> getVideoPositions(Map<String, List<String>> targets) {
        if (Objects.nonNull(targets.get(Dimension.VIDEO_POSITION.toString()))) {
            List<String> results = targets.get(Dimension.VIDEO_POSITION.toString())
                    .stream()
                    .filter(val -> !val.isEmpty() && !"ANY".equalsIgnoreCase(val) && !"ALL".equalsIgnoreCase(val))
                    .toList();
            return results.isEmpty() ? null : results;
        }
        return targets.get(Dimension.VIDEO_POSITION.toString());
    }

    protected static List<String> getPodPositions(Map<String, List<String>> targets) {
        if (Objects.nonNull(targets.get(Dimension.POD_POSITION.toString()))) {
            List<String> results = targets.get(Dimension.POD_POSITION.toString())
                    .stream()
                    .flatMap(val -> mapPodPosition(val).stream())
                    .distinct()
                    .toList();
            return results.isEmpty() ? null : results;
        }
        return targets.get(Dimension.POD_POSITION.toString());
    }

    private static List<String> mapPodPosition(String val) {
        if ("1".equals(val)) {
            return List.of("F", "FL");
        } else if ("100".equals(val)) {
            return List.of("L", "FL");
        }
        return List.of();
    }

    private static List<String> getEvents(Map<String, List<String>> targets) {
        return targets.get(Dimension.EVENT.toString());
    }

    private static List<String> getStates(Map<String, List<String>> targets) {
        return targets.get(Dimension.STATE.toString());
    }

    private static List<String> getCities(Map<String, List<String>> targets) {
        return targets.get(Dimension.CITY.toString());
    }

    private static List<String> getAudience(Map<String, List<String>> targets) {
        return targets.get(Dimension.AUDIENCE.toString());
    }

    private static List<String> getExcludedState(Map<String, List<String>> targets) {
        return targets.get(Dimension.EXCLUDED_STATE.toString());
    }

    private static List<String> getExcludedCity(Map<String, List<String>> targets) {
        return targets.get(Dimension.EXCLUDED_CITY.toString());
    }

    protected static List<String> mapFrequencyCapFromRequest(List<FrequencyCap> frequencyCaps) {
        if (Objects.isNull(frequencyCaps)) {
            return null;
        }
        return frequencyCaps.stream().map(cap -> String.format("%s-%d-%d", cap.getTimeUnit().toUpperCase(), cap.getMaxImpressions(), cap.getNumTimeUnits())).toList();
    }

    protected static List<String> mapAdSlotFromRequest(List<AdServers> adServers, ApiInventoryCheckRepository repository) {
        log.info(" mapAdSlotFromRequest start");
        List<String> adSlots = new ArrayList<>();
        adServers.forEach(adServer -> adServer.getAdslot().forEach(adslot -> {
            adSlots.add(adslot.getAdslotRemoteId());
            if (!adslot.isExcludeChilds())
                repository.findAllChildAdSlots(adslot.getAdslotRemoteId(), adServer.getAdserverId())
                        .forEach(childAdslot -> {
                            if (!childAdslot.getAdserver_adslot_id().isEmpty())
                                adSlots.add(childAdslot.getAdserver_adslot_id());
                        });
        }));
        log.info(" mapAdSlotFromRequest END");
        return adSlots;
    }

    protected static List<String> mapAdServerFromRequest(List<AdServers> adServers) {
        return adServers.stream().map(AdServers::getAdserverId).toList();
    }

    protected static Map<String, List<String>> mapTargetsFromRequest(List<AdServers> adServers) {
        return adServers
                .stream()
                .flatMap(adServer -> adServer.getTargeting().stream())
                .flatMap(target -> getType(target).stream())
                .collect(Collectors.groupingBy(
                        Map.Entry::getKey,
                        Collectors.mapping(Map.Entry::getValue, Collectors.toList())
                ));
    }


    protected static List<Map.Entry<String, String>> getType(Target target) {
        if ("GEO".equalsIgnoreCase(target.getTargetType())
                && (Dimension.STATE.toString().equalsIgnoreCase(target.getTargetCategory()) ||
                Dimension.CITY.toString().equalsIgnoreCase(target.getTargetCategory()))) {
            Dimension key;
            if (target.getExclude()) {
                key = Dimension.STATE.toString().equalsIgnoreCase(target.getTargetCategory()) ? Dimension.EXCLUDED_STATE : Dimension.EXCLUDED_CITY;
            } else {
                key = Dimension.STATE.toString().equalsIgnoreCase(target.getTargetCategory()) ? Dimension.STATE : Dimension.CITY;
            }
            return List.of(Map.entry(key.toString(), target.getTargetRemoteName()));
        } else if ("GEO".equalsIgnoreCase(target.getTargetType())
                && Dimension.COUNTRY.toString().equalsIgnoreCase(target.getTargetCategory())) {
            return List.of(Map.entry(Dimension.COUNTRY.toString(), target.getTargetRemoteName()));
        } else if ("KeyValue".equalsIgnoreCase(target.getTargetType())) {
            return List.of(Map.entry(Dimension.EVENT.toString(), String.join(EVENT_JOIN_VALUE, target.getTargetName(), target.getTargetRemoteName())));
        } else if ("VideoPosition".equalsIgnoreCase(target.getTargetType())) {
            return List.of(Map.entry(Dimension.VIDEO_POSITION.toString(), target.getPosition()),
                    Map.entry(Dimension.POD_POSITION.toString(), target.getPositionPod()));
        } else if ("AudienceSegment".equalsIgnoreCase(target.getTargetType()) || "Audience Segment".equalsIgnoreCase(target.getTargetType())) {
            return List.of(Map.entry(Dimension.AUDIENCE.toString(), target.getTargetRemoteName()));
        }
        return List.of(Map.entry(target.getTargetType().toLowerCase(), target.getTargetRemoteName()));
    }

    private Optional<LocalDateTime> getMaxDate(List<ApiInventoryCheckNativeDTO> inventoryChecks) {
        return inventoryChecks.stream()
                .filter(inventoryCheck -> inventoryCheck.getFutureCapacity() > 0 || ("Y".equalsIgnoreCase(inventoryCheck.getUseOverwrite()) && inventoryCheck.getOverwrittenImpressions() > 0))
                .map(inventoryCheck -> inventoryCheck.getDate())
                .max(LocalDateTime::compareTo);
    }

    public List<ApiInventoryCheckPK> takeOutOfForecastValues(MarketOrderLineDetailsRequest request) {
        return request.getAdserver().parallelStream()
                .map(adServers -> adServerToPK(adServers, request))
                .flatMap(List::stream)
                .toList();
    }

    private List<ApiInventoryCheckPK> adServerToPK(AdServers adServers, MarketOrderLineDetailsRequest request) {
        return adServers.getAdslot()
                .stream()
                .map(adSlots -> generateApiPkKeysToOutOfForecast(adSlots, request, adServers.getTargeting(), adServers.getAdserverId()))
                .flatMap(List::stream)
                .toList();
    }


    private List<ApiInventoryCheckPK> generateApiPkKeysToOutOfForecast(AdSlots adSlot
            , MarketOrderLineDetailsRequest request, List<Target> targets, String adServerId) {

        Map<String, List<String>> targetsTypes = targets
                .parallelStream()
                .flatMap(target -> getType(target).stream())
                .collect(Collectors.groupingBy(
                        Map.Entry::getKey,
                        Collectors.collectingAndThen(
                                Collectors.mapping(Map.Entry::getValue, Collectors.toSet()),
                                ArrayList::new
                        )
                ));
        filterEvents(targetsTypes);
        filterCountry(targetsTypes);
        filterStateAndCityOutOfForecast(targetsTypes);
        filterPodsPositionOutForecast(targetsTypes);
        filterVideoPositionOutForecast(targetsTypes);

        if (Objects.isNull(targetsTypes.get(Dimension.CITY.toString())) || targetsTypes.get(Dimension.CITY.toString()).isEmpty()) {
            targetsTypes.put(Dimension.CITY.toString(), List.of(""));
        }
        if (Objects.isNull(targetsTypes.get(Dimension.STATE.toString())) || targetsTypes.get(Dimension.STATE.toString()).isEmpty()) {
            targetsTypes.put(Dimension.STATE.toString(), List.of(""));
        }
        if (Objects.isNull(targetsTypes.get(Dimension.EVENT.toString())) || targetsTypes.get(Dimension.EVENT.toString()).isEmpty()) {
            targetsTypes.put(Dimension.EVENT.toString(), List.of(""));
        }
        if (Objects.isNull(targetsTypes.get(Dimension.AUDIENCE.toString())) || targetsTypes.get(Dimension.AUDIENCE.toString()).isEmpty()) {
            targetsTypes.put(Dimension.AUDIENCE.toString(), List.of(""));
        }
        if (Objects.isNull(targetsTypes.get(Dimension.POD_POSITION.toString())) || targetsTypes.get(Dimension.POD_POSITION.toString()).isEmpty()) {
            targetsTypes.put(Dimension.POD_POSITION.toString(), List.of(""));
        }
        if (Objects.isNull(targetsTypes.get(Dimension.VIDEO_POSITION.toString())) || targetsTypes.get(Dimension.VIDEO_POSITION.toString()).isEmpty()) {
            targetsTypes.put(Dimension.VIDEO_POSITION.toString(), List.of("ANY"));
        }
        List<ApiInventoryCheckPK> keys = new ArrayList<>();

        for (LocalDate date : generateDates(request.getStartDate(), request.getEndDate())) {
            for (String state : targetsTypes.get(Dimension.STATE.toString())) {
                for (String city : targetsTypes.get(Dimension.CITY.toString())) {
                    for (String event : targetsTypes.get(Dimension.EVENT.toString())) {
                        for (String podPosition : targetsTypes.get(Dimension.POD_POSITION.toString())) {
                            for (String videoPosition : targetsTypes.get(Dimension.VIDEO_POSITION.toString())) {
                                ApiInventoryCheckPK key = new ApiInventoryCheckPK();
                                key.setMetric(request.getMetric());
                                key.setAdserverAdslotId(adSlot.getAdslotRemoteId());
                                key.setDate(date.atStartOfDay());
                                key.setAdserverId(adServerId);
                                key.setCity(city);
                                key.setState(state);
                                key.setEvent(event);
                                key.setPodPosition(podPosition);
                                key.setVideoPosition(videoPosition);
                                keys.add(key);
                            }
                        }
                    }
                }
            }
        }
        return keys;
    }


    public List<LocalDate> generateDates(LocalDate startDate, LocalDate endDate) {
        long numOfDaysBetween = ChronoUnit.DAYS.between(startDate, endDate) + 1;
        return IntStream.iterate(0, i -> i + 1)
                .limit(numOfDaysBetween)
                .mapToObj(i -> startDate.plusDays(i))
                .collect(Collectors.toList());
    }

    @Override
    public Map<ApiInventoryCheckPK, Integer> takeDailyCapacityPerTargetRemoteId(List<ApiInventoryCheckNativeDTO> list) {
        return list.stream().collect(Collectors.toMap(this::mapToChecPkFromDTO, this::mapNegativeStock));
    }

    private int mapNegativeStock(ApiInventoryCheckNativeDTO f) {
        try {
            if (getCapacity(f) <= (f.getBooked() + f.getReserved())) {
                return 1;
            }
            return (int) Math.ceil((getCapacity(f) - (f.getBooked() + f.getReserved()))
                    * f.getAvgPercent() * f.getFactor());
        } catch (Exception e) {
            if (Objects.nonNull(f)) {
                log.info("id = {}, future_capacity = {}, booked = {}, reserved = {}, use_overwrite = {}, overwritten_impressions = {}, missing_forecast = {}, clash = {}"
                        , f.getId()
                        , f.getFutureCapacity()
                        , f.getBooked()
                        , f.getReserved()
                        , f.getUseOverwrite()
                        , f.getOverwrittenImpressions()
                        , f.getMissingForecast()
                        , f.getClash());
            } else {
                log.info("dto is null");
            }
            throw e;
        }
    }

    private ApiInventoryCheckPK mapToChecPkFromDTO(ApiInventoryCheckNativeDTO dto) {
        return ApiInventoryCheckPK.builder()
                .adserverAdslotId(dto.getAdServerAdslotId())
                .adserverId(dto.getAdServerId())
                .date(dto.getDate())
                .city(dto.getCity())
                .state(dto.getState())
                .event(dto.getEvent())
                .videoPosition(dto.getVideoPosition())
                .podPosition(dto.getPodPosition())
                .metric(dto.getMetric())
                .build();
    }

    public Map<ApiInventoryCheckPK, Integer> takeDailyCapacityPerAdSlot(List<ApiInventoryCheckNativeDTO> list) {

        Map<LocalDateTime, Integer> dailyCapacity = takeDailyCapacityPerTargetRemoteId(list)
                .entrySet().stream()
                .collect(Collectors.groupingBy(
                        entry -> entry.getKey().getDate(),
                        Collectors.summingInt(Map.Entry::getValue)
                ));

        return list.stream().collect(Collectors.toMap(this::mapToChecPkFromDTO, value -> dailyCapacity.get(value.getDate())));
    }

    private Integer getCapacity(ApiInventoryCheckNativeDTO check) {
        return "Y".equalsIgnoreCase(check.getUseOverwrite()) ? check.getOverwrittenImpressions() : check.getFutureCapacity();
    }

    private void filterEvents(Map<String, List<String>> targets) {
        if (Objects.nonNull(targets.get(Dimension.EVENT.toString()))) {
            Map<String, List<String>> dict = targets.get(Dimension.EVENT.toString()).stream()
                    .map(event -> event.split(EVENT_JOIN_VALUE))
                    .filter(split -> split.length == 2)
                    .collect(Collectors.groupingBy(
                            keyValue -> keyValue[0],
                            Collectors.mapping(keyValue -> keyValue[1], Collectors.toList())
                    ));

            List<String> events = eventRepo
                    .findEvents(dict.keySet(), dict.values().stream().flatMap(List::stream).toList())
                    .stream()
                    .filter(val -> checkEvent(val, dict))
                    .map(ApiEvent::getCombination)
                    .toList();

            targets.put(Dimension.EVENT.toString(), events);
        }
    }

    private static Boolean checkEvent(ApiEvent apiEvent, Map<String, List<String>> dict) {
        List<String> values = dict.get(apiEvent.getEventKey());
        return values.contains(apiEvent.getEventValue());
    }

    public static void filterCountry(Map<String, List<String>> targets) {
        if (Objects.nonNull(targets.get(Dimension.COUNTRY.toString()))) {
            targets.get(Dimension.COUNTRY.toString()).stream().filter("AUSTRALIA"::equalsIgnoreCase)
                    .findFirst()
                    .ifPresent(target -> removeCountryRelated(targets));
        }
    }

    public static void removeCountryRelated(Map<String, List<String>> targets) {
        targets.remove(Dimension.COUNTRY.toString());
        targets.remove(Dimension.CITY.toString());
        targets.remove(Dimension.STATE.toString());
    }

    public static void filterStateAndCityOutOfForecast(Map<String, List<String>> targets) {
        if (Objects.nonNull(targets.get(Dimension.STATE.toString()))) {
            targets.remove(Dimension.CITY.toString());
        }
    }

    public static void filterPodsPositionOutForecast(Map<String, List<String>> targets) {
        List<String> pods = targets.get(Dimension.POD_POSITION.toString());
        if (Objects.nonNull(pods) && !pods.isEmpty() && (pods.contains("100") || pods.contains("1"))) {
            targets.put(Dimension.POD_POSITION.toString(), List.of("FL"));
        } else {
            targets.remove(Dimension.POD_POSITION.toString());
        }
    }

    public static void filterVideoPositionOutForecast(Map<String, List<String>> targets) {
        if (Objects.nonNull(targets.get(Dimension.VIDEO_POSITION.toString()))) {
            List<String> filterValues = targets.get(Dimension.VIDEO_POSITION.toString())
                    .stream()
                    .filter(val -> !val.isEmpty() && !"ANY".equalsIgnoreCase(val) && !"ALL".equalsIgnoreCase(val))
                    .toList();
            targets.put(Dimension.VIDEO_POSITION.toString(), filterValues);
        }
    }

}
