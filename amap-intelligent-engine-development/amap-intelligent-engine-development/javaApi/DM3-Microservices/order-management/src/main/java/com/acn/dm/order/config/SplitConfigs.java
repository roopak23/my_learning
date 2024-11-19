package com.acn.dm.order.config;

import com.acn.dm.order.domains.ApiInventoryCheckNativeDTO;
import com.acn.dm.order.lov.CalcType;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.service.impl.InventoryServiceImpl;
import com.acn.dm.order.utils.calculators.TotalCapacityQtyCalc;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.Multimap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Component
public class SplitConfigs
  implements Converter<MarketOrderLineDetailsRequest, Multimap<LocalDateTime, QuantityAndPeriod>> {

  @Autowired
  InventoryServiceImpl inventoryService;
  @Autowired
  TotalCapacityQtyCalc totalCapacityQtyCalc;

  @Override
  public Multimap<LocalDateTime, QuantityAndPeriod> convert(MarketOrderLineDetailsRequest source) {

    Multimap<LocalDateTime, QuantityAndPeriod> map = ArrayListMultimap.create();

    log.info("before SplitConfigs query, mold - {}", source.getMoldId());
    List<ApiInventoryCheckNativeDTO> dto = inventoryService.takeValuesFromRepoById(source);
    log.info("after SplitConfigs query, mold - {}", source.getMoldId());
    Optional<LocalDateTime> lastForcastedDate = inventoryService.takeForecastFromRepoById(dto);
    boolean isAllClashPresent = inventoryService.isAllClash(dto);

    List<LocalDate> runningPeriod = inventoryService.generateDates(source.getStartDate(), source.getEndDate());
    int allDays = runningPeriod.size();
    if (!lastForcastedDate.isPresent() && !isAllClashPresent) {
      totalCapacityQtyCalc.calculate(source, allDays, CalcType.LINEAR).forEach(item -> map.put(item.getDay(), item));
    }

    if (lastForcastedDate.isPresent() && !isAllClashPresent) {
      LocalDate lastAvailableDate = lastForcastedDate.get().toLocalDate();

      if
        // running period is entirely included in forecast period
      (((source.getStartDate().isBefore(lastAvailableDate) ||
          source.getStartDate().isEqual(lastAvailableDate))
          &&
          (source.getEndDate().isBefore(lastAvailableDate)) ||
          source.getEndDate().isEqual(lastAvailableDate)) && !isAllClashPresent)  {
        totalCapacityQtyCalc.calculate(source, allDays, CalcType.WEIGHT).forEach(item -> map.put(item.getDay(), item));
        // running period is partially included in forecast period
      } else if
      (((source.getStartDate().isBefore(lastAvailableDate) || source.getStartDate().isEqual(lastAvailableDate)) &&
          source.getEndDate().isAfter(lastAvailableDate)) && !isAllClashPresent) {
        source.setEndDate(lastAvailableDate);
        totalCapacityQtyCalc.calculate(source, allDays, CalcType.WEIGHT).forEach(item -> map.put(item.getDay(), item));
        source.setStartDate(lastAvailableDate.plusDays(1));
        source.setEndDate(runningPeriod.stream().max(Comparator.comparing(LocalDate::toEpochDay))
          .get());
        totalCapacityQtyCalc.calculate(source, allDays, CalcType.LINEAR).forEach(item -> map.put(item.getDay(), item));
        source.setStartDate(runningPeriod.stream().min(Comparator.comparing(LocalDate::toEpochDay))
          .get());
      }
    } else if (isAllClashPresent){
      map.put(source.getStartDate().atStartOfDay(), QuantityAndPeriod.builder().clash(true).build());
    }


    if (log.isDebugEnabled()) {
      log.debug("After split:");
      map.entries().forEach(e -> log.debug("{} -> {}", e.getKey(), e.getValue()));
    }
    return map;
  }
}
