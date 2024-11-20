package com.acn.dm.order.rest.input;

import com.acn.dm.order.config.OrderProperties;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AdSlots {

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@Size(min = 1, max = OrderProperties.STRING_MAX_LIMIT)
	private String adslotRemoteId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String adslotName;

  @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  private boolean excludeChilds = true;

  public AdSlots(String adslotRemoteId) {
    this.adslotRemoteId = adslotRemoteId;
    this.adslotName = "";
  }
}
