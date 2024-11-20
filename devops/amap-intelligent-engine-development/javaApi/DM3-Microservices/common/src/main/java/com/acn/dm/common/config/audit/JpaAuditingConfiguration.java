package com.acn.dm.common.config.audit;

import java.util.Optional;


import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.core.context.SecurityContextHolder;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 *
 */
//@Slf4j
//@Profile(PROFILES.AUDITING)
//@Configuration
//@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
public class JpaAuditingConfiguration {
	
//	public static String getLoggedUser() {
//		return SecurityContextHolder.getContext().getAuthentication().getName();
//	}
//
//    @Bean
//    public AuditorAware<String> auditorProvider() {
//        return () -> Optional.ofNullable(getLoggedUser());
//    }
//    
//    @PostConstruct
//    private void logInfo() {
//    	log.info("Registered Audit listener");
//    }
}
