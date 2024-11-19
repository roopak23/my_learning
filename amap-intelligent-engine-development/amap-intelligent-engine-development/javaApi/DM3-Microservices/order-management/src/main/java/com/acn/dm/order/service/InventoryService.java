package com.acn.dm.order.service;

import com.acn.dm.order.domains.ApiInventoryCheckNativeDTO;
import com.acn.dm.order.domains.pk.ApiInventoryCheckPK;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

public interface InventoryService {

  public List<ApiInventoryCheckNativeDTO> takeValuesFromRepoById(MarketOrderLineDetailsRequest request);

  public Optional<LocalDateTime> takeForecastFromRepoById(List<ApiInventoryCheckNativeDTO> request);

  public Map<ApiInventoryCheckPK, Integer> takeDailyCapacityPerTargetRemoteId(List<ApiInventoryCheckNativeDTO> list);

  public Map<ApiInventoryCheckPK, Integer> takeDailyCapacityPerAdSlot(List<ApiInventoryCheckNativeDTO> list);

  public List<ApiInventoryCheckPK> takeOutOfForecastValues(MarketOrderLineDetailsRequest request);

}
