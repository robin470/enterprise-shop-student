FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
COPY libs ./libs
COPY services ./services

RUN mvn -pl services/payment-service -am clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S appgroup && adduser -S -u 1001 -G appgroup appuser

COPY --from=build /app/services/payment-service/target/payment-service-0.1.0.jar app.jar

USER appuser

EXPOSE 8084

ENTRYPOINT ["java", "-jar", "app.jar"]