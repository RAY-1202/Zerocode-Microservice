FROM maven:3.9.11-eclipse-temurin-21 AS build

WORKDIR /workspace
COPY . .
RUN cp zerocode-app/src/main/resources/application.example.yml zerocode-app/src/main/resources/application.yml \
    && cp zerocode-user/src/main/resources/application.example.yml zerocode-user/src/main/resources/application.yml \
    && cp zerocode-screenshot/src/main/resources/application.example.yml zerocode-screenshot/src/main/resources/application.yml \
    && mvn -DskipTests package

FROM selenium/standalone-chromium:latest

USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openjdk-21-jre-headless mariadb-server redis-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /workspace/zerocode-user/target/zerocode-user-0.0.1-SNAPSHOT.jar user.jar
COPY --from=build /workspace/zerocode-app/target/zerocode-app-0.0.1-SNAPSHOT.jar app.jar
COPY --from=build /workspace/zerocode-screenshot/target/zerocode-screenshot-0.0.1-SNAPSHOT.jar screenshot.jar
COPY sql/create_table.sql schema.sql
COPY cloudflare/start.sh start.sh
RUN chmod 0755 start.sh

EXPOSE 8124 8125 8127 50051 50052
ENTRYPOINT ["/app/start.sh"]
