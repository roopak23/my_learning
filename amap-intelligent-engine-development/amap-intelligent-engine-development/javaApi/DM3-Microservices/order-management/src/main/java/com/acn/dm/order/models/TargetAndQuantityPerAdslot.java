package com.acn.dm.order.models;

import com.acn.dm.order.lov.CalcType;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TargetAndQuantityPerAdslot {

	private Long id;
	private String adserverId;
	private String adslotId;
	private String adslotName;
	private String city;
	private String state;
	private String event;
	private String audienceName;
	private String podPosition;
	private String videoPosition;
	private String overwriting;
	private String percentageOfOverwriting;
	private Integer overwrittenImpressions;
	private String overwritingReason;
	private String useOverwrite;
	private LocalDateTime overwrittenExpiryDate;
	private String updatedBy;

  private CalcType calcType;
	@Builder.Default
	private Integer quantity = 0;

	public void setQuantity(Integer quantity) {
		this.quantity = quantity;
	}


}
