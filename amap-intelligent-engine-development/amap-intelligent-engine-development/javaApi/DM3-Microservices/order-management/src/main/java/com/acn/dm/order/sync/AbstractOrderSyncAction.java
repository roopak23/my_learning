package com.acn.dm.order.sync;

import com.acn.dm.common.lov.InventoryCheckStatus;
import com.acn.dm.common.rest.input.inventory.AbstractInventoryCheckRequest;
import com.acn.dm.common.rest.input.inventory.MarketOrderLineDetails;
import com.acn.dm.common.rest.output.inventory.InventoryCheckResponse;
import com.acn.dm.order.config.SplitConfigs;
import com.acn.dm.order.domains.ApiInventoryCheck;
import com.acn.dm.order.domains.ApiMoldData;
import com.acn.dm.order.domains.ApiMoldHistory;
import com.acn.dm.order.domains.ApiReservedHistory;
import com.acn.dm.order.domains.pk.APIReservedHistoryPK;
import com.acn.dm.order.domains.pk.ApiInventoryCheckPK;
import com.acn.dm.order.domains.pk.ApiMoldDataPK;
import com.acn.dm.order.feign.InventoryManagementFeignClient;
import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.repository.APIReservedHistoryRepository;
import com.acn.dm.order.repository.ApiInventoryCheckRepository;
import com.acn.dm.order.repository.ApiMoldDataRepository;
import com.acn.dm.order.repository.ApiMoldHistoryRepository;
import com.acn.dm.order.rest.input.FrequencyCap;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.service.impl.CustomQueryService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.nimbusds.jose.shaded.gson.Gson;
import jakarta.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.NotImplementedException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;


import static com.acn.dm.common.utils.component.NormalizeCalc.normalizeQuantity;


/**
 * @author Shivani Chaudhary
 */
@Slf4j
@AllArgsConstructor
public abstract class AbstractOrderSyncAction implements OrderSyncAction {

  protected final APIReservedHistoryRepository histRepo;
  protected final ApiInventoryCheckRepository checkRepo;
  protected final ApiMoldDataRepository moldDataRepository;
  protected final ApiMoldHistoryRepository moldHistoryRepository;
  protected final CustomQueryService customQueryService;

  @Value("${application.normalization.qty.value:null}")
  private Integer normalizationQtyValue;

  @Autowired
  private InventoryManagementFeignClient inventory;
  @Autowired
  private AbstractInventoryCheckRequest checkRequest;


  public AbstractOrderSyncAction(APIReservedHistoryRepository histRepo, ApiInventoryCheckRepository checkRepo
          , ApiMoldDataRepository moldDataRepository, ApiMoldHistoryRepository moldHistoryRepository, SplitConfigs dateSplitter
          , CustomQueryService customQueryService) {
    super();
    this.histRepo = histRepo;
    this.checkRepo = checkRepo;
    this.moldDataRepository = moldDataRepository;
    this.moldHistoryRepository = moldHistoryRepository;
    this.customQueryService = customQueryService;
  }

  protected abstract OrderSyncActions canHandleAction();

  @Override
  public String getId() {
    return canHandleAction().toString();
  }

  @Override
  public boolean canHandle(OrderSyncActions request) {
    if (Objects.isNull(request)) {
      log.warn("Invalid null action");
      return false;
    }
    return request.equals(canHandleAction());
  }

  @Override
  public void handle(MarketOrderLineDetailsRequest request, Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList) throws Exception {
    throw new NotImplementedException("Method not implemented yet");
  }

  protected void logStartingProcess(MarketOrderLineDetailsRequest request) {
    log.info("Starting process {} for event", canHandleAction());
  }

  protected void logEndProcess(MarketOrderLineDetailsRequest request) {
    log.info("End process {} for event", canHandleAction());
  }

  @PostConstruct
  public void logInfo() {
    log.info("Register {} sync action for id {}", getClass(), getId());
  }

  @Transactional(readOnly = true)
  protected Map<APIReservedHistoryPK, ApiReservedHistory> mapById(Collection<APIReservedHistoryPK> ids) {
    // @formatter:off
    return histRepo.findAllById(ids)
      .parallelStream()
      .collect(
        Collectors.toMap(
          e -> e.getId(),
          e -> e,
          this::throwsDuplicateKey
        )
      );
    // @formatter:on

  }

