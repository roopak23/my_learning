package com.acn.dm.inventory.rest;

import static com.acn.dm.common.constants.SwaggerConstant.AUTHENTICATION_NAME;


import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.io.IOException;
import java.util.List;



import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;
import com.acn.dm.common.utils.rest.output.error.ApiGenericError;
import com.acn.dm.common.utils.rest.output.success.ApiSuccess;
import com.acn.dm.inventory.rest.input.InventoryCheckRequest;
import com.acn.dm.inventory.rest.input.InventoryInquirityRequest;
import com.acn.dm.inventory.rest.output.InventoryCheckResponse;
import com.acn.dm.inventory.rest.output.InventoryInquirityResponse;
import com.acn.dm.inventory.service.InventoryService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * @author Shivani Chaudhary
 *
 */
@Validated
@RestController
@RequestMapping(InventoryResource.CONTROLLER_PATH)
@Tag(name = "Inventory Management")
public class InventoryResource {

	@Autowired
	private InventoryService inventoryService;

	public static final String CONTROLLER_PATH  = "/inventory";

	@PostMapping("/check")
	@Operation(summary = "Inventory check")
	public ResponseEntity<List<InventoryCheckResponse>> check(@NotNull(message = "Invalid request") @RequestBody @Valid InventoryCheckRequest request) throws IOException{
    return ResponseEntity.ok(inventoryService.checkList(request));
	}

	@Operation(summary = "Inventory Inquiry")
	@PostMapping("/inquirity")
	public ResponseEntity<List<InventoryInquirityResponse>> inquirity(@NotNull(message = "Invalid request") @RequestBody  @Valid InventoryInquirityRequest request) throws IOException{
		return ResponseEntity.ok(inventoryService.inquirityList(request));
	}


}
