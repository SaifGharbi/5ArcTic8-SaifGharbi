FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

COPY --chown=10001:10001 target/backend-1.0.0.jar app.jar

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
