#!/usr/bin/env bash

# Fedora - Ollama MCP Bridge (patruff/ollama-mcp-bridge) installation script
# Based on https://github.com/patruff/ollama-mcp-bridge

printf "\e[36m[%s]: Fedora - Ollama MCP Bridge (patruff) installation script started.\e[0m\n" "$0"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Configuration ---
INSTALL_PARENT_DIR="$HOME/hype" # Parent directory for projects
REPO_NAME="ollama-mcp-bridge" # Cloned repository name
CLONE_DIR="$INSTALL_PARENT_DIR/$REPO_NAME"
WORKSPACE_DIR="$INSTALL_PARENT_DIR/workspace" # General workspace directory
LLM_MODEL="qwen3:0.5b"

# --- Prerequisites ---
printf "\n\e[34mChecking prerequisites...\e[0m\n"

# 1. Install Git, Node.js, and npm if not present
if ! command_exists git || ! command_exists node || ! command_exists npm; then
    printf "Git, Node.js, or npm not found. Attempting to install using sudo...\n"
    printf "You may be prompted for your password.\n"
    sudo dnf install -y git nodejs npm # Fedora uses dnf
    if [ $? -ne 0 ]; then 
        printf "\e[31mError installing Git, Node.js, or npm. Please install them manually and re-run the script.\e[0m\n"
        exit 1
    fi
    printf "\e[32mGit, Node.js, and npm installed successfully.\e[0m\n"
else
    printf "\e[32mGit, Node.js, and npm are already installed.\e[0m\n"
fi

# 2. Check for Ollama
if ! command_exists ollama; then
    printf "Ollama not found.\n"
    printf "Please install Ollama manually from \e[36mhttps://ollama.com/download\e[0m\n"
    printf "After installation, ensure the Ollama service is running.\n"
    read -r -p "Have you installed Ollama and is it running? (yes/no): " ollama_installed_reply
    if [[ "$ollama_installed_reply" != "yes" ]]; then
        printf "\e[31mOllama installation is required to proceed. Exiting.\e[0m\n"
        exit 1
    fi
    # Verify again
    if ! command_exists ollama; then
        printf "\e[31mOllama command still not found. Please ensure it's installed and in your PATH. Exiting.\e[0m\n"
        exit 1
    fi
    printf "\e[32mOllama detected.\e[0m\n"
else
    printf "\e[32mOllama is already installed.\e[0m\n"
fi

# --- Installation Steps ---
printf "\n\e[34mStarting Ollama-MCP-Bridge (patruff) installation...\e[0m\n"

# 3. Clone the repository
if [ -d "$CLONE_DIR" ]; then
    printf "\e[33mDirectory $CLONE_DIR already exists. Skipping clone.\e[0m\n"
    printf "If you want a fresh clone, please remove it first: rm -rf $CLONE_DIR\n"
else
    printf "Cloning patruff/ollama-mcp-bridge repository into $CLONE_DIR...\n"
    git clone https://github.com/patruff/ollama-mcp-bridge.git "$CLONE_DIR"
    if [ $? -ne 0 ]; then
        printf "\e[31mError cloning the repository. Exiting.\e[0m\n"
        exit 1
    fi
    printf "\e[32mRepository cloned successfully.\e[0m\n"
fi

# Change to the repository directory
cd "$CLONE_DIR" || { printf "\e[31mFailed to cd into $CLONE_DIR. Exiting.\e[0m\n"; exit 1; }
printf "Changed directory to $(pwd)\n"

# 4. Install bridge dependencies
printf "Installing bridge dependencies using npm...\n"
npm install
if [ $? -ne 0 ]; then
    printf "\e[31mError installing npm dependencies for the bridge. Exiting.\e[0m\n"
    exit 1
fi
printf "\e[32mBridge npm dependencies installed successfully.\e[0m\n"

# 5. Install MCP Servers globally
printf "\n\e[34mInstalling MCP Servers globally using npm...\e[0m\n"
MCP_SERVERS=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-brave-search"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-memory"
    "@patruff/server-flux"
    "@patruff/server-gmail-drive"
)

for server_pkg in "${MCP_SERVERS[@]}"; do
    printf "Installing $server_pkg...\n"
    sudo npm install -g "$server_pkg"
    if [ $? -ne 0 ]; then
        printf "\e[33mWarning: Failed to install $server_pkg. Please install it manually and ensure it's in your PATH.\e[0m\n"
    else
        printf "\e[32m$server_pkg installed successfully.\e[0m\n"
    fi
done

# 6. Create the workspace directory
printf "\nCreating workspace directory at $WORKSPACE_DIR...\n"
mkdir -p "$WORKSPACE_DIR"
if [ $? -ne 0 ]; then
    printf "\e[33mWarning: Could not create workspace directory $WORKSPACE_DIR. Please check permissions.\e[0m\n"
else
    printf "\e[32mWorkspace directory $WORKSPACE_DIR created/ensured.\e[0m\n"
fi

# 7. Create bridge_config.json
CONFIG_FILE="$CLONE_DIR/bridge_config.json"
printf "\n\e[34mCreating $CONFIG_FILE...\e[0m\n"

