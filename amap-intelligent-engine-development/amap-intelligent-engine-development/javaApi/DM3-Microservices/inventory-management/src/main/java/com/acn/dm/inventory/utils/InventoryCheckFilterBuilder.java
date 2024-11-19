package com.acn.dm.inventory.utils;

import com.acn.dm.inventory.projection.CheckProjectionDTO;
import com.acn.dm.inventory.repository.ApiEventRepository;
import com.acn.dm.inventory.repository.ApiInventoryCheckRepository;
import com.acn.dm.inventory.rest.input.MarketOrderLineDetails;
import java.util.List;
import java.util.Map;

/**
 * @author Shivani Chaudhary
 */
public abstract class InventoryCheckFilterBuilder extends InventoryFilterBuilder {


    public static List<CheckProjectionDTO> buildAndExecCheckQuery(MarketOrderLineDetails request, ApiInventoryCheckRepository repository, ApiEventRepository apiEventRepository) {
        Map<String, List<String>> targets = mapTargetsFromRequest(request.getAdserver());
        filterEvents(targets, apiEventRepository);
        filterCountry(targets);

        return repository.getInventoryCheckQuery(request.getMetric()
                , mapAdSlotFromRequest(request.getAdserver(), repository)
                , mapExcludedAdSlotFromRequest(request.getAdserver())
                , request.getAppliedLabels()
                , request.getMoldId()
                , mapAdServerFromRequest(request.getAdserver())
                , getCities(targets)
                , getExcludedCity(targets)
                , getStates(targets)
                , getExcludedState(targets)
                , getEvents(targets)
                , getVideoPositions(targets)
                , getPodPositions(targets)
                , getAudience(targets)
                , request.getStartDate()
                , request.getEndDate()
                , mapFrequencyCapFromRequest(request.getFrequencyCap()));

    }

}
