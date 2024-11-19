package com.acn.dm.order.sync.action;

import com.acn.dm.order.config.SplitConfigs;
import com.acn.dm.order.domains.ApiReservedHistory;
import com.acn.dm.order.domains.pk.APIReservedHistoryPK;
import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.repository.APIReservedHistoryRepository;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import com.acn.dm.order.repository.ApiMoldDataRepository;
import com.acn.dm.order.repository.ApiMoldHistoryRepository;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.service.impl.CustomQueryService;
import com.acn.dm.order.sync.AbstractOrderSyncAction;
import jakarta.persistence.LockModeType;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class UpdateOnlyStatusAction extends AbstractOrderSyncAction {

    public UpdateOnlyStatusAction(APIReservedHistoryRepository histRepo, ApiInventoryCheckRepository checkRepo,
                                  SplitConfigs dateSplitter, ApiMoldDataRepository moldDataRepository, ApiMoldHistoryRepository moldHistoryRepository,
                                  CustomQueryService customQueryService) {
        super(histRepo, checkRepo, moldDataRepository, moldHistoryRepository, dateSplitter, customQueryService);
    }

    @Override
    protected OrderSyncActions canHandleAction() {
        return OrderSyncActions.NO_CHANGE_OF_QUANTITY;

    }

    @Override
    @Transactional(Transactional.TxType.MANDATORY)
    @Lock(LockModeType.OPTIMISTIC_FORCE_INCREMENT)
    public void handle(MarketOrderLineDetailsRequest request, Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList) throws Exception {
        logStartingProcess(request);
        Set<APIReservedHistoryPK> ids = getIds(splittedList, request.getMoldId());
        List<ApiReservedHistory> hisData = histRepo.findAllById(ids)
                .parallelStream()
                .map(item -> {
                    item.setStatus(request.getCurrentMoldStatus());
                    log.debug("Status change from {} to {}", request.getPreviousMoldStatus(), request.getCurrentMoldStatus());
                    return item;
                }).collect(Collectors.toList());

        if (!hisData.isEmpty()) {
            histRepo.saveAll(hisData);
        } else {
            log.warn("No data to save in reserve and inventory, handler - {}", canHandleAction());
            throw new Exception("No data to save in reserve and inventory, handler - " + canHandleAction());
        }
        logEndProcess(request);
    }

    @Override
    public void saveMoldHistoryFullyClash(MarketOrderLineDetailsRequest request) {
        log.info("NOT IMPLEMENTED - " + canHandleAction().toString());
    }

}


