#!/bin/bash

# Script to install ollama-mcp-bridge and its dependencies

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Installing MCP servers..."

# Install MCP servers globally
if ! npm install -g @modelcontextprotocol/server-filesystem; then
    echo "Failed to install @modelcontextprotocol/server-filesystem"
    exit 1
fi

if ! npm install -g @modelcontextprotocol/server-brave-search; then
    echo "Failed to install @modelcontextprotocol/server-brave-search"
    exit 1
fi

if ! npm install -g @modelcontextprotocol/server-github; then
    echo "Failed to install @modelcontextprotocol/server-github"
    exit 1
fi

if ! npm install -g @modelcontextprotocol/server-memory; then
    echo "Failed to install @modelcontextprotocol/server-memory"
    exit 1
fi

if ! npm install -g @patruff/server-flux; then
    echo "Failed to install @patruff/server-flux"
    exit 1
fi

if ! npm install -g @patruff/server-gmail-drive; then
    echo "Failed to install @patruff/server-gmail-drive"
    exit 1
fi

echo "MCP servers installed successfully."

# Clone the ollama-mcp-bridge repository
BRIDGE_DIR="$HOME/ollama-mcp-bridge"
if [ -d "$BRIDGE_DIR" ]; then
    echo "ollama-mcp-bridge directory already exists. Pulling latest changes..."
    cd "$BRIDGE_DIR"
    git pull
else
    echo "Cloning ollama-mcp-bridge repository..."
    if ! git clone https://github.com/patruff/ollama-mcp-bridge.git "$BRIDGE_DIR"; then
        echo "Failed to clone ollama-mcp-bridge repository"
        exit 1
    fi
    cd "$BRIDGE_DIR"
fi

# Install dependencies for ollama-mcp-bridge
echo "Installing dependencies for ollama-mcp-bridge..."
if ! npm install; then
    echo "Failed to install npm dependencies for ollama-mcp-bridge"
    exit 1
fi

# Create a basic bridge_config.json if it doesn't exist
CONFIG_FILE="$BRIDGE_DIR/bridge_config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating basic bridge_config.json..."
    cat << EOF > "$CONFIG_FILE"
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["$(npm root -g)/@modelcontextprotocol/server-filesystem/dist/index.js"],
      "allowedDirectory": "$HOME/ollama-mcp-bridge-workspace" 
    },
    "brave_search": {
      "command": "node",
      "args": ["$(npm root -g)/@modelcontextprotocol/server-brave-search/dist/index.js"]
    },
    "github": {
      "command": "node",
      "args": ["$(npm root -g)/@modelcontextprotocol/server-github/dist/index.js"]
    },
    "memory": {
      "command": "node",
      "args": ["$(npm root -g)/@modelcontextprotocol/server-memory/dist/index.js"]
    },
    "flux": {
      "command": "node",
      "args": ["$(npm root -g)/@patruff/server-flux/dist/index.js"]
    },
    "gmail_drive": {
      "command": "node",
      "args": ["$(npm root -g)/@patruff/server-gmail-drive/dist/index.js"]
    }
  },
  "llm": {
    "model": "qwen2.5-coder:7b-instruct",
    "baseUrl": "http://localhost:11434"
  }
}
EOF
    # Create the allowed directory for filesystem MCP
    mkdir -p "$HOME/ollama-mcp-bridge-workspace"
    echo "Basic bridge_config.json created."
    echo "Please ensure you have the 'qwen2.5-coder:7b-instruct' model pulled with Ollama."
    echo "You may need to configure API keys (BRAVE_API_KEY, GITHUB_PERSONAL_ACCESS_TOKEN, REPLICATE_API_TOKEN) and run auth for Gmail/Drive MCPs."
else
    echo "bridge_config.json already exists."
fi

# Make the main script executable if it exists (assuming it's in the cloned repo)
if [ -f "$BRIDGE_DIR/dist/index.js" ]; then # Assuming the main script is index.js in dist after build
    # The repo seems to be a typescript project, it might need a build step like `npm run build`
    # For now, let's assume `npm install` handles any necessary build steps or the user runs it manually.
    echo "Attempting to build ollama-mcp-bridge..."
    if npm run build; then
      echo "ollama-mcp-bridge built successfully."
    else
      echo "Build command 'npm run build' might have failed or is not available. Check package.json."
      echo "The main script might be at src/index.ts and needs to be compiled."
    fi
fi


echo "ollama-mcp-bridge installation script finished."

# Set execute permissions for this script
chmod +x "$0"