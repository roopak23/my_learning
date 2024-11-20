package com.acn.dm.inventory.rest.output;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.io.Serializable;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 *
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryCheckResponse implements Serializable {

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private String metric;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @JsonInclude(JsonInclude.Include.NON_EMPTY)
	private String moldId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String quantityAvailable;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String quantityReserved;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String quantityBooked;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String capacity;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private String check;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private String message;
}
