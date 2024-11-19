package com.acn.dm.testing.cucumber.reporting;

import com.acn.dm.testing.SpringIntegrationTestStepsBase;
import io.cucumber.plugin.ConcurrentEventListener;
import io.cucumber.plugin.event.EventPublisher;
import io.cucumber.plugin.event.TestRunFinished;
import jakarta.annotation.PostConstruct;
import java.io.File;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import net.masterthought.cucumber.Configuration;
import net.masterthought.cucumber.ReportBuilder;
import org.apache.commons.io.FileUtils;
import org.apache.logging.log4j.util.Strings;

/**
 * @author Alberto Riminucci
 */
@Slf4j
public class CustomCucumberReporterPlugin implements ConcurrentEventListener {
	
	private final String DEFAULT_TITLE = "Cucumber Report DM3";
	private final String title;
	
	public CustomCucumberReporterPlugin(String title) {
		this.title = Strings.isBlank(title) ? DEFAULT_TITLE : title;
		log.info("Project title {}", title);
	}

	@PostConstruct
	public void logInfo() {
		log.info("Registred CustomCucumberReporterPlugin");
	}
	
	@Override
	public void setEventPublisher(EventPublisher publisher) {
		publisher.registerHandlerFor(TestRunFinished.class, this::run);
	}
	
	public void run(TestRunFinished event) {
		LocalDateTime start = LocalDateTime.now();
		log.info("Start generating report at {}", start);
		Collection<File> jsonFiles = FileUtils.listFiles(new File(SpringIntegrationTestStepsBase.OUTPUT_PATH), new String[] { "json" }, true);
		List<String> jsonPaths = new ArrayList<String>(jsonFiles.size());
		jsonFiles
			.stream()
			.filter(e -> e.length() > 0)
			.forEach(file -> jsonPaths.add(file.getAbsolutePath()));
		if(log.isInfoEnabled()) {
			log.info("Analize the following files");
			jsonFiles.forEach(file -> log.info("\t- {}",file.getName()));
		}
		if(jsonFiles.isEmpty()) {
			log.warn("No Report to generate");
			return;
		}
		Configuration config = new Configuration(new File("target"), title);
		ReportBuilder reportBuilder = new ReportBuilder(jsonPaths, config);
		reportBuilder.generateReports();
		log.info("Shutdown Complite in {}s", ChronoUnit.SECONDS.between(start, LocalDateTime.now()));
//		} catch (InterruptedException e1) {
//			// TODO Auto-generated catch block
//			e1.printStackTrace();
//		}	
	}

}
