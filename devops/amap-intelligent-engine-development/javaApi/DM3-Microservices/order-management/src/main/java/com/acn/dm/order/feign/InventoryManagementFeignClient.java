package com.acn.dm.order.feign;

import java.util.List;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import com.acn.dm.common.rest.input.inventory.AbstractInventoryCheckRequest;
import com.acn.dm.common.rest.output.inventory.InventoryCheckResponse;
import com.acn.dm.feign.commons.config.OpenFeignConfiguration;

import feign.Headers;

@Headers("Content-Type: application/json")
@FeignClient(
	name = "inv-mng",
	url = "${application.feign.inventoryManagement.baseUrl}",
	configuration = OpenFeignConfiguration.class
)
public interface InventoryManagementFeignClient {

	@PostMapping(value="/inventory/check")
	ResponseEntity<List<InventoryCheckResponse>> check(@RequestBody AbstractInventoryCheckRequest request);

}
