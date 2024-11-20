#FROM openjdk:8-jre-alpine
FROM amazoncorretto:17.0.10-alpine3.17
RUN apk --no-cache add curl
ARG ARTIFACT=@project.artifactId@
ARG PROJECT_VERSION=@project.version@
ARG PORT=8080
ARG EXT=jar
ARG INFO_DIR=META-INF
EXPOSE ${PORT}
ENV APP_PORT=${PORT}
ENV APP_JAR=${ARTIFACT}-${PROJECT_VERSION}.${EXT}
ADD ./${INFO_DIR} /app-info
COPY ./healthcheck.sh /healthcheck.sh
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=10 CMD ["/bin/sh","/healthcheck.sh"]
COPY $APP_JAR /app.jar
ENTRYPOINT ["java","-jar","-XX:MaxRAMPercentage=50","/app.jar"]