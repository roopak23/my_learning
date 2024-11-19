package com.acn.dm.order.rest.input;

import com.acn.dm.order.config.OrderProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.ArrayList;
import java.util.List;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Objects;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AdServers {

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "AdserverId is mandatory")
	@Size(min = 1, max = OrderProperties.STRING_MAX_LIMIT)
	private String adserverId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private List<@Valid AdSlots> adslot ;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private List<@Valid Target> targeting ;

  @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  private List<@Size( max = OrderProperties.STRING_MAX_LIMIT) String> excludedAdSlot  = new ArrayList<>();;

	@JsonIgnore
	@AssertTrue(message = "Target size it s not correct")
	public boolean isCorrectSizeOfTargets() {
		return Objects.isNull(targeting) || targeting.size() <= OrderProperties.orderTargetLimit;
	}

	@JsonIgnore
	@AssertTrue(message = "Adslot size it s not correct")
	public boolean isCorrectSizeOfAdslots() {
		return Objects.isNull(adslot) || adslot.size() <= OrderProperties.orderAdSlotLimit;
	}
}
