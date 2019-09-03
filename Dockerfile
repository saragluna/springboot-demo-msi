FROM openjdk:8-jdk-alpine

COPY target/demo-0.0.1-SNAPSHOT.jar app.jar

RUN apk update && apk add bash

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]