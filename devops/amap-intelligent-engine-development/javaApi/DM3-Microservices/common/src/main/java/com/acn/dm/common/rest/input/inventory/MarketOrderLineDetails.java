package com.acn.dm.common.rest.input.inventory;

import static com.acn.dm.common.constants.SwaggerConstant.SWAGGER_DATE_EXAMPLE;
import static org.junit.Assert.assertNotNull;


import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;



import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class MarketOrderLineDetails implements  Serializable{

	/**
	 *
	 */
	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotBlank(message = "Market order line details Id's mandatory")
	private String moldId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String moldName;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String marketOrderId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String marketOrderName;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotNull(message = "Invalid Ordered Quantity")
	@Min(value = 1, message = "Ordered Quantity Must Be Greater Than 1")
	private Integer quantity ;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Integer videoDuration;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = SWAGGER_DATE_EXAMPLE)
	@NotNull(message = "Invalid Start Date")
	private LocalDate startDate;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = SWAGGER_DATE_EXAMPLE)
	@NotNull(message = "Invalid End Date")
	private LocalDate endDate;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotBlank(message = "Metric is mandatory")
	private String metric;

	@JsonIgnore
	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Integer frequencyCap;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(max = 1000)
	private String daypart;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String unit;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private String priority;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "Adserver details are mandatory")
	private List<@Valid AdServers> adserver ;

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
		assertNotNull("Invalid Start Date", startDate.toString());
		return startDate.isEqual(endDate);
	}

	@JsonIgnore
	@AssertTrue(message = "Dates should be current or greater")
	public boolean isDatesGreaterThanCurrent() {
		assertNotNull("Invalid start date", startDate.toString());
		assertNotNull("Invalid end date", endDate.toString());
		LocalDate current = LocalDate.now();
	    return (startDate.isEqual(current) || startDate.isAfter(current));

	}

}
