package com.acn.dm.order.rest.input;

import static com.acn.dm.common.constants.SwaggerConstant.SWAGGER_DATE_EXAMPLE;
import static org.junit.Assert.assertNotNull;


import com.acn.dm.order.config.OrderProperties;
import com.fasterxml.jackson.annotation.JsonSetter;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

import com.acn.dm.common.rest.input.inventory.AdServers;
import com.acn.dm.order.utils.Utils;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class MarketOrderLineDetailsRequest implements Serializable, Cloneable {

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotBlank(message = "Missing Market Order Line Details ID")
	@Size(min = 1, max = OrderProperties.STRING_MAX_LIMIT)
	private String moldId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String moldName;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String marketOrderId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String marketOrderName;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String techLineId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String techLineName;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String techLineRemoteId;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = SWAGGER_DATE_EXAMPLE)
	@NotNull(message = "Invalid Start Date")
	private LocalDate startDate;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = SWAGGER_DATE_EXAMPLE)
	@NotNull(message = "Invalid End Date")
	private LocalDate endDate;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
//	@NotBlank(message = "Invalid Previous MOLD Status")
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String previousMoldStatus;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
//	@NotBlank(message = "Invalid Previous MOLD Status")
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String currentMoldStatus;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String catalogItem;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String breadcrumb;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String advertiserId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String formatId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Integer length ;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String brandName;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String priceItem;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Double unitPrice;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Double unitNetPrice;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Double totalPrice;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String mediaType;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String adFormatId;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String commercialAudience;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotNull(message = "Invalid Ordered Quantity")
	@Min(value = 1, message = "Ordered Quantity Must Be Greater Than 1")
	private Integer quantity;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Integer videoDuration;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private List<@Valid FrequencyCap> frequencyCap;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private List<@Valid String> appliedLabels;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(max = 1000)
	private String daypart;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String unit;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String priority;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String metric;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	@Size(min = 0, max = OrderProperties.STRING_MAX_LIMIT)
	private String marketProductType;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	@NotEmpty(message = "Adserver details are mandatory")
	private List<@Valid AdServers> adserver ;

	@JsonProperty("overbooking")
	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED, defaultValue = "Default true")
	private boolean overbookingAllowed = true;

	@Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
	private Long queueId;

	public void setQuantity(Integer quantity) {
		this.quantity = quantity;
	}

	@JsonSetter
	public void setQuantity(Double quantity) {
		if (quantity != null) {
			this.quantity = (int) Math.round(quantity);
		}
	}

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
		assertNotNull("Invalid Start Date", startDate);
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
	@AssertTrue(message = "AdServer size it s not correct")
	public boolean isCorrectSizeOfAdserver() {
		return adserver.size() <= OrderProperties.orderAdServerLimit;
	}

	@JsonIgnore
	public LocalDateTime getStartDateAtStartOfDay() {
		return Utils.atStartOfDay(startDate);
	}

	@JsonIgnore
	public LocalDateTime getEndDateAtEndOfDay() {
		return Utils.atEndOfDay(endDate);
	}

	// TODO should be an object
	@Override
	public MarketOrderLineDetailsRequest clone() {
		try {
			return (MarketOrderLineDetailsRequest) super.clone();
		} catch (CloneNotSupportedException e) {
			return null;
		}
	}
}
