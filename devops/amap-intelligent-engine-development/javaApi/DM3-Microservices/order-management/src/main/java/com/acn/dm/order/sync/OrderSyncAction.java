package com.acn.dm.order.sync;

import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Map;

/**
 * @author Shivani Chaudhary
 */
public interface OrderSyncAction {

	public void handle(MarketOrderLineDetailsRequest request, Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList) throws Exception;
	public boolean canHandle(OrderSyncActions request);
	public String getId();
	public void saveMoldHistoryFullyClash(MarketOrderLineDetailsRequest request);

}
