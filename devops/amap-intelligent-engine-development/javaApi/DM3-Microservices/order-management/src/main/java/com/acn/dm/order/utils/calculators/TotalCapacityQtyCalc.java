package com.acn.dm.order.utils.calculators;

import com.acn.dm.order.domains.ApiInventoryCheck;
import com.acn.dm.order.domains.ApiInventoryCheckNativeDTO;
import com.acn.dm.order.domains.pk.ApiInventoryCheckPK;
import com.acn.dm.order.lov.CalcType;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.models.TargetAndQuantityPerAdslot;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.service.InventoryService;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;


import static com.acn.dm.common.utils.component.NormalizeCalc.normalizeQuantity;


@Slf4j
@Component
public class TotalCapacityQtyCalc implements QtyCalc {

    protected final InventoryService inventoryService;
    @Value("${application.normalization.qty.value:null}")
    private Integer normalizationQtyValue;

    public TotalCapacityQtyCalc(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @Override
    public List<QuantityAndPeriod> calculate(MarketOrderLineDetailsRequest request, long allDays, CalcType calcType) {
        List<QuantityAndPeriod> result = new ArrayList<>();
        long days = getNumOfDaysBetween(request.getStartDate(), request.getEndDate());
        int normalizeQty = normalizeQuantity((int) Math.round(request.getQuantity() * ((double) days / allDays)), request.getVideoDuration(), normalizationQtyValue);
        if (calcType.equals(CalcType.WEIGHT)) {
            log.info("before WEIGHT query, mold - {}", request.getMoldId());
            List<ApiInventoryCheckNativeDTO> inventoryChecksDTO = inventoryService.takeValuesFromRepoById(request);
            log.info("after WEIGHT query, mold - {}", request.getMoldId());
            int dailyQuantity = getQty(getUnique(inventoryChecksDTO), normalizeQty);
            log.info("before WEIGHT (takeDailyCapacityPerAdSlot), mold - {}", request.getMoldId());
            Map<ApiInventoryCheckPK, Integer> dailyCapacity = inventoryService.takeDailyCapacityPerAdSlot(getNotClashValues(inventoryChecksDTO));
            log.info("after WEIGHT (takeDailyCapacityPerAdSlot), mold - {}", request.getMoldId());
            log.info("before WEIGHT (takeDailyCapacityPerTargetRemoteId), mold - {}", request.getMoldId());
            Map<ApiInventoryCheckPK, Integer> dailyCapacityPerTarget = inventoryService.takeDailyCapacityPerTargetRemoteId(getNotClashValues(inventoryChecksDTO));
            log.info("after WEIGHT (takeDailyCapacityPerTargetRemoteId), mold - {}", request.getMoldId());
            log.info("before WEIGHT (calc), mold - {}", request.getMoldId());
            List<ApiInventoryCheck> inventoryChecks = mapResultsToCheckFromDTO(inventoryChecksDTO);
            inventoryChecks.forEach(entry -> {
                        ApiInventoryCheckPK id = mapToPkFromCheck(entry);
                        if (Objects.nonNull(dailyCapacityPerTarget.get(id))) {
                            float calc = dailyCapacityPerTarget.get(id).longValue() /
                                    (float) dailyCapacity.get(id).longValue()
                                    * dailyQuantity;
                            int q = dailyQuantity < 0 ? (int) Math.floor(calc) : (int) Math.ceil(calc);
                            result.add(
                                    mapToTargetAndQty(entry,
                                            q, calcType
                                    ));
                        } else {
                            result.add(mapToTargetAndQty(entry, 0, CalcType.CLASH));
                        }
                    }
            );
            log.info("after WEIGHT (calc), mold - {}", request.getMoldId());
        } else if (calcType.equals(CalcType.LINEAR)) {
            List<ApiInventoryCheckPK> checksIds = inventoryService.takeOutOfForecastValues(request);
            int dailyQuantity = getQty(checksIds.size(), (normalizeQty));
            checksIds.forEach(inv -> result.add(mapToTargetAndQty(inv, dailyQuantity, calcType)));
        } else if (calcType.equals(CalcType.CLASH)) {
            List<ApiInventoryCheckNativeDTO> inventoryChecksDTO = inventoryService.takeValuesFromRepoById(request);
            List<ApiInventoryCheck> inventoryChecks = mapResultsToCheckFromDTO(inventoryChecksDTO);
            inventoryChecks.forEach(entry -> result.add(mapToTargetAndQty(entry, 0, CalcType.CLASH)));
        }
        log.info("moldId - {} [values after calc before limit - {}, qty to reserve after norm - {}, calcType - {}}",request.getMoldId(), result.stream()
                .map(val -> val.getTargetPerSlots().getQuantity()).mapToInt(Integer::intValue).sum()
                , normalizeQty
                , calcType);
        return fitQuantity(result, normalizeQty, request.getMoldId(), calcType);
    }

    private List<QuantityAndPeriod> fitQuantity(List<QuantityAndPeriod> list, int qty, String moldId, CalcType calcType) {
        List<QuantityAndPeriod> quantityAndPeriods = list.stream()
                .filter(val -> val.getTargetPerSlots().getQuantity() != 0)
                .sorted((a, b) -> Integer.compare(b.getTargetPerSlots().getQuantity(), a.getTargetPerSlots().getQuantity())).toList();

        int remainingQty = qty;
        List<QuantityAndPeriod> selectedQty = new ArrayList<>();
        List<QuantityAndPeriod> notSelectedQty = new ArrayList<>();

        for (QuantityAndPeriod quantityAndPeriod : quantityAndPeriods) {
            Integer quantity = quantityAndPeriod.getTargetPerSlots().getQuantity();
            if (Math.abs(quantity) <= Math.abs(remainingQty)) {
                selectedQty.add(quantityAndPeriod);
                remainingQty -= quantity;
            } else {
                notSelectedQty.add(quantityAndPeriod);
            }
        }

        if (remainingQty != 0) {
            for (QuantityAndPeriod quantityAndPeriod : notSelectedQty) {
                Integer quantity = quantityAndPeriod.getTargetPerSlots().getQuantity();
                if (remainingQty != 0 && Math.abs(quantity) >= Math.abs(remainingQty)) {
                    quantityAndPeriod.getTargetPerSlots().setQuantity(remainingQty);
                    selectedQty.add(quantityAndPeriod);
                    remainingQty -= remainingQty;
                }
            }
        }
        log.info("moldId - {} [values returned after limit  - {}, qty to reserve after norm - {}, calcType - {}, values not returned after limit  - {}, remainingQty - {}]", moldId, selectedQty.stream()
                        .map(val -> val.getTargetPerSlots().getQuantity()).mapToInt(Integer::intValue).sum()
                , qty
                , calcType,
                notSelectedQty.stream()
                        .map(val -> val.getTargetPerSlots().getQuantity()).mapToInt(Integer::intValue).sum(), remainingQty);
        return selectedQty;
    }

    private Long getUnique(List<ApiInventoryCheckNativeDTO> inventoryChecksDTO) {
        return inventoryChecksDTO.stream()
                .filter(dto -> Objects.isNull(dto.getClash()))
                .map(ApiInventoryCheckNativeDTO::getDate)
                .distinct()
                .count();
    }

    private List<ApiInventoryCheckNativeDTO> getNotClashValues(List<ApiInventoryCheckNativeDTO> inventoryChecksDTO) {
        return inventoryChecksDTO.stream()
                .filter(dto -> Objects.isNull(dto.getClash()))
                .toList();
    }

    private List<ApiInventoryCheck> mapResultsToCheckFromDTO(List<ApiInventoryCheckNativeDTO> inventoryChecksDTO) {
        return inventoryChecksDTO.stream()
                .map(this::mapToCheckFromDTO).toList();
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
                .version(dto.getVersion())
                .build();
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

    //@Override
    public List<QuantityAndPeriod> calculate(MarketOrderLineDetailsRequest request) {
        return null;
    }

    private int countQtyToAllocate(List<ApiInventoryCheck> inventoryChecks) {

        return inventoryChecks.stream().map(inv -> inv.getFutureCapacity() - (inv.getBooked() + inv.getReserved()))
                .reduce(0, Integer::sum);
    }

    private int countQtyWithCalcType(List<ApiInventoryCheck> inventoryChecks, String calcType) {

        return inventoryChecks.stream().map(inv -> inv.getFutureCapacity() - (inv.getBooked() + inv.getReserved()))
                .reduce(0, Integer::sum);
    }

    private int countQty(ApiInventoryCheck inv, int allQty, int toReserve) {
        int capacity = inv.getFutureCapacity() - (inv.getBooked() + inv.getReserved());
        double i = (double) capacity / allQty * toReserve;
        return (int) Math.round(i);
    }

    private long getNumOfDaysBetween(LocalDate startDate, LocalDate endDate) {
        return ChronoUnit.DAYS.between(startDate, endDate) + 1;
    }

    private QuantityAndPeriod mapToTargetAndQty(ApiInventoryCheck inventoryCheck, Integer qty, CalcType calcType) {
        TargetAndQuantityPerAdslot targetAndQuantityPerAdslot = TargetAndQuantityPerAdslot.builder()
                .adserverId(inventoryCheck.getAdserverId())
                .adslotId(inventoryCheck.getAdserverAdslotId())
                .city(decorateString(inventoryCheck.getCity()))
                .event(decorateString(inventoryCheck.getEvent()))
                .state(decorateString(inventoryCheck.getState()))
                .audienceName(decorateString(inventoryCheck.getAudienceName()))
                .podPosition(decorateString(inventoryCheck.getPodPosition()))
                .videoPosition(decorateString(inventoryCheck.getVideoPosition()))
                .overwriting(inventoryCheck.getOverwriting())
                .overwritingReason(inventoryCheck.getOverwritingReason())
                .overwrittenImpressions(inventoryCheck.getOverwrittenImpressions())
                .useOverwrite(inventoryCheck.getUseOverwrite())
                .percentageOfOverwriting(inventoryCheck.getPercentageOfOverwriting())
                .calcType(calcType)
                .id(inventoryCheck.getId())
                .overwrittenExpiryDate(inventoryCheck.getOverwrittenExpiryDate())
                .updatedBy(null)
                .build();
        targetAndQuantityPerAdslot.setQuantity(qty);
        boolean isClash = calcType.equals(CalcType.CLASH);
        return new QuantityAndPeriod(inventoryCheck.getDate(), isClash, targetAndQuantityPerAdslot);
    }

    private QuantityAndPeriod mapToTargetAndQty(ApiInventoryCheckPK inventoryCheckPk, Integer qty, CalcType calcType) {
        TargetAndQuantityPerAdslot targetAndQuantityPerAdslot = TargetAndQuantityPerAdslot.builder()
                .adserverId(inventoryCheckPk.getAdserverId())
                .adslotId(inventoryCheckPk.getAdserverAdslotId())
                .city(decorateString(inventoryCheckPk.getCity()))
                .event(decorateString(inventoryCheckPk.getEvent()))
                .state(decorateString(inventoryCheckPk.getState()))
                .podPosition(decorateString(inventoryCheckPk.getPodPosition()))
                .videoPosition(decorateString(inventoryCheckPk.getVideoPosition()))
                .calcType(calcType)
                .build();
        targetAndQuantityPerAdslot.setQuantity(qty);
        boolean isClash = calcType.equals(CalcType.CLASH);
        return new QuantityAndPeriod(inventoryCheckPk.getDate(), isClash, targetAndQuantityPerAdslot);
    }

    private String decorateString(String field) {
        return Objects.isNull(field) ? StringUtils.EMPTY : field;
    }

    private int getQty(long days, int qty) {
        return qty < 0 ? (int) Math.floor((float) qty / days) : (int) Math.ceil((float) qty / days);
    }

    private ApiInventoryCheckPK mapToPkFromCheck(ApiInventoryCheck api) {
        return new ApiInventoryCheckPK(api.getDate()
                , api.getAdserverId()
                , api.getMetric()
                , api.getAdserverAdslotId()
                , api.getCity()
                , api.getState()
                , api.getEvent()
                , api.getPodPosition()
                , api.getVideoPosition());
    }
}


