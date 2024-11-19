package com.acn.dm.common.rest.input.inventory;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.ArrayList;
import java.util.List;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Set;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AdServers {

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "Adserver Id is mandatory")
	private String adserverId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Set<AdSlots> adslot ;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private List<@Valid Target> targeting = new ArrayList<>() ;

  @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  private List<String> excludedAdSlot = new ArrayList<>();

}
