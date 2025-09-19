# WebLabs-MobIDE Workspace

This directory contains the development workspace for the Docker-based Ubuntu environment.

## Structure

- `projects/` - User-created development projects
- `ai/models/` - AI model cache and downloads  
- `ai/cache/` - AI processing cache
- `logs/` - Development environment logs

## Usage

When the Docker container is running, this workspace is mounted to `/home/developer/workspace` inside the container.

Access the web-based IDE at: http://localhost:8080

## Docker Environment

The WebLabs-MobIDE APK now uses a Docker-based Ubuntu 24.04 ARM64 environment instead of Alpine Linux proot for:

- ✅ Better GitHub Copilot compatibility
- ✅ Standard glibc environment  
- ✅ Native Docker performance
- ✅ Code-Server web IDE
- ✅ Production-grade development tools

## Features

- 🐳 **Ubuntu 24.04 ARM64** - Standard Linux environment
- ⚡ **Code-Server IDE** - Full VS Code experience in browser
- 🤖 **AI Integration** - HuggingFace models and local inference
- 📱 **Mobile Optimized** - Touch-friendly interface
- 🛠️ **Development Tools** - Android SDK, NDK, Python, Node.js, build tools