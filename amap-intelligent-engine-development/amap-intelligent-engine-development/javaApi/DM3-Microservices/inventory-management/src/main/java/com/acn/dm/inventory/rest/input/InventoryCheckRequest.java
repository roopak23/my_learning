package com.acn.dm.inventory.rest.input;

import com.acn.dm.inventory.config.InventoryProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import java.io.Serializable;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 *
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryCheckRequest implements Serializable {

	private static final long serialVersionUID = 1L;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private List<@Valid MarketOrderLineDetails> line;

	@JsonIgnore
	@AssertTrue(message = "Line size it s not correct")
	public boolean isCorrectSizeOfLine() {
		return line.size() <= InventoryProperties.inventoryLineLimit;
	}
}
