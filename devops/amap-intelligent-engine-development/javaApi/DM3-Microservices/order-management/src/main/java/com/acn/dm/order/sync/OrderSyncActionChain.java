package com.acn.dm.order.sync;

import com.acn.dm.common.rest.input.inventory.AdSlots;
import com.acn.dm.order.config.SplitConfigs;
import com.acn.dm.order.domains.ApiMoldHistory;
import com.acn.dm.order.domains.ApiStatusChangeAction;
import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.lov.QueueStatus;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.repository.APIReservedHistoryRepository;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import com.acn.dm.order.repository.ApiMoldHistoryRepository;
import com.acn.dm.order.repository.ApiStatusChangeActionRepository;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.rest.input.OrderSyncRequest;
import com.acn.dm.order.service.impl.QueueService;
import com.acn.dm.order.sync.action.NoActionOrderSync;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.google.common.collect.Multimap;
import com.google.common.collect.Multimaps;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;


import static com.acn.dm.common.utils.component.NormalizeCalc.normalizeQuantity;

/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Component
public class OrderSyncActionChain {

    private List<OrderSyncAction> chain;
    private APIReservedHistoryRepository repo;
    private ApiStatusChangeActionRepository statusRepo;
    private ApiMoldHistoryRepository moldHistoryRepository;
    private ApiInventoryCheckRepository inventoryCheckRepository;
    private NoActionOrderSync action;
    private SplitConfigs dateSplitter;
    private QueueService queueService;

    @Value("${application.normalization.qty.value:null}")
    private Integer normalizationQtyValue;

    public OrderSyncActionChain(List<OrderSyncAction> chain, APIReservedHistoryRepository repo, ApiStatusChangeActionRepository statusRepo, ApiMoldHistoryRepository moldHistoryRepository, ApiInventoryCheckRepository inventoryCheckRepository, NoActionOrderSync action, SplitConfigs dateSplitter, QueueService queueService) {
        this.chain = chain;
        this.repo = repo;
        this.statusRepo = statusRepo;
        this.moldHistoryRepository = moldHistoryRepository;
        this.inventoryCheckRepository = inventoryCheckRepository;
        this.action = action;
        this.dateSplitter = dateSplitter;
        this.queueService = queueService;
    }

