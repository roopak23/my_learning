package com.acn.dm.order.utils.calculators;

import com.acn.dm.order.lov.CalcType;
import com.acn.dm.order.models.QuantityAndPeriod;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;

import java.util.List;

public interface QtyCalc {

  public List<QuantityAndPeriod> calculate(MarketOrderLineDetailsRequest request, long dailyQuantity, CalcType calcType);
  //public List<QuantityAndPeriod> calculate(MarketOrderLineDetailsRequest request);
}
