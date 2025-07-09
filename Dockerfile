# -------- Stage 1: Build the Kotlin project using Maven --------
FROM maven:3.8.7-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy POM and download dependencies first (for caching)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source files
COPY src ./src

# Package the JAR
RUN mvn clean package -DskipTests


# -------- Stage 2: Runtime environment with headless Chrome --------
FROM eclipse-temurin:17-jdk

# Install dependencies for Chrome
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    gnupg \
    curl \
    fonts-liberation \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxshmfence1 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# Set working directory
WORKDIR /app

# Copy the jar from the builder
COPY --from=builder /app/target/kotlin-selenium-testng-demo-1.0-SNAPSHOT.jar app.jar

# Set entrypoint
ENTRYPOINT ["java", "-jar", "app.jar"]
