#!/usr/bin/env bash

# Arch Linux - Ollama MCP Bridge WebUI installation script
# Based on https://github.com/Rkm1999/Ollama-MCP-Bridge-WebUI

printf "\e[36m[%s]: Arch Linux - Ollama MCP Bridge WebUI installation script started.\e[0m\n" "$0"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Prerequisites ---
printf "\n\e[34mChecking prerequisites...\e[0m\n"

# 1. Install Git, Node.js, and npm if not present
if ! command_exists git || ! command_exists node || ! command_exists npm; then
    printf "Git, Node.js, or npm not found. Attempting to install...\n"
    sudo pacman -Syu --noconfirm git nodejs npm
    if [ $? -ne 0 ]; then 
        printf "\e[31mError installing Git, Node.js, or npm. Please install them manually and re-run the script.\e[0m\n"
        exit 1
    fi
    printf "\e[32mGit, Node.js, and npm installed successfully.\e[0m\n"
else
    printf "\e[32mGit, Node.js, and npm are already installed.\e[0m\n"
fi

# 2. Install Ollama if not present
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
printf "\n\e[34mStarting Ollama-MCP-Bridge-WebUI installation...\e[0m\n"

INSTALL_PARENT_DIR="/home/eev/hype" # Parent directory for the clone
REPO_NAME="Ollama-MCP-Bridge-WebUI"
CLONE_DIR="$INSTALL_PARENT_DIR/$REPO_NAME"
WORKSPACE_DIR="$INSTALL_PARENT_DIR/workspace" # As per ../workspace relative to the repo

# 3. Clone the repository
if [ -d "$CLONE_DIR" ]; then
    printf "\e[33mDirectory $CLONE_DIR already exists. Skipping clone.\e[0m\n"
    printf "If you want a fresh clone, please remove it first: rm -rf $CLONE_DIR\n"
else
    printf "Cloning Ollama-MCP-Bridge-WebUI repository into $CLONE_DIR...\n"
    git clone https://github.com/Rkm1999/Ollama-MCP-Bridge-WebUI.git "$CLONE_DIR"
    if [ $? -ne 0 ]; then
        printf "\e[31mError cloning the repository. Exiting.\e[0m\n"
        exit 1
    fi
    printf "\e[32mRepository cloned successfully.\e[0m\n"
fi

# Change to the repository directory
cd "$CLONE_DIR" || { printf "\e[31mFailed to cd into $CLONE_DIR. Exiting.\e[0m\n"; exit 1; }
printf "Changed directory to $(pwd)\n"

# 4. Install dependencies
printf "Installing dependencies using npm...\n"
npm install
if [ $? -ne 0 ]; then
    printf "\e[31mError installing npm dependencies. Exiting.\e[0m\n"
    exit 1
fi
printf "\e[32mNpm dependencies installed successfully.\e[0m\n"

# 5. Create the workspace directory
printf "Creating workspace directory at $WORKSPACE_DIR...\n"
mkdir -p "$WORKSPACE_DIR"
if [ $? -ne 0 ]; then
    printf "\e[33mWarning: Could not create workspace directory $WORKSPACE_DIR. Please check permissions.\e[0m\n"
else
    printf "\e[32mWorkspace directory $WORKSPACE_DIR created/ensured.\e[0m\n"
fi

# 6. Build the project
printf "Building the TypeScript project...\n"
npm run build
if [ $? -ne 0 ]; then
    printf "\e[31mError building the project. Exiting.\e[0m\n"
    exit 1
fi
printf "\e[32mProject built successfully.\e[0m\n"


# --- Post-installation ---
printf "\n\e[34mPost-installation steps:\e[0m\n"

printf "\e[33mIMPORTANT: You need to configure API keys in \e[36m$CLONE_DIR/.env\e[0m\e[33m.\e[0m\n"
printf "   Example for Brave Search: \e[35mBRAVE_API_KEY=your_brave_key_here\e[0m\n"

CONFIG_FILE="$CLONE_DIR/bridge_config.json"
printf "\nReview and update \e[36m$CONFIG_FILE\e[0m if necessary.\n"
if [ -f "$CONFIG_FILE" ]; then
    printf "Attempting to update placeholder paths in $CONFIG_FILE...\n"
    ESCAPED_CLONE_DIR=$(printf '%s\n' "$CLONE_DIR" | sed 's:[][\\/.^$*]:\\&:g')
    ESCAPED_WORKSPACE_DIR=$(printf '%s\n' "$WORKSPACE_DIR" | sed 's:[][\\/.^$*]:\\&:g')

    sed -i "s|To/Your/Directory/Ollama-MCP-Bridge-WebUI|$ESCAPED_CLONE_DIR|g" "$CONFIG_FILE"
    sed -i "s|To/Your/Directory/Ollama-MCP-Bridge-WebUI/../workspace|$ESCAPED_WORKSPACE_DIR|g" "$CONFIG_FILE"
    printf "\e[32mPaths in $CONFIG_FILE potentially updated. Please verify its contents carefully.\e[0m\n"
else
    printf "\e[33m$CONFIG_FILE not found. You may need to create it from a template or copy it manually.\e[0m\n"
    printf "  Ensure 'allowedDirectory' for the filesystem server points to \e[36m$WORKSPACE_DIR\e[0m\n"
    printf "  Ensure other paths for MCP servers point correctly within \e[36m$CLONE_DIR\e[0m\n"
fi

printf "\n\e[34mTo start the Ollama-MCP-Bridge-WebUI:\e[0m\n"
printf "1. Navigate to the installation directory: \e[36mcd $CLONE_DIR\e[0m\n"
printf "2. Run: \e[32mnpm start\e[0m (or check project for specific start command if this fails)\n"
printf "3. Access the web interface, typically at \e[36mhttp://localhost:8080\e[0m (or as shown in console output).\n"

printf "\n\e[32m[%s]: Arch Linux - Ollama MCP Bridge WebUI installation script finished.\e[0m\n" "$0"
printf "\e[33mPlease complete any manual configuration (API keys, verify bridge_config.json) as instructed above.\e[0m\n"

exit 0