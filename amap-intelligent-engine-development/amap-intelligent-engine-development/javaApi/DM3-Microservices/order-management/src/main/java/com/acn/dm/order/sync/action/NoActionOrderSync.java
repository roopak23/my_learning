
package com.acn.dm.order.sync.action;

import com.acn.dm.order.repository.ApiMoldDataRepository;
import com.acn.dm.order.repository.ApiMoldHistoryRepository;
import com.acn.dm.order.service.impl.CustomQueryService;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Map;

import com.acn.dm.order.config.SplitConfigs;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.repository.APIReservedHistoryRepository;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.sync.AbstractOrderSyncAction;

/**
 * @author Shivani Chaudhary
 */

@Component
@Slf4j
public class NoActionOrderSync extends AbstractOrderSyncAction {

	/**
	 * @param repo
	 * @param dateSplitter
	 */
	public NoActionOrderSync(APIReservedHistoryRepository histRepo, ApiInventoryCheckRepository checkRepo,
							 SplitConfigs dateSplitter, ApiMoldDataRepository moldDataRepository, ApiMoldHistoryRepository moldHistoryRepository,
							 CustomQueryService customQueryService) {
		super(histRepo, checkRepo, moldDataRepository, moldHistoryRepository, dateSplitter, customQueryService);
	}

	@Override
	protected OrderSyncActions canHandleAction() {
		return OrderSyncActions.NO_ACTION;
	}

	@Override
	public void handle(MarketOrderLineDetailsRequest request, Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList) {
		logStartingProcess(request);
		logEndProcess(request);
	}

	@Override
	public void saveMoldHistoryFullyClash(MarketOrderLineDetailsRequest request) {
		log.info("NOT IMPLEMENTED - " + canHandleAction().toString());
	}
}
