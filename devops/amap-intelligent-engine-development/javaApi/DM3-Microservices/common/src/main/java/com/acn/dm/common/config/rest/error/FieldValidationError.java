package com.acn.dm.common.config.rest.error;

import java.util.Collection;

import com.fasterxml.jackson.annotation.JsonProperty;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FieldValidationError{

	@Schema(example = "Can't be null", requiredMode = Schema.RequiredMode.REQUIRED)
	private String message;

	@Schema(example = "fieldName", requiredMode = Schema.RequiredMode.REQUIRED)
	private String field;

	@JsonProperty("known")
	@Schema(defaultValue = "List of known/visible fields", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Collection<String> knownFields;

}
