# requirements.txt
aiohttp>=3.8.0
asyncio-mqtt>=0.11.0
pathlib2>=2.3.7
dataclasses>=0.6
concurrent-futures>=3.1.1

# setup.sh
#!/bin/bash
set -e

echo "🚀 Setting up Unstoppable AI Development Environment"

# Check Python version
python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "❌ Python 3.8+ required, found $python_version"
    exit 1
fi

echo "✅ Python version check passed"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install --upgrade pip
pip3 install -r requirements.txt

# Check if Ollama is running
echo "🔍 Checking Ollama status..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama is running"
else
    echo "❌ Ollama is not running. Please start Ollama first:"
    echo "   ollama serve"
    exit 1
fi

# Verify models are available
echo "🤖 Checking AI models..."
models=("phi:latest" "qwen:latest" "deepseek-coder:latest")

for model in "${models[@]}"; do
    if ollama list | grep -q "${model%:*}"; then
        echo "✅ Found $model"
    else
        echo "⚠️  Model $model not found. Installing..."
        ollama pull "$model"
        echo "✅ Installed $model"
    fi
done

# Make the main script executable
chmod +x ai_dev_system.py

# Create initial project structure if needed
mkdir -p logs
mkdir -p backups
mkdir -p generated

echo "🎉 Setup complete! Run with:"
echo "   python3 ai_dev_system.py"
echo ""
echo "Available commands in interactive mode:"
echo "   analyze    - Analyze current project"
echo "   setup      - Auto-setup project dependencies"
echo "   generate   - Generate files with AI"
echo "   refactor   - Refactor existing code"
echo "   exec       - Execute commands with retry logic"
echo "   ask        - Query all AI models"
echo ""
echo "Example usage:"
echo "   generate main.py 'Create a FastAPI server with user authentication'"
echo "   refactor app.py 'Add error handling and logging'"
echo "   exec 'pip install -r requirements.txt'"

# Quick test
echo "🧪 Running quick test..."
python3 -c "
import aiohttp
import asyncio
print('✅ Dependencies working')

async def test_ollama():
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get('http://localhost:11434/api/tags') as response:
                if response.status == 200:
                    print('✅ Ollama API accessible')
                else:
                    print('❌ Ollama API error')
    except Exception as e:
        print(f'❌ Ollama connection failed: {e}')

asyncio.run(test_ollama())
"

echo ""
echo "🚀 Ready to rock! Your AI development environment is unleashed."
