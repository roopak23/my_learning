package com.acn.dm.inventory.rest;

import static com.acn.dm.common.constants.SwaggerConstant.AUTHENTICATION_NAME;


import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.io.IOException;



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
import com.acn.dm.inventory.rest.input.AudienceSegmentRequest;
import com.acn.dm.inventory.rest.output.AudienceReachResponseWrapper;
import com.acn.dm.inventory.rest.output.AudienceReachResponse;
import com.acn.dm.inventory.service.AudienceService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * @author Shivani Chaudhary
 *
 */
@Validated
@RestController
@RequestMapping(AudienceResource.CONTROLLER_PATH)
@Tag(name = "Inventory Management")
public class AudienceResource {
	
	public static final String CONTROLLER_PATH  = "/audience";	

	@Autowired
	private AudienceService audienceService;

	@Operation(summary = "Audience Reach")
	@PostMapping("/reach")
	public ResponseEntity<AudienceReachResponseWrapper> inquirity(@NotNull(message = "Invalid request") @RequestBody  @Valid AudienceSegmentRequest request) throws IOException{
		return ResponseEntity.ok(audienceService.segmentList(request));
	}
	

}
