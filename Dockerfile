# WebLabs-MobIDE Docker Environment
# Ubuntu 24.04 ARM64 Development Environment for GitHub Copilot Compatibility
# Replaces Alpine Linux proot setup with standard glibc-based environment

FROM ubuntu:24.04

# Set up environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
ENV DEBIAN_FRONTEND=noninteractive

# Install core tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    wget \
    ca-certificates \
    openjdk-17-jdk \
    nodejs \
    npm \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libssl-dev \
    libffi-dev \
    python3-dev \
    nano \
    vim \
    htop \
    tree \
    bash-completion \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create Android SDK directory and install command line tools
RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && cd /tmp \
    && curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip commandlinetools.zip \
    && mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm commandlinetools.zip

# Install Android SDK components
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses \
    && $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "platform-tools" \
        "ndk;25.2.9519653"

# Install web-based IDE (Code-Server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Python AI/ML packages for development
RUN pip3 install --no-cache-dir \
    transformers \
    torch \
    torchvision \
    huggingface_hub \
    accelerate \
    safetensors \
    kagglehub \
    numpy \
    flask \
    fastapi \
    uvicorn

# Create developer user and workspace
RUN useradd -m -s /bin/bash developer \
    && mkdir -p /home/developer/workspace \
    && mkdir -p /home/developer/ai \
    && mkdir -p /home/developer/projects \
    && chown -R developer:developer /home/developer

# Copy toolkit scripts
COPY scripts/docker/ /usr/local/bin/
COPY app/src/main/assets/scripts/start-ide.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Set up developer environment
USER developer
WORKDIR /home/developer/workspace

# Create .bashrc for development environment
RUN echo '# WebLabs-MobIDE Development Environment' > ~/.bashrc \
    && echo 'export PS1="\[\033[01;32m\]developer@ubuntu-arm64\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc \
    && echo 'export EDITOR=nano' >> ~/.bashrc \
    && echo 'export PYTHONDONTWRITEBYTECODE=1' >> ~/.bashrc \
    && echo 'export PYTHONUNBUFFERED=1' >> ~/.bashrc \
    && echo 'alias ll="ls -alF"' >> ~/.bashrc \
    && echo 'alias la="ls -A"' >> ~/.bashrc \
    && echo 'alias l="ls -CF"' >> ~/.bashrc \
    && echo 'alias python=python3' >> ~/.bashrc \
    && echo 'alias pip=pip3' >> ~/.bashrc \
    && echo 'echo "🚀 WebLabs-MobIDE Ubuntu Development Environment Ready!"' >> ~/.bashrc

# Expose IDE port
EXPOSE 8080

# Command to start the web IDE
CMD ["/usr/local/bin/start-ide.sh"]