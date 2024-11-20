package com.acn.dm.common.utils;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.logging.log4j.util.Strings;
import org.springframework.core.env.Environment;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class LogAppInfo {

	private static final String DELIMITER = "-------------------------------------------------------------------------------------------";

	private static final List<String> INFOS = Arrays.asList(
			"",
			DELIMITER,
			"\tApplication '{}' is running!",
			"\tLocal Access:     {}://{}:{}",
			"\tExternal Access:  {}://{}:{}",
			"\tContext Path:     {}",
			"\tProfile(s):       {}",
			DELIMITER,
			""
		);

	public static void logInfo(Environment env) {
		String protocol = "http";
		if (env.getProperty("server.ssl.key-store") != null) {
			protocol = "https";
		}
		try {
			List<String> profiles = new ArrayList<>();
			profiles.add(env.getProperty("spring.profiles.active","default"));
			profiles.addAll(Arrays.asList(env.getProperty("spring.profiles.include","").split(",")));
			log.info(
					String.join("\n",INFOS),
					env.getProperty("spring.application.name"),
					protocol,
					env.getProperty("server.address", "localhost"),
					env.getProperty("server.port"),
					protocol,
					InetAddress.getLocalHost().getHostAddress(),
					env.getProperty("server.port"),
					env.getProperty("server.servlet.context-path","/"),
					profiles.stream().filter(Strings::isNotBlank).collect(Collectors.toList())
			);
		} catch (UnknownHostException e) {
			log.error("{}", e.getMessage());
		}
	}
}
