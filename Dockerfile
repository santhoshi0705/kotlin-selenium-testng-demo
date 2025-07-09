# ---------- Stage 1: Build the Kotlin project using Maven ----------
FROM maven:3.8.7-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy project files
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src

# Compile and run tests
RUN mvn clean test


# ---------- Stage 2: Runtime (Optional, if you want to run jar) ----------
# Only needed if you want to run compiled JAR; omit if just testing.
FROM eclipse-temurin:17-jdk

# Install Chrome dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    unzip \
    fonts-liberation \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxshmfence1 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

WORKDIR /app

# Copy built files if needed (skip if test-only)
# COPY --from=builder /app/target/kotlin-selenium-testng-demo-1.0-SNAPSHOT.jar app.jar
# ENTRYPOINT ["java", "-jar", "app.jar"]

# If just running tests, use Maven
COPY --from=builder /app .

CMD ["mvn", "test"]
