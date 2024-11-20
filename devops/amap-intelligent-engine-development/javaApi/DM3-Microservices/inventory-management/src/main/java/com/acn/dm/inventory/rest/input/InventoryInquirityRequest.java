package com.acn.dm.inventory.rest.input;

import static com.acn.dm.common.constants.SwaggerConstant.SWAGGER_DATE_EXAMPLE;
import static org.junit.Assert.assertNotNull;


import com.acn.dm.inventory.config.InventoryProperties;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;



import com.acn.dm.inventory.utils.Utils;
import com.fasterxml.jackson.annotation.JsonIgnore;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryInquirityRequest implements Serializable {

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "Adserver details are mandatory")
	private List<@Valid AdServers> adserver ;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = SWAGGER_DATE_EXAMPLE)
	@NotNull(message = "Invalid Start Date")
	private LocalDate startDate;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = SWAGGER_DATE_EXAMPLE)
	@NotNull(message = "Invalid End Date")
	private LocalDate endDate;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "Metric is mandatory")
	private List<String> metric;

	@JsonIgnore
	@AssertTrue(message = "Invalid date range")
	public boolean isValidDataRange() {
		if (Objects.isNull(startDate) || Objects.isNull(endDate)) {
			return false;
		}
		return startDate.isBefore(endDate) || isSameDate();
	}

	@JsonIgnore
	public boolean isSameDate() {
		if (Objects.isNull(startDate)) {
			return false;
		}
		return startDate.isEqual(endDate);
	}

	@JsonIgnore
	@AssertTrue(message = "Dates should be current or greater")
	public boolean isDatesGreaterThanCurrent() {
		assertNotNull("Invalid start date", startDate);
		assertNotNull("Invalid end date", endDate);
		LocalDate current = LocalDate.now();
 	    return (startDate.isEqual(current) || startDate.isAfter(current));
	}

	@JsonIgnore
	@AssertTrue(message = "Metric size it s not correct")
	public boolean isSizeCorrect() {
		assertNotNull("Metric is mandatory", metric);
		return metric.size() <= InventoryProperties.inventoryMetricLimit
				&& InventoryProperties.isCorrectLimitOfStrings(metric);
	}

	@JsonIgnore
	@AssertTrue(message = "AdServer size it s not correct")
	public boolean isCorrectSizeOfAdserver() {
		return adserver.size() <= InventoryProperties.inventoryAdServerLimit;
	}

	@JsonIgnore
	public LocalDateTime getStartDateAtStartOfDay() {
		return Utils.atStartOfDay(startDate);
	}

	@JsonIgnore
	public LocalDateTime getEndDateAtEndOfDay() {
		return Utils.atEndOfDay(endDate);
	}

}


