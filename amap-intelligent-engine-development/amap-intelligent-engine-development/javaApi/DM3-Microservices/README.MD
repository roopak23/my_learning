# DM3 Microservice Layer

- [Solution Architecture](#solution-architecture)
- [KeyCloak](#keycloak)
  - [Registry](#registry)
  - [Config Server](#config-server)
  - [Gateway](#gateway)
- [Eclipse Workspace](#eclipse)
  - [Import Launch Configuration](#launch-config)
  - [Setup Launch Configuration](#eclipse-setup)
- [Requirements <a name="requirements"></a>](#requirements)
- [LINKS <a name="links"></a>](#links)

## Solution Architecture <a name="solution-architecture"></a>

![Solution Architecture][]

## [KeyCloak][KeyCloak] <a name="keycloak"></a>

KeyCloak is an open source identity and access management, take a look to its [download page][keyCloak_Download].

[Here you can find the installation step on kubernetes][KeyCloak_k8s] or [via helm in this github repository][KeyCloak_k8s_codecentric]

### [Registry][eureka_registry] <a name="registry"></a>

This is the core component of the whole architecture. It allows to any application to register in order to be visible and used from other components (such as the Gateway or Monitoring App).
To accomplish a Service registration and discovery, Registry component is responsible to maintain the registry of all the Microservices that has been deployed and removed. This will act like a catalog of all other applications/microservices, acting as a lookup service where a client microservice can register and be discovered by other registered microservices.

### [Config Server][spring_config_server] <a name="config-server"></a>

The Config Server is is used for storing and serving distributed configurations across multiple applications and environments. This configuration can be stored and versioned under Git version control and can be modified at application runtime.

### [Gateway][zuul] <a name="gateway"></a>

This component exposes the single-entry point for user’s requests by federating multiple API’s of different applications, such as the Authorization server REST API’s and Metadata application REST API’s. The gateway has 2 goals:

1.	For a given request, it must be able to understand through the Registry component which microservice it must be redirected to;
2.	If a microservice has more than one active instance, it will distribute the requests by routing them to the most appropriate instance basing on its load.

## Eclipse Workspace <a name="eclipse"></a>

### Import Launch Configuration <a name="launch-config"></a>

In the folder [dev-files\eclipse](dev-files\eclipse) you will find a zip file [launch-config.zip](dev-files\eclipse\launch-config.zip) that containing the launch configuration to be imported

### Setup Launch Configuration <a name="eclipse-setup"></a>

Once the run configuration will be imported in eclipse, it's needed to write some variable in our workspace

- **DB_PASS**: it is used during tests
- **JAVA_ARGS**: global java VM arguments, use this value *-Xmx250m*
- **AMAP_DB_SCHEMA**: schema used for local test
- **KEYCLOAK_HOME**: keycloak local installation folder


to create those variables, it's is needed to **open a run configuration** , click on **Add** to create a new parameter, click on **variables** then on **Edit Variables**

## Requirements <a name="requirements"></a>

- Java 1.8
- [Apache Maven 3.6+][maven]
- [Eclipse][eclipse] for java development (or [Spring Tools Suite 4][STS4])


## LINKS <a name="links"></a>

- [Eclipse Run Configuration](./dev-files/eclipse/launch-config)
- [Spring Boot][]
- [Spring Cloud][]

[solution architecture]: ./dev-files/images/network.png
[api flow]: ./dev-files/images/api_flow.png

<!-- external tools -->

[STS4]: https://spring.io/tools
[maven]: https://maven.apache.org/download.cgi
[eclipse]: https://www.eclipse.org/downloads/
[junction]: https://docs.microsoft.com/en-us/sysinternals/downloads/junction
[Spring Boot]: https://spring.io/projects/spring-boot
[Spring Cloud]: https://spring.io/projects/spring-cloud
[KeyCloak]: https://www.keycloak.org/
[keyCloak_Download]: https://www.keycloak.org/downloads
[KeyCloak_k8s]: https://www.keycloak.org/getting-started/getting-started-kube#:~:text=%20Keycloak%20on%20Kubernetes%20%201%20Before%20you,the%20username%20and%20password%20you%20created...%20More
[KeyCloak_k8s_codecentric]: https://github.com/codecentric/helm-charts/tree/master/charts/keycloak
[eureka_registry]: https://cloud.spring.io/spring-cloud-netflix/multi/multi_spring-cloud-eureka-server.html
[spring_config_server]: https://cloud.spring.io/spring-cloud-config/multi/multi__spring_cloud_config_server.html
[zuul]: https://cloud.spring.io/spring-cloud-netflix/multi/multi__router_and_filter_zuul.html