package com.acn.dm.inventory;

//import static com.acn.dm.testing.SpringIntegrationTestStepsBase.CUCUMBER_JSON;
//import static com.acn.dm.testing.SpringIntegrationTestStepsBase.CUSTOM_CUCUMBER_REPORT_PLUGIN;
//import static com.acn.dm.testing.SpringIntegrationTestStepsBase.OUTPUT_PATH;
//import static com.acn.dm.testing.SpringIntegrationTestStepsBase.TEST_NOT_ANNOTATED_WITH_IGNORE;
//
//import org.junit.runner.RunWith;
//import org.keycloak.adapters.springboot.KeycloakSpringBootProperties;
//import org.springframework.boot.context.properties.EnableConfigurationProperties;
//import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
//import org.springframework.cloud.contract.wiremock.AutoConfigureWireMock;
//import org.springframework.test.context.TestPropertySource;
//
//import io.cucumber.junit.Cucumber;
//import io.cucumber.junit.CucumberOptions;
//import io.cucumber.spring.CucumberContextConfiguration;
//
//@AutoConfigureMockMvc
//@RunWith(Cucumber.class)
//@CucumberContextConfiguration
//@SpringBootTest(webEnvironment = WebEnvironment.MOCK)
//@AutoConfigureWireMock(port = 0) //, stubs = MOCK_FILE_LOCATION)
//@EnableConfigurationProperties(KeycloakSpringBootProperties.class)
//@TestPropertySource(locations = { "classpath:db.properties", "classpath:setting-test.properties" })
//@CucumberOptions(plugin = { "pretty", "json:" + OUTPUT_PATH + CUCUMBER_JSON , CUSTOM_CUCUMBER_REPORT_PLUGIN + ":Inventory Management"}, publish = false, tags = TEST_NOT_ANNOTATED_WITH_IGNORE)
public class InventoryManagementApplicationTest {}
