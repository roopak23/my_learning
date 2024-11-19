package com.acn.dm.order.rest.input;

import com.acn.dm.order.config.OrderProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import java.io.Serializable;
import java.util.List;

import org.springframework.stereotype.Component;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Component
@NoArgsConstructor
@AllArgsConstructor
public class OrderSyncRequest implements Serializable{

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	List<@Valid MarketOrderLineDetailsRequest> line ;

	@JsonIgnore
	@AssertTrue(message = "Line size it s not correct")
	public boolean isCorrectSizeOfLine() {
		return line.size() <= OrderProperties.orderLineLimit;
	}

}
