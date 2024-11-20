package com.acn.dm.testing;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.StringWriter;
import java.util.Objects;

import org.apache.logging.log4j.util.Strings;
import org.jose4j.lang.JoseException;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import com.acn.dm.testing.config.KeycloakTestConfiguration;
import com.acn.dm.testing.matcher.ResponsePatternMatch;
import com.acn.dm.testing.utilities.CleanJson;
import com.jayway.jsonpath.JsonPath;

import io.cucumber.java.Scenario;
import lombok.extern.slf4j.Slf4j;
import net.minidev.json.JSONArray;

/**
 * @author Alberto Riminucci
 */
@Slf4j
public class SpringIntegrationTestStepsBase extends KeycloakTestConfiguration {

	public static final String CUSTOM_CUCUMBER_REPORT_PLUGIN = "com.acn.dm.testing.cucumber.reporting.CustomCucumberReporterPlugin";
	private static final String ReourceFileWhereRequestWillBeLoggedByDefault = "resource.txt";
	public static final String TEST_NOT_ANNOTATED_WITH_IGNORE = "not @ignore";
	public static final String MAVEN_TARGET_FOLDER = "./target";
	public static final String OUTPUT_PATH = MAVEN_TARGET_FOLDER + "/surefire-reports/";
	public static final String CUCUMBER_JSON = "cucumber.json";
	protected ResultActions result;
	protected final OutputStream out;

	private Scenario scenario;
	protected final MockMvc mockMvc;
	
	public SpringIntegrationTestStepsBase(MockMvc mockMvc, String keycloakBaseUrl, String keycloakRealm) throws IOException, JoseException {
		this(mockMvc, keycloakBaseUrl, keycloakRealm, ReourceFileWhereRequestWillBeLoggedByDefault);
	}
	
	protected void setScenario(Scenario scenario) {
		this.scenario = scenario;
	}

	protected void write(String message) {
		if (!Objects.isNull(scenario)) {
			scenario.log(message);
		}
	}
	
	protected void writeResposeInCucumberReport() {
		try {
			if(!Objects.isNull(result)) {
				StringWriter writer = new StringWriter();
				result.andDo(print(writer));
				write(writer.toString());
			}
		}catch (Exception e) {
			log.warn(e.getMessage());
		}
	}
	
	public SpringIntegrationTestStepsBase(MockMvc mockMvc, String keycloakBaseUrl, String keycloakRealm,String logRequestInFile) throws IOException, JoseException {
		super(keycloakBaseUrl, keycloakRealm);
		this.mockMvc = mockMvc;
		OutputStream o = null;
		String logFolder = MAVEN_TARGET_FOLDER;
		if (Strings.isNotBlank(logFolder)) {
			File file = new File(logFolder);
			if (file.exists() && !file.isDirectory()) {
				throw new RuntimeException("folder " + logFolder + "is not a directory");
			}
			file = new File(logFolder + "/" + logRequestInFile);
			if (file.exists()) {
				file.delete();
			}
			if (!file.exists()) {
				try {
					file.createNewFile();
					// file.setExecutable(true,true);
					file.setWritable(false, true);
				} catch (IOException e) {
					log.error("Can't create new file in {} due to {}",file.getAbsolutePath(), e.getMessage());
				}
			}
			try {
				o = new FileOutputStream(file,true);
			} catch (FileNotFoundException e) {
				log.error("File not fount {}",file.getAbsoluteFile());
			}finally {
				if(Objects.isNull(o)) {
					out = System.out;
				}else {
					out=o;
				}
					o.close();
			}
		} else {
			out= System.out;
		}
	}
	
	protected String cleanJson(String event) {
		return new CleanJson().convert(event);
	}

	public void thenTheStatusShouldBeOk() throws Exception {
		assertNotNull("No Result", result);
		writeResposeInCucumberReport();
		result.andExpect(status().isOk());
	}

	public void applicationRaiseError() throws Exception {
		assertNotNull("No Result", result);
		writeResposeInCucumberReport();
		result.andExpect(status().isInternalServerError());
	}

	public void applicationRejectRequestError() throws Exception {
		assertNotNull("No Result", result);
		writeResposeInCucumberReport();
		result.andExpect(status().isBadRequest());
	}

	public void matchJsonPath(String path, String error) throws Exception {
		assertNotNull("No Result", result);
		writeResposeInCucumberReport();
		result.andExpect(jsonPath(path).exists()).andExpect(jsonPath(path).value(error));
	}

	public void matchPatternJsonPath(String path, String pattern) throws Exception {
		assertNotNull("No Result", result);
		writeResposeInCucumberReport();
		result.andExpect(jsonPath(path).exists()).andExpect(jsonPath(path, new ResponsePatternMatch(pattern)));
	}

	public void atLeastLenght(String path, Integer size) {
		writeResposeInCucumberReport();
		String json;
		try {
			json = result.andExpect(jsonPath(path).exists()).andExpect(jsonPath(path).isArray()).andReturn().getResponse().getContentAsString();
			JSONArray jsonArray = JsonPath.read(json, path);
			assertTrue("Size mismatch", size <= Integer.valueOf(jsonArray.size()));
		} catch (Exception e) {
			log.error(" ", e.getMessage());
			fail(e.getMessage()); //only for test purpose
		}
	}

	public void matchLenght(String path, Integer size) {
		writeResposeInCucumberReport();
		String json;
		try {
			json = result.andExpect(jsonPath(path).exists()).andExpect(jsonPath(path).isArray()).andReturn().getResponse().getContentAsString();
			JSONArray jsonArray = JsonPath.read(json, path);
			assertEquals("Size mismatch", size, Integer.valueOf(jsonArray.size()));
		} catch (Exception e) {
		    log.error(" ", e.getMessage());
			fail(e.getMessage());
		}
	}
}
