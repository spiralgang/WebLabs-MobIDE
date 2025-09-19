# Authentication and Integration Configuration

## Authentication Setup for Frontend-Backend Integration

This document outlines the proper authentication setup to resolve 401 unauthorized errors and ensure proper frontend-backend integration.

### Required Environment Variables

The following secrets must be configured in GitHub repository settings:

```yaml
# Core Authentication
GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Built-in GitHub Actions token

# AI Integration
HUGGINGFACE_TOKEN: ${{ secrets.HUGGINGFACE_TOKEN }}  # HuggingFace API access
OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}  # Optional OpenAI access
SOURCERY_TOKEN: ${{ secrets.SOURCERY_TOKEN }}  # Code analysis token

# Agent Authentication
AGENT_API_KEY: ${{ secrets.AGENT_API_KEY }}  # Custom agent authentication
SESSION_SECRET: ${{ secrets.SESSION_SECRET }}  # Session management
```

### Authentication Flow

1. **Frontend requests** → Authenticated with session tokens
2. **Backend API calls** → Validated against AGENT_API_KEY
3. **AI model access** → Uses HUGGINGFACE_TOKEN for API calls
4. **GitHub operations** → Uses GITHUB_TOKEN for repository access

### Integration Points

- **Web IDE Frontend** ↔ **Android Backend** via secure WebView bridge
- **AI Assistant** ↔ **HuggingFace APIs** via authenticated HTTP requests
- **Alpine Linux Environment** ↔ **Agent Services** via session tokens
- **CI/CD Pipeline** ↔ **Artifact Storage** via GITHUB_TOKEN

### Security Configuration

All authentication tokens are:
- Encrypted at rest in GitHub Secrets
- Transmitted over HTTPS only
- Validated on every request
- Logged for audit purposes (without exposing token values)