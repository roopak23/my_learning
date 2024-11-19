package com.acn.dm.common.utils.rest.output.error;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description ="Api Generic Error Body")
public class ApiGenericErrorBody {
	
	@Schema(defaultValue = "Error Message", requiredMode = Schema.RequiredMode.REQUIRED)
	private String error;
	
}