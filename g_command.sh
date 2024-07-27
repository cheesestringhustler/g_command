g_command() {
    if [ $# -eq 0 ]; then
        echo "Usage: g [prompt]" >&2
        return 1
    fi

    local prompt="$*"

    system_prompt=$(cat <<EOF | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}'
You are a helpful assistant that generates console commands. 
The user's system information is: $os_info
The system architecture is: $arch
Based on this information and the user's prompt, generate an appropriate console command.
Provide only the command itself, without any explanation or markdown formatting.
EOF
)

    api_request=$(cat <<EOF
{
    "model": "llama3.1",
    "prompt": "${system_prompt}\\n\\nUser: ${prompt}\\nAssistant:",
    "stream": true
}
EOF
)

    # Print the prompt part
    printf "$(whoami)@$(hostname) ~ %% "

    local generated_command=""
    if ! curl -s -X POST http://${OLLAMA_HOST}/api/generate -d "$api_request" | while read -r line; do
        if [[ $line == *"response"* ]]; then
            local response=$(echo "$line" | jq -r '.response')
            printf "%s" "$response"
            generated_command+="$response"
        fi
    done; then
        echo "Error: API is not responsive" >&2
        return 1
    fi

    if [ -z "$generated_command" ]; then
        echo "Error: No command was generated" >&2
        return 1
    fi

    read -r
    eval "$generated_command"
}

# If the script is sourced, don't execute g_command
if [[ "${(%):-%x}" != "${(%):-%N}" ]]; then
    return 0
fi

# If the script is executed directly, run g_command with arguments
g_command "$@"
