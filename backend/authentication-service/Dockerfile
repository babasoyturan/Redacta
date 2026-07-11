FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace

COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
COPY document-service/build.gradle document-service/build.gradle
COPY authentication-service/build.gradle authentication-service/build.gradle
COPY anonymization-service/build.gradle anonymization-service/build.gradle
RUN chmod +x gradlew

COPY authentication-service/src authentication-service/src
RUN ./gradlew :authentication-service:bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine

# Kubernetes runAsNonRoot requires a numeric image user it can verify.
RUN apk upgrade --no-cache \
    && addgroup -S -g 10001 app \
    && adduser -S -u 10001 -G app app
WORKDIR /app

COPY --from=build /workspace/authentication-service/build/libs/*.jar app.jar

EXPOSE 8092
USER 10001:10001

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
