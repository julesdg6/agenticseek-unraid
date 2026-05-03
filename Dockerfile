FROM python:3.11.12
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Default runtime environment variables.
# REDIS_URL, PORT, and CHOKIDAR_USEPOLLING are set here so that supervisord
# child processes inherit them without needing explicit environment= directives
# (which would replace – not extend – the container environment and would
# prevent user-supplied variables such as REACT_APP_BACKEND_URL from reaching
# the frontend dev-server or PROVIDER_* vars from reaching the backend).
ENV REDIS_URL=redis://localhost:6379/0
ENV PORT=3000
ENV CHOKIDAR_USEPOLLING=true
# Pin Chrome to a tested version. Update alongside the upstream Dockerfile.backend
# when new agenticSeek releases are made. Check available versions at:
# https://googlechromelabs.github.io/chrome-for-testing/
ENV CHROME_TESTING_VERSION=134.0.6998.88

# Persistent config/runtime directory that is safe to bind-mount from the host
# without shadowing any application source code.
RUN mkdir -p /app/userdata

# Install system packages required by the backend, Chrome, and Node.js
RUN apt-get update -y && apt-get install -y \
    curl \
    wget \
    gnupg2 \
    ca-certificates \
    unzip \
    xvfb \
    libxss1 \
    fonts-liberation \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    dbus \
    gcc \
    g++ \
    gfortran \
    libportaudio2 \
    portaudio19-dev \
    ffmpeg \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libasound2 \
    alsa-utils \
    libgtk-4-1 \
    supervisor \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18 (LTS) via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome for Testing
RUN set -eux; \
    wget -qO /tmp/chrome.zip \
      "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_TESTING_VERSION}/linux64/chrome-linux64.zip"; \
    unzip -q /tmp/chrome.zip -d /opt; \
    rm /tmp/chrome.zip; \
    ln -s /opt/chrome-linux64/chrome /usr/local/bin/google-chrome; \
    ln -s /opt/chrome-linux64/chrome /usr/local/bin/chrome; \
    mkdir -p /opt/chrome; \
    ln -s /opt/chrome-linux64/chrome /opt/chrome/chrome; \
    chmod +x /opt/chrome/chrome; \
    google-chrome --version

# Install ChromeDriver
RUN set -eux; \
    wget -qO /tmp/chromedriver.zip \
      "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_TESTING_VERSION}/linux64/chromedriver-linux64.zip"; \
    unzip -q /tmp/chromedriver.zip -d /tmp; \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin; \
    rm /tmp/chromedriver.zip; \
    chmod +x /usr/local/bin/chromedriver; \
    chromedriver --version

RUN pip3 install --upgrade pip setuptools wheel

# Install Python backend dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install npm dependencies for the React frontend
WORKDIR /frontend
COPY frontend/agentic-seek-front/package.json frontend/agentic-seek-front/package-lock.json ./
RUN npm ci && npm rebuild
RUN test -f node_modules/.bin/react-scripts || npm install react-scripts
COPY frontend/agentic-seek-front/ .

# Copy Python backend source
WORKDIR /app
COPY api.py .
COPY sources/ ./sources/
COPY prompts/ ./prompts/
COPY crx/ crx/
COPY llm_router/ llm_router/
COPY config.ini .

# Create required directories
RUN mkdir -p /opt/workspace /app/screenshots /data /var/log/supervisor

# Supervisord configuration for multi-process management
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3000 7777

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
