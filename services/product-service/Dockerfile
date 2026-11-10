
# Stage 1: Build the application using Maven and Java 21
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
COPY libs ./libs
COPY services ./services

RUN mvn -pl services/product-service -am clean package -DskipTests

# Stage 2: Run the application using a lightweight Alpine JRE
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the finished JAR from the build stage
COPY --from=build /app/services/product-service/target/product-service-0.1.0.jar app.jar

# Run as a non-root user
USER appuser

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "app.jar"]