  @Transactional(readOnly = true)
  protected Map<ApiInventoryCheckPK, ApiInventoryCheck> mapByIdForInventory(Collection<ApiInventoryCheckPK> checkIds) {
    // @formatter:off
    return customQueryService.findEntitiesByKey(checkIds)
      .parallelStream()
      .collect(
        Collectors.toMap(
          this::mapToPkFromCheck,
          e -> e,
          this::throwsDuplicateKeyCheck
        )
      );
    // @formatter:on

  }

  protected ApiReservedHistory throwsDuplicateKey(Object first, Object next) {
    throw new DuplicateKeyException("Duplicate ID " + first.toString());
  }

  protected ApiInventoryCheck throwsDuplicateKeyCheck(Object first, Object next) {
    throw new DuplicateKeyException("Duplicate ID " + first.toString());
  }

  protected Set<APIReservedHistoryPK> getIds(Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList, String moldId) {
    Set<APIReservedHistoryPK> apiPk = new HashSet<>();
    splittedList.entrySet().stream().forEach(entry -> {
      entry.getValue().stream().forEach(qAp -> {
        APIReservedHistoryPK api = new APIReservedHistoryPK();
        api.setDate(qAp.getDay());
        api.setAdserverAdslotId(qAp.getTargetPerSlots().getAdslotId());
        api.setEvent(qAp.getTargetPerSlots().getEvent());
        api.setCity(qAp.getTargetPerSlots().getCity());
        api.setState(qAp.getTargetPerSlots().getState());
        api.setMoldId(moldId);
        api.setPodPosition(qAp.getTargetPerSlots().getPodPosition());
        api.setVideoPosition(qAp.getTargetPerSlots().getVideoPosition());
        apiPk.add(api);
      });
    });

    return apiPk;
  }

  protected Set<ApiInventoryCheckPK> getIdsforInventoryCheck(Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList, String metric) {
      return splittedList.entrySet()
              .stream()
              .flatMap(entry -> entry.getValue().stream())
              .map(qAp -> mapToCheckPkFromQuantityAndPeriod(qAp, metric))
              .collect(Collectors.toCollection(HashSet::new));
  }

  protected ApiInventoryCheckPK mapToCheckPkFromQuantityAndPeriod(QuantityAndPeriod qAp, String metric) {
    return ApiInventoryCheckPK.builder()
            .adserverAdslotId(qAp.getTargetPerSlots().getAdslotId())
            .adserverId(qAp.getTargetPerSlots().getAdserverId())
            .date(qAp.getDay())
            .city(qAp.getTargetPerSlots().getCity())
            .state(qAp.getTargetPerSlots().getState())
            .event(qAp.getTargetPerSlots().getEvent())
            .videoPosition(qAp.getTargetPerSlots().getVideoPosition())
            .podPosition(qAp.getTargetPerSlots().getPodPosition())
            .metric(metric)
            .build();
  }

  protected APIReservedHistoryPK apiHistPKFromQuantityAndPeriod(QuantityAndPeriod qAp, MarketOrderLineDetailsRequest request) {
    APIReservedHistoryPK pk = new APIReservedHistoryPK();
    pk.setAdserverAdslotId(qAp.getTargetPerSlots().getAdslotId());
    pk.setEvent(qAp.getTargetPerSlots().getEvent());
    pk.setCity(qAp.getTargetPerSlots().getCity());
    pk.setState(qAp.getTargetPerSlots().getState());
    pk.setDate(qAp.getDay());
    pk.setMoldId(request.getMoldId());
    pk.setPodPosition(qAp.getTargetPerSlots().getPodPosition());
    pk.setVideoPosition(qAp.getTargetPerSlots().getVideoPosition());
    return pk;
  }

  protected List<ApiInventoryCheck> generateApiInventoryCheckFromReservedHistory(List<ApiReservedHistory> reservedHistories
          , Map<LocalDateTime, Collection<QuantityAndPeriod>> splittedList, String metric ) {
    Map<ApiInventoryCheckPK, ApiInventoryCheck> inventoryDBData
            = mapByIdForInventory(getIdsforInventoryCheck(splittedList, metric));

    return reservedHistories.stream()
            .map(hist -> {
              ApiInventoryCheckPK pk = mapToPkFromHistory(hist);
              return fromApiReservHistToInvCheck(hist, inventoryDBData.get(pk), hist.getQuantityBooked()
                      , hist.getQuantityReserved());
            })
            .toList();
  }

