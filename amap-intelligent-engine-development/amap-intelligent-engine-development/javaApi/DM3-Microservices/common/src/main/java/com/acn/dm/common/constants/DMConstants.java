/**
 * 
 */
package com.acn.dm.common.constants;

/**
 * @author Shivani Chaudhary
 *
 */
public class DMConstants {
	
	public static final String COMMON_BASE_PACKAGE = "com.acn.dm";
	
	public static final String COMMON_BASE = "com.acn.dm.common";
	public static final String AUDIT_CONFIG = COMMON_BASE + ".config.audit";
	public static final String AUTH_CONFIG = COMMON_BASE + ".config.auth";
	public static final String AUTH_ACTUATOR_CONFIG = AUTH_CONFIG + ".actuator";
	public static final String AUTH_ACTUATOR_CONFIG_GENERAL = AUTH_ACTUATOR_CONFIG + ".general";
	public static final String AUTH_ACTUATOR_CONFIG_RESOURCE_SERVER = AUTH_CONFIG + ".resource.server";
	public static final String CORS_CONFIG = COMMON_BASE + ".cors";
	public static final String COMMON_SERVICES = COMMON_BASE + ".service";
	public static final String SHARED_CONFIG = COMMON_BASE + ".config";
	public static final String COMMON_SERVICE = COMMON_BASE + ".service";
	public static final String COMMON_LOV = COMMON_BASE + ".model.lov";
	public static final String SWAGGER = COMMON_BASE + ".config.swagger";
	
	public static final int ACTUATOR_SECURITY_ORDER = 99;
	
	public static final String ACTUATOR_SECURITY_PROPERTY_NAME = "application.actuator.security.enabled";
	
}
