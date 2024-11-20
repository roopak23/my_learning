package com.acn.dm.order.steps.order.sync;

//import static org.junit.Assert.assertNotNull;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
//import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
//
//import java.io.IOException;
//
//import org.jose4j.lang.JoseException;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.http.MediaType;
//import org.springframework.test.web.servlet.MockMvc;
//
//import com.acn.dm.order.domains.ApiReservedHistory;
//import com.acn.dm.order.repository.APIReservedHistoryRepository;
//import com.acn.dm.testing.SpringIntegrationTestStepsBase;
//import com.github.tomakehurst.wiremock.client.WireMock;
//
//import io.cucumber.java.Before;
//import io.cucumber.java.Scenario;
//import io.cucumber.java.en.And;
//import io.cucumber.java.en.Given;
//import io.cucumber.java.en.Then;
//import io.cucumber.java.en.When;
//import lombok.extern.slf4j.Slf4j;

//@Slf4j
//public class OrderManagementTestsSteps extends SpringIntegrationTestStepsBase {
public class OrderManagementTestsSteps{
//	private final APIReservedHistoryRepository reservedRepo;
//
//	public OrderManagementTestsSteps(
//		MockMvc mock,
//		APIReservedHistoryRepository reservedRepo,
//		@Value("${wiremock.server.baseUrl}") String keycloakBaseUrl,
//		@Value("${keycloak.realm}") String keycloakRealm
//	) throws IOException, JoseException {
//		super(mock, keycloakBaseUrl, keycloakRealm);
//		this.reservedRepo = reservedRepo;
//	}
//
//	@Before
//	public void setScenario(Scenario scenario) {
//		super.setScenario(scenario);
//	}
//
//	private String inventoryManagementCheckSuccess(Integer available, Integer ordered) {
//		return String.format("[{"
//				+ "\"quantityAvailable\": %d,"
//				+ "\"quantityReserved\": %d,"
//				+ "\"uniqueIdentifier\": \"123\","
//				+ "\"businessId\": null,"
//				+ "\"transactionId\": \"123\""
//				+ "}]",available,ordered);
//	}
//
//	@When("^a synchronization event is sent$")
//	public void sendSyncEvent(String event) throws Throwable  {
//		assertNotNull("Invalid Event", event);
//		// @formatter:off
//		result = mockMvc
//			.perform(
//				put("/orders/sync")
//				.header(AUTHENTICATION_HEADER, getTokenForRequest())
//				.contentType(MediaType.APPLICATION_JSON)
//				.content(cleanJson(event))
//			)
//			.andDo(print(out));
//	  // @formatter:on
//	}
//
//	@When("In then inventory I have {int} elements and I order {int}")
//	public void whenInventoryManagementHas(Integer quantity , Integer ordered) {
//		WireMock.stubFor(WireMock.post(WireMock.urlEqualTo("/inventory-management/inventory/check"))
//				.willReturn(WireMock.aResponse().withHeader("Content-Type", "application/json").withBody(inventoryManagementCheckSuccess(quantity,ordered))));
//	}
//
//	@Given("an empty reservation table")
//	public void cleanTable() {
//		log.warn("Deleting all data in {} table", ApiReservedHistory.TABLE_NAME);
//		reservedRepo.deleteAllInBatch();
//	}
//
//	@Then("the status should be ok")
//	public void thenTheStatusShouldBeOk() throws Exception {
//		super.thenTheStatusShouldBeOk();
//	}
//
//	@Then("application raise internal server error")
//	public void applicationRaiseError() throws Exception {
//		super.applicationRaiseError();
//	}
//
//	@Then("application reject the request because it is invalid")
//	public void applicationRejectRequestError() throws Exception {
//		super.applicationRejectRequestError();
//	}
//
//	@And("the path {string} in the response must be {string}")
//	public void matchJsonPath(String path, String error) throws Exception {
//		super.matchJsonPath(path, error);
//	}
//
//	@And("the path {string} in the response must match the pattern {string}")
//	public void matchPatternJsonPath(String path, String pattern) throws Exception {
//		super.matchPatternJsonPath(path, pattern);
//	}
//
//	@And("the path {string} in the response contains at least {int} element")
//	public void atLeastLenght(String path, Integer size) {
//		super.atLeastLenght(path, size);
//	}
//
//	@And("the path {string} in the response contains {int} element")
//	public void matchLenght(String path, Integer size) {
//		super.matchLenght(path, size);
//	}

}