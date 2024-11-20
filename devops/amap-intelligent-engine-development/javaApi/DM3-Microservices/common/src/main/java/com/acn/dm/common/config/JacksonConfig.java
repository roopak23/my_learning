package com.acn.dm.common.config;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.format.Formatter;

import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 *
 */
@Slf4j
@Configuration
public class JacksonConfig {

	// @formatter:off 
	public static final DateTimeFormatter CUSTOM_DATE_TIME_FORMAT = new DateTimeFormatterBuilder()
			.append(DateTimeFormatter.ISO_LOCAL_DATE)
			.appendLiteral(' ')
			.append(DateTimeFormatter.ISO_LOCAL_TIME)
			.toFormatter();
	// @formatter:on

	private static LocalDateTime parseDateTime(String text) {
		LocalDateTime ret = null;
		try {
			ret = LocalDateTime.parse(text, DateTimeFormatter.ISO_DATE_TIME);
		} catch (Exception e) {
			ret = LocalDateTime.parse(text, CUSTOM_DATE_TIME_FORMAT);
		}
		return ret;
	}

	@Bean
	@Primary
	public Formatter<LocalDateTime> localDateTimeFormatter() {
		log.info("Register Jackson Converter - {}",LocalDateTime.class);
		return new Formatter<LocalDateTime>() {
			@Override
			public LocalDateTime parse(String text, Locale locale) {
				return JacksonConfig.parseDateTime(text);
			}

			@Override
			public String print(LocalDateTime object, Locale locale) {
				return DateTimeFormatter.ISO_DATE_TIME.format(object);
			}
		};
	}
	
	@Bean
	public ObjectMapper objectMapper(
			@Value("${application.jackson.include-null:false}") boolean includeNotNull,
			@Value("${application.jackson.write-date-as-timestamp:false}") boolean writeDateAsTimestamp,
			@Value("${application.jackson.fail-on-unknown-properties:true}") boolean failOnUnknownProps
		) {
		ObjectMapper mapper = new ObjectMapper();
		if(includeNotNull) {
			log.info("Configuring object mapper to include null value of a DTO");
			mapper.setSerializationInclusion(Include.ALWAYS);
		}else {
			log.info("Configuring object mapper to ignore null value of a DTO");
			mapper.setSerializationInclusion(Include.NON_NULL);
		}
		if(!writeDateAsTimestamp) {
			log.info("Disable WRITE_DATES_AS_TIMESTAMPS feature");
			mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
		}
		mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, failOnUnknownProps);
		log.info("Configuring object mapper to {} on unknow propeties of a DTO", failOnUnknownProps ? "FAIL" : "IGNORE");
		mapper.registerModule(new JavaTimeModule());
		return mapper;
	}

}