    public Set<String> process(MarketOrderLineDetailsRequest request) throws Exception {
        Optional<ApiMoldHistory> apiMoldHistory = alignQuantityAndReturnFlagWithStatus(request);
        String fromStatus = apiMoldHistory.map(ApiMoldHistory::getStatus).orElse("NA");
        String toStatus = request.getCurrentMoldStatus();

        List<OrderSyncActions> actionIDs = statusRepo.findActionMappedByStatus(fromStatus
                        , toStatus, apiMoldHistory.map(ApiMoldHistory::getBookInd).orElse(null))
                .stream()
                .map(status -> Enum.valueOf(OrderSyncActions.class, status))
                .toList();

        Set<String> handledBy = new HashSet<>();

        if (actionIDs.isEmpty()) {
            log.info("Event rejected {}", request);
            handledBy.add("NONE");
            String json = mapToJson(new OrderSyncRequest(List.of(request)));
            queueService.selectAndSaveOrUpdateMessageQueue(request, json, QueueStatus.COMPLETED, OrderSyncActions.NONE, null);
            queueService.selectAndSaveOrUpdateProcessState(request, QueueStatus.COMPLETED);
        } else {
            handleExcludeChildren(request);
            Multimap<LocalDateTime, QuantityAndPeriod> splitted = dateSplitter.convert(request);
            if (splitted.size() == 1 && splitted.get(request.getStartDate().atStartOfDay()).stream().allMatch(val -> Boolean.TRUE.equals(val.getClash()))) {
                chain.parallelStream()
                        .filter(e -> e.canHandle(actionIDs.get(0)))
                        .findFirst()
                        .ifPresent(handler -> handler.saveMoldHistoryFullyClash(request));
                queueService.selectAndSaveOrUpdateMessageQueue(request, mapToJson(new OrderSyncRequest(List.of(request)))
                        , QueueStatus.COMPLETED, actionIDs.get(0), "FULLY CLASH");
                queueService.selectAndSaveOrUpdateProcessState(request, QueueStatus.COMPLETED);
            } else {
                Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList = Multimaps.asMap(splitted);
                for (OrderSyncActions actionID : actionIDs) {
                    Optional<OrderSyncAction> command = chain
                            .parallelStream()
                            .filter(e -> e.canHandle(actionID))
                            .findFirst();
                    if (command.isPresent()) {
                        OrderSyncAction handler = command.get();
                        String actionName = handler.getClass().getName();
                        log.info("Processing request with action {}", actionName);
                        handledBy.add(handler.getId() + clashMessage(splittedList));
                        handler.handle(request, splittedList);
                    } else {
                        log.warn("There is no action for {} to handle {}", actionID, request);
                    }
                }
            }
        }
        return handledBy;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public Set<String> validProcess(MarketOrderLineDetailsRequest request) throws Exception {
        Optional<String> previousMoldStatus = queueService.findPreviousMoldStatus(request.getMoldId(), request.getMarketOrderId());
        String fromStatus = previousMoldStatus.orElse("NA");
        String toStatus = request.getCurrentMoldStatus();
        List<ApiStatusChangeAction> statusBeforeValid = statusRepo.findActionMappedByStatusForValid(fromStatus, toStatus, null);
        if (statusBeforeValid.size() > 1) {
            statusBeforeValid = statusBeforeValid
                    .stream()
                    .filter(value -> "N".equalsIgnoreCase(value.getApiStatusChangeActionPK().getBookInd()))
                    .toList();
        }
        List<OrderSyncActions> actionIDs = statusBeforeValid
                .stream()
                .map(ApiStatusChangeAction::getActionMapped)
                .map(status -> Enum.valueOf(OrderSyncActions.class, status))
                .toList();


        String json = mapToJson(new OrderSyncRequest(List.of(request)));

        Set<String> handledBy = new HashSet<>();
        if (actionIDs.isEmpty()) {
            log.info("Event rejected {}", request);
            queueService.selectAndSaveOrUpdateMessageQueue(request, json, QueueStatus.NEW, OrderSyncActions.NONE, null);
            queueService.selectAndSaveOrUpdateProcessState(request, QueueStatus.NEW);
            handledBy.add("NONE");
        } else {
            queueService.selectAndSaveOrUpdateMessageQueue(request, json, QueueStatus.NEW, actionIDs.get(0), null);
            queueService.selectAndSaveOrUpdateProcessState(request, QueueStatus.NEW);
            for (OrderSyncActions actionID : actionIDs) {
                Optional<OrderSyncAction> command = chain
                        .parallelStream()
                        .filter(e -> e.canHandle(actionID))
                        .findFirst();
                if (command.isPresent()) {
                    OrderSyncAction handler = command.get();
                    String actionName = handler.getClass().getName();
                    log.info("Processing request with action {}", actionName);
                    handledBy.add(handler.getId());
                }
            }

        }
        return handledBy;
    }

    private String clashMessage(Map<LocalDateTime, Collection<QuantityAndPeriod>> map) {
        List<Boolean> booleans = map.values().stream().flatMap(Collection::stream).map(QuantityAndPeriod::getClash).toList();
        if (booleans.stream().allMatch(Boolean.TRUE::equals)) {
            return (" (FULLY CLASH)");
        } else if (booleans.contains(Boolean.TRUE)) {
            return (" (PARTIAL CLASH)");
        }
        return StringUtils.EMPTY;
    }

    private MarketOrderLineDetailsRequest handleExcludeChildren(MarketOrderLineDetailsRequest request) throws ResponseStatusException {

        if (!request.getAdserver().isEmpty()) {

            request.getAdserver().forEach(adServer -> {
                Set<AdSlots> adslotsList = new HashSet<>();
                // get adSlots id and its children's id if flag set true
                adServer.getAdslot().forEach(adSlot -> {

                    if (!adSlot.isExcludeChilds())
                        inventoryCheckRepository.findAllChildAdSlots(adSlot.getAdslotRemoteId(), adServer.getAdserverId())
                                .forEach(childAdslot -> {
                                    if (!childAdslot.getAdserver_adslot_id().isEmpty() && !adServer.getExcludedAdSlot().contains(childAdslot.getAdserver_adslot_id()))
                                        adslotsList.add(new AdSlots(childAdslot.getAdserver_adslot_id()));
                                });

                    if (!adServer.getExcludedAdSlot().contains(adSlot.getAdslotRemoteId()))
                        adslotsList.add(new AdSlots(adSlot.getAdslotRemoteId(), adSlot.getAdslotName()));
                });
                // after exclusion there should be at least one adSlot in list
                if (adslotsList.isEmpty()) {
                    log.error("AdSlot list empty after exclusion process");
                    throw new ResponseStatusException(
                            HttpStatus.BAD_REQUEST, "AdSlot list empty after exclusion process");
                }
                adServer.setAdslot(adslotsList);
            });
        }
        return request;

    }

    private Optional<ApiMoldHistory> alignQuantityAndReturnFlagWithStatus(MarketOrderLineDetailsRequest request) {
        Optional<ApiMoldHistory> moldHistResult = moldHistoryRepository.findById(request.getMoldId());

        moldHistResult.filter(this::isScenarioToDecrease)
                .stream()
                .findFirst()
                .map(moldHist -> normalizeQuantity(request.getQuantity(), request.getVideoDuration(), normalizationQtyValue)
                        - moldHist.getQuantityBooked())
                .ifPresent(qty -> updateRequest(qty, request));

        return moldHistResult;

    }

    private boolean isScenarioToDecrease(ApiMoldHistory apiMoldHistory) {
        return "Y".equalsIgnoreCase(apiMoldHistory.getBookInd());
    }

    private void updateRequest(Long qty, MarketOrderLineDetailsRequest request) {
        request.setQuantity(Math.toIntExact(qty));
    }

    private String mapToJson(Object object) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            mapper.registerModule(new JavaTimeModule());
            mapper.findAndRegisterModules();
            return mapper.writeValueAsString(object);
        } catch (Exception e) {
            log.error("Error mapping to json", e);
            return object.toString();
        }
    }
}
