FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace

COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
COPY document-service/build.gradle document-service/build.gradle
COPY authentication-service/build.gradle authentication-service/build.gradle
COPY anonymization-service/build.gradle anonymization-service/build.gradle
RUN chmod +x gradlew

COPY anonymization-service/src anonymization-service/src
RUN ./gradlew :anonymization-service:bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
WORKDIR /app

COPY --from=build /workspace/anonymization-service/build/libs/*.jar app.jar

EXPOSE 8094
USER 10001:10001

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
