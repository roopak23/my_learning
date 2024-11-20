package com.acn.dm.order.config;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import org.apache.logging.log4j.util.Strings;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;

import com.acn.dm.order.lov.OrderStatus;
import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.utils.Utils;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.google.common.collect.ImmutableTable;
import com.google.common.collect.ImmutableTable.Builder;
import com.google.common.collect.Table;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Configuration
public class TriggerActionConfiguration {

	@Value("${application.change-status-mapping.delimiter:;}")
	private String DELIMITER;
	
	@Value("classpath:status_change_action_mapping.csv")
	private Resource INTERNAL_STATUS_MAPPING;
		
	private static final String COMMA_DELIMITER = ",";

	@Bean
	@ConditionalOnProperty(name = "application.change-status-mapping.external-file", havingValue = "true", matchIfMissing = false)
	public Table<OrderStatus, OrderStatus, List<OrderSyncActions>> triggerToActionConverterUsingExternalFile(@Value("${application.change-status-mapping.file}") String fileName)
			throws JsonParseException, JsonMappingException, IOException {
		log.info("Load trigger mapping from external file {}", fileName);
		return createTableMapping(new FileSystemResource(fileName));
	}

	@Bean
	@ConditionalOnProperty(name = "application.change-status-mapping.external-file", havingValue = "false", matchIfMissing = true)
	public Table<OrderStatus, OrderStatus, List<OrderSyncActions>> triggerToActionConverterUsingInternalFile() throws JsonParseException, JsonMappingException, IOException {
		log.info("Load trigger mapping from internal file {}", INTERNAL_STATUS_MAPPING);
		return createTableMapping(INTERNAL_STATUS_MAPPING);
	}

	private Table<OrderStatus, OrderStatus, List<OrderSyncActions>> createTableMapping(Resource resource) throws FileNotFoundException, IOException {
		List<OrderStatus> headers = null;
		Builder<OrderStatus, OrderStatus, List<OrderSyncActions>> table = ImmutableTable.builder();
		try (BufferedReader br = new BufferedReader(new InputStreamReader(resource.getInputStream(),"UTF-8"))) {
			String line;
			while ((line = br.readLine()) != null) {
				OrderStatus rowKey = null;
				log.info(line);
				if (Strings.isBlank(line)) {
					continue;
				}
				String[] values = line.split(DELIMITER);
				if (null == headers) {
					headers = Arrays.asList(values).subList(0, values.length).stream().map(OrderStatus::fromString).collect(Collectors.toList());
				log.info(headers.size()+ " " +headers.get(0)+ " " +headers.get(headers.size()-1));
				} else {
					rowKey = OrderStatus.fromString(values[0]);
					for (Integer i = 0; i < headers.size(); i++) {
						Integer j = i + 1;
						if (j >= values.length) {
							break;
						}
						String val = values[j];
						OrderStatus column = headers.get(i);
						// @formatter:off
						List<OrderSyncActions> value = Arrays
									.asList(val.split(COMMA_DELIMITER))
									.stream()
									.filter(Strings::isNotBlank)
									.map(String::trim)
									.map(e -> Utils.getEnumFromString(OrderSyncActions.class,e))
									.collect(Collectors.toList()); 
						// @formatter:on
						if(Objects.isNull(value) || value.isEmpty()) {
							log.warn("status change not mapped {} -> {}",rowKey,column);
						}else {							
							log.info("map status change {} -> {} as {}",rowKey,column,value);
						}
						table.put(rowKey,column,value);
					}
				}
			}
		}
		return table.build();
	}

}