  protected ApiReservedHistory apiHistFromQuantityAndPeriod(QuantityAndPeriod qAp, MarketOrderLineDetailsRequest request
          , OrderSyncActions action) {
    ApiReservedHistory api = new ApiReservedHistory();
    api.setId(apiHistPKFromQuantityAndPeriod(qAp, request));
    api.setAdserverId(qAp.getTargetPerSlots().getAdserverId());
    api.setAdServerAdslotName(qAp.getTargetPerSlots().getAdslotName());
    api.setCalcType(qAp.getTargetPerSlots().getCalcType().getValue());
    api.setMoldName(request.getMoldName());
    api.setTechLineId(request.getTechLineId());
    api.setTechLineName(request.getTechLineName());
    api.setTechLineRemoteId(request.getTechLineRemoteId());
    api.setStartDate(request.getStartDate());
    api.setEndDate(request.getEndDate());
    api.setStatus(request.getCurrentMoldStatus());
    api.setMediaType(request.getMediaType());
    api.setCommercialAudience(request.getCommercialAudience());
    api.setUnitType(request.getMetric());
    api.setUnitPrice(request.getUnitPrice());
    api.setUnitNetPrice(request.getUnitNetPrice());
    api.setTotalPrice(request.getTotalPrice());
    api.setLength(request.getLength());
    api.setFormatId(request.getFormatId());
    api.setPriceItem(request.getPriceItem());
    api.setBreadcrumb(request.getBreadcrumb());
    api.setAdvertiserId(request.getAdvertiserId());
    api.setBrandName(request.getBrandName());
    api.setMarketOrderId(request.getMarketOrderId());
    api.setMarketOrderName(request.getMarketOrderName());
    api.setDaypart(request.getDaypart());
    api.setPriority(request.getPriority());
    api.setAdFormatId(request.getAdFormatId());
    api.setMarketProductTypeId(request.getMarketProductType());
    api.setVideoDuration(request.getVideoDuration());
    if(action.equals(OrderSyncActions.ADD_RESERVED) || action.equals(OrderSyncActions.UPDATE_RESERVED)) {
      api.setQuantityReserved(qAp.getTargetPerSlots().getQuantity());
    } else if(action.equals(OrderSyncActions.ADD_BOOKED) || action.equals(OrderSyncActions.UPDATE_BOOKED)
            || action.equals(OrderSyncActions.MOVE_FROM_RESERVED_TO_BOOKED)) {
      api.setQuantityReserved(0);
      api.setQuantityBooked(qAp.getTargetPerSlots().getQuantity());
    }
    api.setQuantity(qAp.getTargetPerSlots().getQuantity());
    return api;
  }



  protected ApiInventoryCheck fromApiReservHistToInvCheck(ApiReservedHistory hist, ApiInventoryCheck DBvalue, int booked, int reserved) {
    ApiInventoryCheck check = new ApiInventoryCheck();

    if (!Objects.isNull(DBvalue)) {
      check.setId(DBvalue.getId());
      check.setVersion(DBvalue.getVersion());
      check.setFutureCapacity(DBvalue.getFutureCapacity());
      check.setMissingForecast(DBvalue.getMissingForecast());
      check.setBooked(DBvalue.getBooked() + booked);
      check.setReserved(DBvalue.getReserved() + reserved);
      check.setMissingSegment(DBvalue.getMissingSegment());
      check.setOverwriting(DBvalue.getOverwriting());
      check.setOverwritingReason(DBvalue.getOverwritingReason());
      check.setOverwrittenImpressions(DBvalue.getOverwrittenImpressions());
      check.setUseOverwrite(DBvalue.getUseOverwrite());
      check.setPercentageOfOverwriting(DBvalue.getPercentageOfOverwriting());
      check.setDate(hist.getId().getDate());
      check.setAdserverAdslotId(hist.getId().getAdserverAdslotId());
      check.setAdServerAdslotName(DBvalue.getAdServerAdslotName());
      check.setMetric(hist.getUnitType());
      check.setAdserverId(hist.getAdserverId());
      check.setCity(hist.getId().getCity());
      check.setState(hist.getId().getState());
      check.setEvent(hist.getId().getEvent());
      check.setAudienceName(DBvalue.getAudienceName());
      check.setPodPosition(hist.getId().getPodPosition());
      check.setVideoPosition(hist.getId().getVideoPosition());
      check.setUpdatedBy(null);
      check.setOverwrittenExpiryDate(DBvalue.getOverwrittenExpiryDate());
    } else {
      check.setFutureCapacity(0);
      check.setMissingForecast("Y");
      check.setBooked(booked);
      check.setReserved(reserved);
      check.setMissingSegment("Y");
      check.setDate(hist.getId().getDate());
      check.setAdserverAdslotId(hist.getId().getAdserverAdslotId());
      check.setMetric(hist.getUnitType());
      check.setAdserverId(hist.getAdserverId());
      check.setCity(hist.getId().getCity());
      check.setState(hist.getId().getState());
      check.setEvent(hist.getId().getEvent());
      check.setPodPosition(hist.getId().getPodPosition());
      check.setVideoPosition(hist.getId().getVideoPosition());
    }
    return check;
  }

