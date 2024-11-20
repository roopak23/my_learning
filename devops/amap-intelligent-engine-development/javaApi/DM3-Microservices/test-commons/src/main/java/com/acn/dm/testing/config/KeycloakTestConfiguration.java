package com.acn.dm.testing.config;

import java.io.IOException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.jose4j.jwk.JsonWebKeySet;
import org.jose4j.jwk.RsaJsonWebKey;
import org.jose4j.jwk.RsaJwkGenerator;
import org.jose4j.jws.AlgorithmIdentifiers;
import org.jose4j.jws.JsonWebSignature;
import org.jose4j.jwt.JwtClaims;
import org.jose4j.jwt.NumericDate;
import org.jose4j.lang.JoseException;

import com.github.tomakehurst.wiremock.client.WireMock;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Alberto Riminucci
 */
@Slf4j
public class KeycloakTestConfiguration {
	
	public static final String MOCK_FILE_LOCATION = "classpath:/keycloak-mock";
	
	private static RsaJsonWebKey rsaJsonWebKey;
//	private static boolean testSetupIsCompleted = false;
	private final String keycloakBaseUrl;
	private final String keycloakRealm;
	protected final String AUTHENTICATION_HEADER = "Authorization";
	protected final String TOKEN_TYPE = "Bearer";
	
	public KeycloakTestConfiguration(String keycloakBaseUrl, String keycloakRealm) throws IOException, JoseException {
		super();
		this.keycloakBaseUrl = keycloakBaseUrl;
		this.keycloakRealm = keycloakRealm;
		log.info("keycloakBaseUrl = {}", keycloakBaseUrl);
		log.info("keycloakRealm = {}", keycloakRealm);
//		setUpMockKeyCloak();
//		rsaJsonWebKey = RsaJwkGenerator.generateJwk(2048);
//		rsaJsonWebKey.setKeyId("k1");
//		rsaJsonWebKey.setAlgorithm(AlgorithmIdentifiers.RSA_USING_SHA256);
//		rsaJsonWebKey.setUse("sig");
		setUpMockKeyCloak();
	}

	public void setUpMockKeyCloak() throws IOException, JoseException {
//		if (!testSetupIsCompleted) {
			log.info("Set up mock server");
			// Generate an RSA key pair, which will be used for signing and verification of
			// the JWT, wrapped in a JWK
			rsaJsonWebKey = RsaJwkGenerator.generateJwk(2048);
			rsaJsonWebKey.setKeyId("k1");
			rsaJsonWebKey.setAlgorithm(AlgorithmIdentifiers.RSA_USING_SHA256);
			rsaJsonWebKey.setUse("sig");

			String openidConfig = "" 
					+ "{"
						+ "\"issuer\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "\","
						+ "\"authorization_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/auth\","
						+ "\"token_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/token\","
						+ "\"token_introspection_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/token/introspect\","
						+ "\"userinfo_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/userinfo\","
						+ "\"end_session_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/logout\","
						+ "\"jwks_uri\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/certs\","
						+ "\"check_session_iframe\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/login-status-iframe.html\","
						+ "\"registration_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/clients-registrations/openid-connect\","
						+ "\"introspection_endpoint\": \"" + keycloakBaseUrl + "/auth/realms/" + keycloakRealm + "/protocol/openid-connect/token/introspect\""
					+ "}";
			WireMock.stubFor(WireMock.get(WireMock.urlEqualTo(String.format("/auth/realms/%s/.well-known/openid-configuration", keycloakRealm)))
					.willReturn(WireMock.aResponse().withHeader("Content-Type", "application/json").withBody(openidConfig)));
			WireMock.stubFor(WireMock.get(WireMock.urlEqualTo(String.format("/auth/realms/%s/protocol/openid-connect/certs", keycloakRealm)))
					.willReturn(WireMock.aResponse().withHeader("Content-Type", "application/json").withBody(new JsonWebKeySet(rsaJsonWebKey).toJson())));
			log.info("{}",openidConfig);
			log.info("{}", new JsonWebKeySet(rsaJsonWebKey).toJson());
//			testSetupIsCompleted = true;
//		}
	}
	
