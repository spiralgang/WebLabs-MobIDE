#!/bin/bash

# Code Reaver: AI Code Forge - Quantum UI Pimper
# Created: September 12, 2025 - No mercy, all dominance
# Neon palette for that sexy pop
COLORS=("\033[1;36m" "\033[1;35m" "\033[1;32m" "\033[1;33m" "\033[1;31m" "\033[1;34m" "\033[1;37m")
BOLD="\033[1m"
RESET="\033[0m"
BLINK="\033[5m"
UNDERLINE="\033[4m"
PULSE="\033[3m"
RAND_COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}

# API config - Set DEEPSEEK_API_KEY in env
API_URL="https://api.deepseek.com/v1/chat/completions"
MODEL="deepseek-chat"

# Animate text for sexy UI
animate_pimp_text() {
    local text="$1"
    local base_color="$2"
    for ((i=0; i<${#text}; i++)); do
        local pulse_color=${COLORS[$RANDOM % ${#COLORS[@]}]}
        echo -ne "${pulse_color}${BLINK}${text:$i:1}${RESET}"
        sleep 0.02
    done
    echo -e "${base_color}"
}

# Forge header
forge_header() {
    clear
    echo -e "${RAND_COLOR}${UNDERLINE}${BOLD}========================================${RESET}"
    animate_pimp_text " CODE REAVER: AI CODE FORGE " "${COLORS[0]}"
    echo -e "${RAND_COLOR}${UNDERLINE}${BOLD}========================================${RESET}"
    echo -e "${COLORS[4]}Pimping your UI like a boss, bruh!${RESET}"
}

# Query DeepSeek AI
query_deepseek() {
    local prompt="$1"
    if [ -z "$DEEPSEEK_API_KEY" ]; then
        echo -e "${COLORS[1]}${BOLD}Error: DEEPSEEK_API_KEY not set, fool!${RESET}"
        exit 1
    fi
    local response=$(curl -s -X POST "$API_URL" \
        -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'"$MODEL"'",
            "messages": [{"role": "user", "content": "'"$prompt"'"}],
            "temperature": 0.7,
            "max_tokens": 2048
        }')
    local code=$(echo "$response" | grep -oP '(?<=content": ")[^"]+' | sed 's/\\n/\n/g' | sed 's/\\"/"/g' | sed 's/\\\\/\\/g')
    echo "$code"
}

# Generate file
generate_file() {
    local file="$1"
    local description="$2"
    forge_header
    echo -e "${COLORS[2]}${BOLD}Generating $file with: $description${RESET}"
    local prompt="Generate code for $description. Output only the code, no explanations."
    local code=$(query_deepseek "$prompt")
    if [ -n "$code" ]; then
        echo "$code" > "$file"
        echo -e "${COLORS[3]}${BOLD}File $file pimped out and generated!${RESET}"
    else
        echo -e "${COLORS[1]}${BOLD}Generation failed, bruh!${RESET}"
    fi
}

# Refactor file
refactor_file() {
    local file="$1"
    local instructions="$2"
    forge_header
    echo -e "${COLORS[2]}${BOLD}Refactoring $file with: $instructions${RESET}"
    if [ ! -f "$file" ]; then
        echo -e "${COLORS[1]}${BOLD}File $file not found, fool!${RESET}"
        exit 1
    fi
    local existing_code=$(cat "$file")
    local prompt="Refactor this code: \n$existing_code\nAccording to these instructions: $instructions. Output only the refactored code."
    local new_code=$(query_deepseek "$prompt")
    if [ -n "$new_code" ]; then
        echo "$new_code" > "$file"
        echo -e "${COLORS[3]}${BOLD}File $file refactored and pimped!${RESET}"
    else
        echo -e "${COLORS[1]}${BOLD}Refactor failed, bruh!${RESET}"
    fi
}

# Main logic
case "$1" in
    generate)
        if [ $# -lt 3 ]; then
            echo -e "${COLORS[1]}${BOLD}Usage: forge generate <file> <description>${RESET}"
            exit 1
        fi
        generate_file "$2" "${*:3}"
        ;;
    refactor)
        if [ $# -lt 3 ]; then
            echo -e "${COLORS[1]}${BOLD}Usage: forge refactor <file> <instructions>${RESET}"
            exit 1
        fi
        refactor_file "$2" "${*:3}"
        ;;
    *)
        forge_header
        echo -e "${COLORS[1]}${BOLD}Unknown command, bruh! Use 'forge generate <file> <description>' or 'forge refactor <file> <instructions>'${RESET}"
        ;;
esac
