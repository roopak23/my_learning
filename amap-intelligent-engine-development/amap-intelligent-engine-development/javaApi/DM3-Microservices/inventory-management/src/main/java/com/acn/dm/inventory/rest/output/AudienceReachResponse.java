package com.acn.dm.inventory.rest.output;

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
public class AudienceReachResponse implements Serializable {

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String audienceName;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String reach ;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String impression ;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String spend ;
		
}

