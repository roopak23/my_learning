package com.acn.dm.inventory.rest.input;

import com.acn.dm.inventory.config.InventoryProperties;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Value;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AdSlots {

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@Size(min = 1, max = InventoryProperties.STRING_MAX_LIMIT)
	private String adslotRemoteId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
	private String adslotName;

  	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  	private boolean excludeChilds = false;

}
