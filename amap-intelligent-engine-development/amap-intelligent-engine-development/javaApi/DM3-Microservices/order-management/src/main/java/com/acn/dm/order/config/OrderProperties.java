package com.acn.dm.order.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class OrderProperties {

    public static final int STRING_MAX_LIMIT = 255;

    public static int orderLineLimit;
    public static int orderTargetLimit;
    public static int orderAdServerLimit;
    public static int orderAdSlotLimit;

    public OrderProperties(@Value("${api.order.line-limit}") int orderLineLimit, @Value("${api.order.target-limit}") int orderTargetLimit,
                           @Value("${api.order.adserver-limit}") int orderAdServerLimit, @Value("${api.order.adslot-limit}") int orderAdSlotLimit) {

        OrderProperties.orderLineLimit = orderLineLimit;
        OrderProperties.orderTargetLimit = orderTargetLimit;
        OrderProperties.orderAdServerLimit = orderAdServerLimit;
        OrderProperties.orderAdSlotLimit = orderAdSlotLimit;
    }
}
