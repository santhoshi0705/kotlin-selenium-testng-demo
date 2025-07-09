# ---------- Stage 1: Build the Kotlin project using Maven ----------
FROM maven:3.8.7-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom and fetch dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source files
COPY src ./src

# Compile only (don't run tests during image build)
RUN mvn clean compile


# ---------- Stage 2: Runtime/Test Stage ----------
FROM eclipse-temurin:17-jdk

# Install Chrome & dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    unzip \
    jq \
    fonts-liberation \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libasound2t64 \
    libxshmfence1 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# Install matching ChromeDriver
RUN CHROME_VERSION=$(google-chrome --version | awk '{ print $3 }' | cut -d '.' -f 1) && \
    DRIVER_VERSION=$(curl -sS "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json" | \
    jq -r --arg ver "$CHROME_VERSION" '.versions[] | select(.version | startswith($ver)) | .version' | head -n 1) && \
    wget -q "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${DRIVER_VERSION}/linux64/chromedriver-linux64.zip" && \
    unzip chromedriver-linux64.zip && \
    mv chromedriver-linux64/chromedriver /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromedriver && \
    rm -rf chromedriver-linux64*

ENV PATH="/usr/bin:${PATH}"

WORKDIR /app

# Copy the built source and dependencies
COPY --from=builder /app .

# Run tests (they must use headless mode)
CMD ["mvn", "test"]
