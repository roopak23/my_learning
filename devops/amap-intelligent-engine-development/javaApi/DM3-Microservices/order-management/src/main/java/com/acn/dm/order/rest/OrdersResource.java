package com.acn.dm.order.rest;


import jakarta.validation.Valid;
import java.util.List;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.acn.dm.order.rest.input.OrderSyncRequest;
import com.acn.dm.order.rest.output.OrderSyncResponse;
import com.acn.dm.order.service.OrdersService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.WebRequest;

/**
 * @author Shivani Chaudhary
 *
 */
@Validated
@RestController
@RequestMapping(OrdersResource.CONTROLLER_PATH)
@Tag(name = "Orders Management")
public class OrdersResource {

	@Autowired
	private OrdersService ordersService;

	public static final String CONTROLLER_PATH  = "/orders";

	@PutMapping("/sync")
	@Operation(summary = "")
	public ResponseEntity<List<OrderSyncResponse>> sync(@RequestBody @Valid OrderSyncRequest request, WebRequest webRequest) throws Exception{
		webRequest.setAttribute("request", request, RequestAttributes.SCOPE_REQUEST);
		return ResponseEntity.ok(ordersService.process(request));
	}

}
