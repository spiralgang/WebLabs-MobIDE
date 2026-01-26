# Use the latest Ubuntu LTS as the base image
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Metadata
LABEL org.opencontainers.image.source=https://github.com/spiralgang/WebLabs-MobIDE
LABEL description="WebLabs MobIDE: Autonomous Mobile Development Environment"

# Update and install essential development tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    git \
    curl \
    wget \
    nano \
    vim \
    zip \
    unzip \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set up the workspace directory
WORKDIR /workspace

# Copy project files into the image
COPY . /workspace

# Install Python dependencies if requirements.txt exists
RUN if [ -f requirements.txt ]; then \
    python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt; \
    fi

# Install Node.js dependencies if package.json exists
RUN if [ -f package.json ]; then \
    npm install; \
    fi

# Expose ports for WebIDE (8080) and Flask/Dev servers (3000, 5000)
EXPOSE 8080 3000 5000

# Set the default command to bash (or your start script)
CMD ["/bin/bash"]
