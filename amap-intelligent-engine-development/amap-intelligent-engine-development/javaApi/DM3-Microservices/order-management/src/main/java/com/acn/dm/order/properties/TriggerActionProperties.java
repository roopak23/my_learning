/**
 * 
 */
package com.acn.dm.order.properties;

import com.acn.dm.order.sync.AbstractOrderSyncAction;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Data;

/**
 * @author Shivani Chaudhary
 *
 */
@Data
public class TriggerActionProperties {

	@JsonProperty("from")
	private String fromStatus;
	
	@JsonProperty("to")
	private String toStatus;
	
	private Class<? extends AbstractOrderSyncAction> action;
	
}