	protected String getTokenForRequest() throws JoseException, IOException {
		return new StringBuilder().append(TOKEN_TYPE).append(" ").append(generateJWT(true)).toString();
	}

	protected String generateJWT(boolean withTenantClaim) throws JoseException, IOException {
		log.info("Create Token");
		Map<String,List<String>> realm_access = new HashMap<>();
		realm_access.put("roles", Arrays.asList("offline_access", "uma_authorization", "user"));
		
		Map<String,Map<String,List<String>>> resource_access = new HashMap<>();
		Map<String,List<String>> account_roles = new HashMap<>();
		account_roles.put("roles", Arrays.asList("manage-account", "manage-account-links", "view-profile"));
		resource_access.put("account", account_roles);
		
		
		
		// Create the Claims, which will be the content of the JWT
		JwtClaims claims = new JwtClaims();
		claims.setJwtId(UUID.randomUUID().toString()); // a unique identifier for the token
		claims.setExpirationTimeMinutesInTheFuture(10); // time when the token will expire (10 minutes from now)
		claims.setNotBeforeMinutesInThePast(0); // time before which the token is not yet valid (2 minutes ago)
		claims.setIssuedAtToNow(); // when the token was issued/created (now)
		claims.setAudience("account"); // to whom this token is intended to be sent
		claims.setIssuer(String.format("%s/auth/realms/%s", keycloakBaseUrl, keycloakRealm)); // who creates the token and signs it
		claims.setSubject(UUID.randomUUID().toString()); // the subject/principal is whom the token is about
		claims.setClaim("typ", "Bearer"); // set type of token
		claims.setClaim("azp", "example-client-id"); // Authorized party (the party to which this token was issued)
		claims.setClaim("auth_time", NumericDate.fromMilliseconds(Instant.now().minus(11, ChronoUnit.SECONDS).toEpochMilli()).getValue()); // time when authentication occured
		claims.setClaim("session_state", UUID.randomUUID().toString()); // keycloak specific ???
		claims.setClaim("acr", "0"); // Authentication context class
		claims.setClaim("realm_access", realm_access); // keycloak roles
		claims.setClaim("resource_access",resource_access); // keycloak roles
		claims.setClaim("scope", "profile email");
		claims.setClaim("name", "John Doe"); // additional claims/attributes about the subject can be added
		claims.setClaim("email_verified", true);
		claims.setClaim("preferred_username", "doe.john");
		claims.setClaim("given_name", "John");
		claims.setClaim("family_name", "Doe");

		// A JWT is a JWS and/or a JWE with JSON claims as the payload.
		// In this example it is a JWS so we create a JsonWebSignature object.
		JsonWebSignature jws = new JsonWebSignature();

		// The payload of the JWS is JSON content of the JWT Claims
		jws.setPayload(claims.toJson());

		// The JWT is signed using the private key
		jws.setKey(rsaJsonWebKey.getPrivateKey());

		// Set the Key ID (kid) header because it's just the polite thing to do.
		// We only have one key in this example but a using a Key ID helps
		// facilitate a smooth key rollover process
		jws.setKeyIdHeaderValue(rsaJsonWebKey.getKeyId());

		// Set the signature algorithm on the JWT/JWS that will integrity protect the
		// claims
		jws.setAlgorithmHeaderValue(AlgorithmIdentifiers.RSA_USING_SHA256);

		// set the type header
		jws.setHeader("typ", "JWT");

		// Sign the JWS and produce the compact serialization or the complete JWT/JWS
		// representation, which is a string consisting of three dot ('.') separated
		// base64url-encoded parts in the form Header.Payload.Signature
		return jws.getCompactSerialization();
	}

}
