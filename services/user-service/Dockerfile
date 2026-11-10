
# Stage 1: Build the application
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy the complete Maven project, including shared libraries
COPY pom.xml .
COPY libs ./libs
COPY services ./services

# Build only user-service and its required dependencies
RUN mvn -pl services/user-service -am clean package -DskipTests

# Stage 2: Run the application
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create a non-root user
RUN useradd --system --uid 1001 appuser

# Copy the built JAR from the build stage
COPY --from=build /app/services/user-service/target/user-service-0.1.0.jar app.jar

# Run as non-root
USER appuser

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
