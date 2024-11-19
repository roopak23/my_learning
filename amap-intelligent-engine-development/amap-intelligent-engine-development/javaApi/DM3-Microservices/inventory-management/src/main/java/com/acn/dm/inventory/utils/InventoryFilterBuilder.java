package com.acn.dm.inventory.utils;

import com.acn.dm.inventory.domains.ApiEvent;
import com.acn.dm.inventory.repository.ApiEventRepository;
import com.acn.dm.inventory.repository.ApiInventoryCheckRepository;
import com.acn.dm.inventory.rest.input.AdServers;
import com.acn.dm.inventory.rest.input.FrequencyCap;
import com.acn.dm.inventory.rest.input.Target;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;


import static com.acn.dm.inventory.utils.Const.EVENT_JOIN_VALUE;
import static java.util.stream.Collectors.toList;

/**
 * @author Shivani Chaudhary
 */
public abstract class InventoryFilterBuilder {

    protected static List<String> getVideoPositions(Map<String, List<String>> targets) {
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

    protected static List<String> getEvents(Map<String, List<String>> targets) {
        return targets.get(Dimension.EVENT.toString());
    }

    protected static List<String> getStates(Map<String, List<String>> targets) {
        return targets.get(Dimension.STATE.toString());
    }

    protected static List<String> getCities(Map<String, List<String>> targets) {
        return targets.get(Dimension.CITY.toString());
    }

    protected static List<String> getAudience(Map<String, List<String>> targets) {
        return targets.get(Dimension.AUDIENCE.toString());
    }

    protected static List<String> getExcludedState(Map<String, List<String>> targets) {
        return targets.get(Dimension.EXCLUDED_STATE.toString());
    }

    protected static List<String> getExcludedCity(Map<String, List<String>> targets) {
        return targets.get(Dimension.EXCLUDED_CITY.toString());
    }


    protected static List<String> mapExcludedAdSlotFromRequest(List<AdServers> adServers) {
        List<String> excludedAdSlots = new ArrayList<>();
        adServers.forEach(ad -> {
            if (!Objects.isNull(ad.getExcludedAdSlot())) excludedAdSlots.addAll(ad.getExcludedAdSlot());
        });

        return excludedAdSlots.isEmpty() ? null : excludedAdSlots;
    }

    protected static List<String> mapFrequencyCapFromRequest(List<FrequencyCap> frequencyCaps) {
        if (Objects.isNull(frequencyCaps)) {
            return null;
        }
        return frequencyCaps.stream().map(cap -> String.format("%s-%d-%d", cap.getTimeUnit().toUpperCase(), cap.getMaxImpressions(), cap.getNumTimeUnits())).toList();
    }

    protected static List<String> mapAdSlotFromRequest(List<AdServers> adServers, ApiInventoryCheckRepository repository) {
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
                        Collectors.mapping(Map.Entry::getValue, toList())
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


    public static void filterEvents(Map<String, List<String>> targets, ApiEventRepository eventRepo) {
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


}