  protected ApiInventoryCheckPK mapToPkFromHistory(ApiReservedHistory api) {
    return new ApiInventoryCheckPK(api.getId().getDate()
            , api.getAdserverId()
            , api.getUnitType()
            , api.getId().getAdserverAdslotId()
            , api.getId().getCity()
            , api.getId().getState()
            , api.getId().getEvent()
            , api.getId().getPodPosition()
            , api.getId().getVideoPosition());
  }

  protected ApiInventoryCheckPK mapToPkFromCheck(ApiInventoryCheck api) {
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


  protected void checkInventoryAvailability(MarketOrderLineDetailsRequest request) throws Exception {
    if (!request.isOverbookingAllowed()) {

      log.error("marketRequest, {}", request);
      MarketOrderLineDetails mold = fromMoldRequestToMold(request);
      checkRequest.setLine(Collections.singletonList(mold));
      log.error(" OrderSync Request before calling mapper", checkRequest);

      try {
        ResponseEntity<List<InventoryCheckResponse>> res = inventory.check(checkRequest);

        if (res.getStatusCode() != HttpStatus.OK) {
          log.error("Inventory Management reply with non success response, {}", res);
          throw new Exception("Inventory Management reply with non success response");
        }
        if (res.getBody().isEmpty()) {
          log.error("Inventory Management reply with an empty response body, " + res.getBody());
          throw new Exception("Inventory Management reply with an empty response body");
        }
        InventoryCheckResponse checkResult = res.getBody().get(0);
        if (Objects.isNull(checkResult)) {
          log.error("Inventory Management reply with an null response , {}" + checkResult);
          throw new Exception("Inventory Management reply with an null response");
        }

        if (!(InventoryCheckStatus.OK.getStatus().equals(checkResult.getCheck()))) {
          log.error("Space not available, requested {} but available {}",
                  normalizeQuantity(checkRequest.getLine().get(0).getQuantity()
                          , request.getVideoDuration(), normalizationQtyValue), checkResult.getQuantityAvailable());
          throw new Exception("Space not available, requested "
                  + normalizeQuantity(checkRequest.getLine().get(0).getQuantity(), request.getVideoDuration(), normalizationQtyValue)
            + ", available " + checkResult.getQuantityAvailable());
        }
      } catch (Exception ex) {
        throw ex;
      }

    }

  }

  private MarketOrderLineDetails fromMoldRequestToMold(MarketOrderLineDetailsRequest request) {
    MarketOrderLineDetails mold = new MarketOrderLineDetails();
    mold.setMoldId(request.getMoldId());
    mold.setMoldName(request.getMoldName());
    mold.setAdserver(request.getAdserver());
    mold.setEndDate(request.getEndDate());
    mold.setStartDate(request.getStartDate());
    mold.setQuantity(request.getQuantity());
    mold.setMetric(request.getMetric());
    mold.setVideoDuration(request.getVideoDuration());
    return mold;
  }

  protected List<ApiMoldData> createMoldData(MarketOrderLineDetailsRequest request) {
    List<ApiMoldData> results = new ArrayList<>();
    if(Objects.nonNull(request.getFrequencyCap())) {
      results.add(createMoldDataFrequencyCap(request.getMoldId(), request.getFrequencyCap(), request.getMarketOrderId()));
    }
    results.addAll(createMoldDataLabels(request.getMoldId(), request.getAppliedLabels(), request.getMarketOrderId()));
    return results;
  }

  private ApiMoldData createMoldDataFrequencyCap(String moldId, List<FrequencyCap> frequencyCap, String marketOrderId) {
    Gson gson = new Gson();
    return new ApiMoldData(createMoldDataPk(moldId, "FREQUENCY_CAPPING", gson.toJson(frequencyCap)), marketOrderId);
  }

  private List<ApiMoldData> createMoldDataLabels(String moldId, List<String> labels, String marketOrderId) {
    if(Objects.isNull(labels)) {
      return List.of();
    }
    return labels.stream().map(label -> new ApiMoldData(createMoldDataPk(moldId, "LABEL", label), marketOrderId)).toList();
  }

  private ApiMoldDataPK createMoldDataPk(String moldId, String type, String value) {
    return new ApiMoldDataPK(moldId, type, value);
  }

  protected ApiMoldHistory createMoldHistory(MarketOrderLineDetailsRequest request, OrderSyncActions action) {
    int qty = normalizeQuantity(request.getQuantity(), request.getVideoDuration(), normalizationQtyValue);
    return ApiMoldHistory.builder()
            .moldId(request.getMoldId())
            .quantity(qty)
            .bookInd(OrderSyncActions.ADD_BOOKED.equals(action) ? "Y" : "N")
            .quantityBooked(OrderSyncActions.ADD_BOOKED.equals(action) ? qty : 0)
            .quantityReserved(OrderSyncActions.ADD_RESERVED.equals(action) ? qty : 0)
            .status(request.getCurrentMoldStatus())
            .build();
  }

  protected ApiMoldHistory updateMoldHistory(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request, OrderSyncActions action) {
    int qty = normalizeQuantity(request.getQuantity(), request.getVideoDuration(), normalizationQtyValue);
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantity(qty);
    moldHistory.setQuantityReserved(OrderSyncActions.UPDATE_RESERVED.equals(action) ? qty : 0);
    moldHistory.setQuantityBooked(OrderSyncActions.UPDATE_BOOKED.equals(action) ? qty : 0);
    return moldHistory;
  }

  protected ApiMoldHistory updateMoldHistoryReady(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantity(request.getQuantity() + moldHistory.getQuantityBooked());
    moldHistory.setQuantityReserved(request.getQuantity());
    return moldHistory;
  }

  protected ApiMoldHistory updateMoldHistoryReadyClash(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    return moldHistory;
  }

  protected ApiMoldHistory moveMoldHistoryReadyClash(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    return moldHistory;
  }

  protected ApiMoldHistory moveMoldHistory(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    int qty = normalizeQuantity(request.getQuantity(), request.getVideoDuration(), normalizationQtyValue);
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantity(qty);
    moldHistory.setQuantityReserved(0);
    moldHistory.setQuantityBooked(qty);
    moldHistory.setBookInd("Y");
    return moldHistory;
  }

  protected ApiMoldHistory moveMoldHistoryReady(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantity(moldHistory.getQuantityBooked() + request.getQuantity());
    moldHistory.setQuantityReserved(0);
    moldHistory.setQuantityBooked(moldHistory.getQuantityBooked() + request.getQuantity());
    moldHistory.setBookInd("Y");
    return moldHistory;
  }

  protected ApiMoldHistory removeMoldHistory(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    return moldHistory;
  }

  protected ApiMoldHistory removeReservedBookedMoldHistory(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantityBooked(0);
    moldHistory.setQuantityReserved(0);
    return moldHistory;
  }

  protected ApiMoldHistory removeReservedMoldHistory(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantityReserved(0);
    return moldHistory;
  }

  protected ApiMoldHistory removeBookedMoldHistory(ApiMoldHistory moldHistory, MarketOrderLineDetailsRequest request) {
    moldHistory.setStatus(request.getCurrentMoldStatus());
    moldHistory.setQuantityBooked(0);
    return moldHistory;
  }

  protected ApiMoldHistory decorateClashMoldHistory(ApiMoldHistory moldHistory) {
    moldHistory.setQuantityBooked(0);
    moldHistory.setQuantityReserved(0);
    moldHistory.setQuantity(0);
    return moldHistory;
  }

    protected ApiMoldHistory decorateClashMoldHistoryY(ApiMoldHistory moldHistory) {
      moldHistory.setQuantity(moldHistory.getQuantityBooked());
      moldHistory.setQuantityReserved(0);
      return moldHistory;
    }

  protected String mapToJson(Object object) {
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
  protected String generateStringKey(LocalDateTime date, String adserverId, String metric, String adserverAdslotId, String city, String state, String event, String podPosition, String videoPosition) {
    return (date.toString() + "|" + adserverId + "|" + metric + "|" + adserverAdslotId + "|" + city + "|" + state + "|" + event + "|" + podPosition + "|" + videoPosition).toUpperCase();
  }

  protected Map<String, ApiReservedHistory> createReservedMap(List<ApiReservedHistory> apiReservedHistory) {
    return apiReservedHistory.stream()
            .collect(Collectors.toMap(
                    key -> generateStringKey(key.getId().getDate(), key.getAdserverId(), key.getUnitType()
                            , key.getId().getAdserverAdslotId(), key.getId().getCity(), key.getId().getState()
                            , key.getId().getEvent(), key.getId().getPodPosition(), key.getId().getVideoPosition()),
                    value -> value
            ));
  }

  protected void decreaseInvReserved(List<ApiReservedHistory> apiReservedHistory, List<ApiInventoryCheck> apiInventoryCheck) {
    Map<String, ApiReservedHistory> reservedMap = createReservedMap(apiReservedHistory);
    apiInventoryCheck.forEach(inv -> {
      String invKey = generateStringKey(inv.getDate(), inv.getAdserverId(), inv.getMetric(), inv.getAdserverAdslotId()
              , inv.getCity(), inv.getState(), inv.getEvent(), inv.getPodPosition(), inv.getVideoPosition());
      ApiReservedHistory reservedResult = reservedMap.get(invKey);
      if(Objects.nonNull(reservedResult)) {
        inv.setReserved(inv.getReserved() - reservedResult.getQuantityReserved());
      }
    });
  }

  protected void decreaseInvBooked(List<ApiReservedHistory> apiReservedHistory, List<ApiInventoryCheck> apiInventoryCheck) {
    Map<String, ApiReservedHistory> reservedMap = createReservedMap(apiReservedHistory);
    apiInventoryCheck.forEach(inv -> {
      String invKey = generateStringKey(inv.getDate(), inv.getAdserverId(), inv.getMetric(), inv.getAdserverAdslotId()
              , inv.getCity(), inv.getState(), inv.getEvent(), inv.getPodPosition(), inv.getVideoPosition());
      ApiReservedHistory reservedResult = reservedMap.get(invKey);
      if(Objects.nonNull(reservedResult)) {
        inv.setBooked(inv.getBooked() - reservedResult.getQuantityBooked());
      }
    });
  }

  protected void decreaseInvReservedAndBooked(List<ApiReservedHistory> apiReservedHistory, List<ApiInventoryCheck> apiInventoryCheck) {
    Map<String, ApiReservedHistory> reservedMap = createReservedMap(apiReservedHistory);
    apiInventoryCheck.forEach(inv -> {
      String invKey = generateStringKey(inv.getDate(), inv.getAdserverId(), inv.getMetric(), inv.getAdserverAdslotId()
              , inv.getCity(), inv.getState(), inv.getEvent(), inv.getPodPosition(), inv.getVideoPosition());
      ApiReservedHistory reservedResult = reservedMap.get(invKey);
      if(Objects.nonNull(reservedResult)) {
        inv.setReserved(inv.getReserved() - reservedResult.getQuantityReserved());
        inv.setBooked(inv.getBooked() - reservedResult.getQuantityBooked());
      }
    });
  }

  protected void increaseInvReserved(List<ApiReservedHistory> apiReservedHistory, List<ApiInventoryCheck> apiInventoryCheck) {
    Map<String, ApiReservedHistory> reservedMap = createReservedMap(apiReservedHistory);
    apiInventoryCheck.forEach(inv -> {
      String invKey = generateStringKey(inv.getDate(), inv.getAdserverId(), inv.getMetric(), inv.getAdserverAdslotId()
              , inv.getCity(), inv.getState(), inv.getEvent(), inv.getPodPosition(), inv.getVideoPosition());
      ApiReservedHistory reservedResult = reservedMap.get(invKey);
      if(Objects.nonNull(reservedResult)) {
        inv.setReserved(inv.getReserved() + reservedResult.getQuantityReserved());
      }
    });
  }

  protected void increaseInvBooked(List<ApiReservedHistory> apiReservedHistory, List<ApiInventoryCheck> apiInventoryCheck) {
    Map<String, ApiReservedHistory> reservedMap = createReservedMap(apiReservedHistory);
    apiInventoryCheck.forEach(inv -> {
      String invKey = generateStringKey(inv.getDate(), inv.getAdserverId(), inv.getMetric(), inv.getAdserverAdslotId()
              , inv.getCity(), inv.getState(), inv.getEvent(), inv.getPodPosition(), inv.getVideoPosition());
      ApiReservedHistory reservedResult = reservedMap.get(invKey);
      if(Objects.nonNull(reservedResult)) {
        inv.setBooked(inv.getBooked() + reservedResult.getQuantityBooked());
      }
    });
  }
}
