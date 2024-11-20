package com.acn.dm.order.service;

import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.rest.input.OrderSyncRequest;
import com.acn.dm.order.rest.output.OrderSyncResponse;
import java.util.List;

/**
 * @author Shivani Chaudhary
 */
public interface OrdersService {


    public void sync(MarketOrderLineDetailsRequest request) throws Exception;

    public OrderSyncResponse valid(MarketOrderLineDetailsRequest request) throws Exception;

    public List<OrderSyncResponse> validList(OrderSyncRequest request) throws Exception;

    public void syncList(OrderSyncRequest request) throws Exception;

    public List<OrderSyncResponse> process(OrderSyncRequest request) throws Exception;


}
