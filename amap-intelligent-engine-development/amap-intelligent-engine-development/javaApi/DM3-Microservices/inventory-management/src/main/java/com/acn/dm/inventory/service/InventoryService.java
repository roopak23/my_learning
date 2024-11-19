package com.acn.dm.inventory.service;

import java.util.List;
import java.util.stream.Collectors;


import com.acn.dm.inventory.rest.input.InventoryCheckRequest;
import com.acn.dm.inventory.rest.input.InventoryInquirityRequest;
import com.acn.dm.inventory.rest.input.MarketOrderLineDetails;
import com.acn.dm.inventory.rest.output.InventoryCheckResponse;
import com.acn.dm.inventory.rest.output.InventoryInquirityResponse;

/**
 * @author Shivani Chaudhary
 *
 */
public interface InventoryService {
	
	public List<InventoryInquirityResponse> inquirity(InventoryInquirityRequest request);
	public InventoryCheckResponse check(MarketOrderLineDetails request);
	
	default public List<InventoryInquirityResponse> inquirityList(InventoryInquirityRequest request){
		return inquirity(request);
	}
	
	default public List<InventoryCheckResponse> checkList(InventoryCheckRequest request){
		return request.getLine().parallelStream().map(this::check).collect(Collectors.toList());
	}
}
