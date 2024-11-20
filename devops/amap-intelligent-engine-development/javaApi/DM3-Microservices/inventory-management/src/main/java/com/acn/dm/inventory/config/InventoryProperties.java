package com.acn.dm.inventory.config;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class InventoryProperties {

    public static final int STRING_MAX_LIMIT = 255;

    public static int inventoryMetricLimit;
    public static int inventoryTargetLimit;
    public static int inventoryAdServerLimit;
    public static int inventoryAdSlotLimit;
    public static int inventoryLineLimit;
    public static int audienceMetricLimit;
    public static int audienceNameLimit;
    public static int audienceAdServerLimit;

    public InventoryProperties(@Value("${api.inventory.line-limit}") int inventoryLineLimit, @Value("${api.inventory.target-limit}") int inventoryTargetLimit,
                               @Value("${api.inventory.adserver-limit}") int inventoryAdServerLimit, @Value("${api.inventory.adslot-limit}") int inventoryAdSlotLimit,
                               @Value("${api.inventory.metric-limit}") int inventoryMetricLimit, @Value("${api.audience.metric-limit}") int audienceMetricLimit,
                               @Value("${api.audience.name-limit}") int audienceNameLimit, @Value("${api.audience.adserver-limit}") int audienceAdServerLimit) {

        InventoryProperties.inventoryMetricLimit = inventoryMetricLimit;
        InventoryProperties.inventoryTargetLimit = inventoryTargetLimit;
        InventoryProperties.inventoryAdServerLimit = inventoryAdServerLimit;
        InventoryProperties.inventoryAdSlotLimit = inventoryAdSlotLimit;
        InventoryProperties.inventoryLineLimit = inventoryLineLimit;
        InventoryProperties.audienceMetricLimit = audienceMetricLimit;
        InventoryProperties.audienceNameLimit = audienceNameLimit;
        InventoryProperties.audienceAdServerLimit = audienceAdServerLimit;
    }

    public static boolean isCorrectLimitOfStrings(List<String> list) {
        return list.stream().noneMatch(value -> value.length() > STRING_MAX_LIMIT);
    }
}
