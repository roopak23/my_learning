package com.acn.dm.order.rest.output;

import jakarta.validation.constraints.NotBlank;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;


import com.fasterxml.jackson.annotation.JsonIgnore;

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
public class OrderSyncResponse {
	
	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotBlank(message = "Missing market order line details Id")
	private String moldId;
	
	@Builder.Default
	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, defaultValue = "Managed By Action")
	private Set<String> managedBy = new HashSet<>();
	
	@JsonIgnore
	public OrderSyncResponse addAction(String action) {
		if(Objects.isNull(managedBy)) {
			managedBy = new HashSet<>();
		}
		managedBy.add(action);
		return this;
	}

}
