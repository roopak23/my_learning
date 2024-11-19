package com.acn.dm.inventory.rest.input;

import com.acn.dm.inventory.config.InventoryProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotEmpty;
import java.io.Serializable;
import java.util.List;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Objects;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


import static org.junit.Assert.assertNotNull;

/**
 * @author Shivani Chaudhary
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AudienceSegmentRequest implements Serializable {

	private static final long serialVersionUID = 1L;
	
	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "At least one audience name is required")
	private List<String> audienceName ;
	
	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "At least one metric is mandatory")
	private List<String> metric;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private List<String> adserverId;


	@JsonIgnore
	@AssertTrue(message = "Audience Name size it s not correct")
	public boolean isCorrectSizeOfAudienceName() {
		assertNotNull("Audience Name is mandatory", audienceName);
		return audienceName.size() <= InventoryProperties.audienceNameLimit
				&& InventoryProperties.isCorrectLimitOfStrings(audienceName);
	}

	@JsonIgnore
	@AssertTrue(message = "Metric size it s not correct")
	public boolean isCorrectSizeOfMetric() {
		assertNotNull("Metric is mandatory", metric);
		return metric.size() <= InventoryProperties.audienceMetricLimit
				&& InventoryProperties.isCorrectLimitOfStrings(metric);
	}

	@JsonIgnore
	@AssertTrue(message = "AdServer size it s not correct")
	public boolean isCorrectSizeOfAdserverId() {
		return Objects.isNull(adserverId) || (adserverId.size() <= InventoryProperties.audienceAdServerLimit
				&& InventoryProperties.isCorrectLimitOfStrings(adserverId));
	}
}


