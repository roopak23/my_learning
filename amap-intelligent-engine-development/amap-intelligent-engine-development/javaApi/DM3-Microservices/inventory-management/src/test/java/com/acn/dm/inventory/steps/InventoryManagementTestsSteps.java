package com.acn.dm.inventory.steps;

//import static org.junit.Assert.assertNotNull;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
//import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
//
//import java.io.IOException;
//
//import org.jose4j.lang.JoseException;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.http.MediaType;
//import org.springframework.test.web.servlet.MockMvc;
//
//import com.acn.dm.testing.SpringIntegrationTestStepsBase;
//
//import io.cucumber.java.Before;
//import io.cucumber.java.Scenario;
//import io.cucumber.java.en.And;
//import io.cucumber.java.en.Then;
//import io.cucumber.java.en.When;

//public class InventoryManagementTestsSteps extends SpringIntegrationTestStepsBase {
public class InventoryManagementTestsSteps{

//	public InventoryManagementTestsSteps(MockMvc mock, @Value("${wiremock.server.baseUrl}") String keycloakBaseUrl, @Value("${keycloak.realm}") String keycloakRealm)
//			throws IOException, JoseException {
//		super(mock, keycloakBaseUrl, keycloakRealm);
//	}
//
//	@Before
//	public void setScenario(Scenario scenario) {
//		super.setScenario(scenario);
//	}
//
//	@When("^check request is sent$")
//	public void whenACheckRequestIsSent(String event) throws Throwable {
//		assertNotNull("Invalid Event", event);
//		// @formatter:off
//		result = mockMvc
//			.perform(
//				post("/inventory/check")
//				.header(AUTHENTICATION_HEADER, getTokenForRequest())
//				.contentType(MediaType.APPLICATION_JSON)
//				.content(cleanJson(event))
//			)
//			.andDo(print(out))
//			;
//	    // @formatter:on
//	}
//
//	@When("^inquirity request is sent$")
//	public void whenAnInquirityRequestIsSent(String event) throws Throwable {
//		assertNotNull("Invalid Event", event);
//		// @formatter:off
//		result = mockMvc
//			.perform(
//				post("/inventory/inquirity")
//				.header(AUTHENTICATION_HEADER, getTokenForRequest())
//				.contentType(MediaType.APPLICATION_JSON)
//				.content(cleanJson(event))
//			)
//			.andDo(print(out));
//		// @formatter:on
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
