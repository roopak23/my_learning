package com.acn.dm.inventory.utils;

import com.acn.dm.inventory.projection.InquirityProjectionDTO;
import com.acn.dm.inventory.repository.ApiEventRepository;
import com.acn.dm.inventory.repository.ApiInventoryCheckRepository;
import com.acn.dm.inventory.rest.input.InventoryInquirityRequest;
import java.util.List;
import java.util.Map;

/**
 * @author Shivani Chaudhary
 */
public abstract class InventoryInquirityFilterBuilder extends InventoryFilterBuilder {

    public static List<InquirityProjectionDTO> buildAndExecInquirityQuery(InventoryInquirityRequest request, ApiInventoryCheckRepository repository, ApiEventRepository apiEventRepository) {
        Map<String, List<String>> targets = mapTargetsFromRequest(request.getAdserver());
        filterEvents(targets, apiEventRepository);
        filterCountry(targets);

        return repository.getInventoryInqiurityQuery(request.getMetric()
                , mapAdSlotFromRequest(request.getAdserver(), repository)
                , mapExcludedAdSlotFromRequest(request.getAdserver())
                , mapAdServerFromRequest(request.getAdserver())
                , getCities(targets)
                , getStates(targets)
                , getEvents(targets)
                , getAudience(targets)
                , request.getStartDate()
                , request.getEndDate());


    }


}
