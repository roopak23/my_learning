package com.acn.dm.order.sync.action;

import com.acn.dm.order.config.SplitConfigs;
import com.acn.dm.order.domains.ApiInventoryCheck;
import com.acn.dm.order.domains.ApiMoldData;
import com.acn.dm.order.domains.ApiReservedHistory;
import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.lov.QueueStatus;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.repository.APIReservedHistoryRepository;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import com.acn.dm.order.repository.ApiMoldDataRepository;
import com.acn.dm.order.repository.ApiMoldHistoryRepository;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.service.impl.CustomQueryService;
import com.acn.dm.order.service.impl.QueueService;
import com.acn.dm.order.sync.AbstractOrderSyncAction;
import jakarta.persistence.LockModeType;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.stereotype.Component;

/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Component
public class AddReservedSyncAction extends AbstractOrderSyncAction {


  private final QueueService queueService;

  public AddReservedSyncAction(APIReservedHistoryRepository histRepo, ApiInventoryCheckRepository checkRepo,
                               SplitConfigs dateSplitter, ApiMoldDataRepository moldDataRepository, ApiMoldHistoryRepository moldHistoryRepository,
                               CustomQueryService customQueryService, QueueService queueService) {
    super(histRepo, checkRepo, moldDataRepository, moldHistoryRepository, dateSplitter, customQueryService);
    this.queueService = queueService;
  }

  @Override
  protected OrderSyncActions canHandleAction() {
    return OrderSyncActions.ADD_RESERVED;
  }

  @Override
  @Transactional(Transactional.TxType.MANDATORY)
  @Lock(LockModeType.OPTIMISTIC_FORCE_INCREMENT)
  public void handle(MarketOrderLineDetailsRequest request, Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList) throws Exception {
    logStartingProcess(request);
    if (!request.isOverbookingAllowed()) {
      try {
        checkInventoryAvailability(request);
      } catch (Exception ex) {
        log.error("Inventory Management reply with non success response, {}", ex.getMessage());
        throw ex;
      }
    }

    List<ApiReservedHistory> currentlyReservedValues = splittedList.entrySet()
            .parallelStream()
            .flatMap(entry -> entry.getValue().stream())
            .map(qAp -> apiHistFromQuantityAndPeriod(qAp, request, OrderSyncActions.ADD_RESERVED))
            .toList();

    List<ApiInventoryCheck> currentlyInventoryCheckValues =
            generateApiInventoryCheckFromReservedHistory(currentlyReservedValues, splittedList, request.getMetric());

    if (!currentlyReservedValues.isEmpty() && !currentlyInventoryCheckValues.isEmpty()) {
      checkRepo.saveAll(currentlyInventoryCheckValues);
      histRepo.saveAll(currentlyReservedValues);
      moldHistoryRepository.save(createMoldHistory(request, OrderSyncActions.ADD_RESERVED));
      List<ApiMoldData> moldData = createMoldData(request);
      if (!moldData.isEmpty()) {
        moldDataRepository.saveAll(createMoldData(request));
      }
      queueService.selectAndSaveOrUpdateMessageQueue(request, mapToJson(request), QueueStatus.COMPLETED, canHandleAction(), null);
      queueService.selectAndSaveOrUpdateProcessState(request, QueueStatus.COMPLETED);
    } else {
      log.warn("No data to save in reserve and inventory, handler - {}", canHandleAction());
      throw new Exception("No data to save in reserve and inventory, handler - " + canHandleAction());
    }
    logEndProcess(request);
  }

  @Override
  @Transactional(Transactional.TxType.MANDATORY)
  public void saveMoldHistoryFullyClash(MarketOrderLineDetailsRequest request) {
    moldHistoryRepository.save(decorateClashMoldHistory(createMoldHistory(request, OrderSyncActions.ADD_RESERVED)));
  }

}
