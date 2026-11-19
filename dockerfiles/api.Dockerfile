FROM eclipse-temurin:21-jre
WORKDIR /opt/agroconecta
COPY citizentech-api-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/opt/agroconecta/app.jar"]
