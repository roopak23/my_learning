package com.acn.dm.inventory.projection;

import java.io.Serializable;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 
 * Inquirity Projection
 * 
 * @author Shivani Chaudhary
 *
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AudienceProjection implements Serializable {

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private String audienceName;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private Long reach;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private Long impression;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private Double spend;
	
}