# Escape paths for JSON
ESCAPED_WORKSPACE_DIR=$(printf '%s' "$WORKSPACE_DIR" | sed 's/[&\/]/\\&/g')

cat > "$CONFIG_FILE" << EOL
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["$(npm bin -g)/server-filesystem"],
      "allowedDirectory": "$ESCAPED_WORKSPACE_DIR"
    },
    "brave-search": {
      "command": "node",
      "args": ["$(npm bin -g)/server-brave-search"]
    },
    "github": {
      "command": "node",
      "args": ["$(npm bin -g)/server-github"]
    },
    "memory": {
      "command": "node",
      "args": ["$(npm bin -g)/server-memory"]
    },
    "flux": {
      "command": "node",
      "args": ["$(npm bin -g)/server-flux"]
    },
    "gmail-drive": {
      "command": "node",
      "args": ["$(npm bin -g)/server-gmail-drive"]
    }
  },
  "llm": {
    "model": "$LLM_MODEL",
    "baseUrl": "http://localhost:11434"
  }
}
EOL

if [ -f "$CONFIG_FILE" ]; then
    printf "\e[32m$CONFIG_FILE created successfully.\e[0m\n"
    printf "\e[33mPlease review $CONFIG_FILE and update server paths in 'args' if 'npm bin -g' does not point to the correct executables.\e[0m\n"
else
    printf "\e[31mError: Failed to create $CONFIG_FILE. Please create it manually.\e[0m\n"
fi

# --- Post-installation --- 
printf "\n\e[34mPost-installation steps:\e[0m\n"

printf "\e[33mIMPORTANT: Configure API keys and OAuth:\e[0m\n"
printf "1. Set \e[35mBRAVE_API_KEY\e[0m environment variable for Brave Search.\n"
printf "2. Set \e[35mGITHUB_PERSONAL_ACCESS_TOKEN\e[0m environment variable for GitHub.\n"
printf "3. Set \e[35mREPLICATE_API_TOKEN\e[0m environment variable for Flux image generation.\n"
printf "4. Run Gmail/Drive MCP authentication: \e[36mnode $(npm bin -g)/server-gmail-drive auth\e[0m\n"
printf "   (Adjust path if needed, e.g., \e[36mnode path/to/your/global/node_modules/@patruff/server-gmail-drive/dist/index.js auth\e[0m)\n"

# --- Start the bridge automatically ---
printf "\n\e[34mAttempting to start Ollama-MCP-Bridge in the background...\e[0m\n"

if [ -d "$CLONE_DIR" ]; then
    # Store current directory to return if needed, though this is the end of the script.
    current_dir_before_start=$(pwd)
    cd "$CLONE_DIR" || {
        printf "\e[31mError: Failed to cd into %s to start the bridge.\e[0m\n" "$CLONE_DIR"
        printf "You may need to start it manually: \e[36mcd %s && npm run start\e[0m\n" "$CLONE_DIR"
    }

    # Proceed only if cd was successful
    if [ "$(pwd)" = "$CLONE_DIR" ]; then
        LOG_FILE="$CLONE_DIR/ollama_mcp_bridge_auto_start.log"
        printf "Starting 'npm run start' in the background. Output will be logged to: \e[36m%s\e[0m\n" "$LOG_FILE"
        
        nohup npm run start > "$LOG_FILE" 2>&1 &
        NOHUP_PID=$!

        printf "Waiting a few seconds for the bridge to initialize...\n"
        sleep 5 

        if ps -p $NOHUP_PID > /dev/null; then
            printf "\e[32mOllama-MCP-Bridge appears to have started successfully in the background (PID: %s).\e[0m\n" "$NOHUP_PID"
            printf "You can view the logs with: \e[36mtail -f %s\e[0m\n" "$LOG_FILE"
            printf "To stop this instance of the bridge, you can use: \e[36mkill %s\e[0m\n" "$NOHUP_PID"
            printf "Alternatively, find the process with 'pgrep -f "npm run start.*ollama-mcp-bridge"' or similar and kill it.\n"
        else
            printf "\e[31mFailed to start Ollama-MCP-Bridge in the background, or it exited quickly.\e[0m\n"
            printf "Please check the log file for errors: \e[36m%s\e[0m\n" "$LOG_FILE"
            printf "You may need to start it manually: \e[36mcd %s && npm run start\e[0m\n" "$CLONE_DIR"
        fi
        
        # Optionally cd back if this wasn't the end of the script
        # cd "$current_dir_before_start" || printf "\e[33mWarning: could not cd back to %s\e[0m\n" "$current_dir_before_start"
    else
        # This handles the case where cd failed and the inner error message was printed.
        printf "\e[31mError: Not in %s. Cannot start the bridge automatically.\e[0m\n" "$CLONE_DIR"
        printf "You may need to start it manually: \e[36mcd %s && npm run start\e[0m\n" "$CLONE_DIR"
    fi
else
    printf "\e[31mInstallation directory %s not found. Cannot start the bridge automatically.\e[0m\n" "$CLONE_DIR"
fi

printf "\n\e[32m[%s]: Fedora - Ollama MCP Bridge (patruff) installation script finished.\e[0m\n" "$0"
printf "\e[33mPlease complete API key configuration and OAuth setup as instructed above if you haven't already.\e[0m\n"

exit 0