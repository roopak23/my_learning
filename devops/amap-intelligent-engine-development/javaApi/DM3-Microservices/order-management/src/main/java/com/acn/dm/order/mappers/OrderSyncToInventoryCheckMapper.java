
package com.acn.dm.order.mappers;

import org.mapstruct.Mapper;

import com.acn.dm.common.rest.input.inventory.MarketOrderLineDetails;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import org.mapstruct.ReportingPolicy;

/**
 * @author Shivani Chaudhary
 *
 */
@Mapper(componentModel = "spring" , unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface OrderSyncToInventoryCheckMapper {

	/* @Mappings({@Mapping(target = "moldId", ignore = false) }) */
	public MarketOrderLineDetails toInventoryCheckRequest(MarketOrderLineDetailsRequest request);

}

