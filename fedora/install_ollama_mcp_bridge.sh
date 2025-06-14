#!/usr/bin/env bash

# Fedora - Ollama MCP Bridge (patruff/ollama-mcp-bridge) installation script
# Based on https://github.com/patruff/ollama-mcp-bridge

printf "\e[36m[%s]: Fedora - Ollama MCP Bridge (patruff) installation script started.\e[0m\n" "$0"

# IMPORTANT: This script should NOT be run with sudo directly.
# It will call sudo internally for specific commands (dnf, npm install -g) when needed.
if [ "$(id -u)" -eq 0 ]; then
  printf "\e[31mError: This script should not be run as root or with sudo directly.\e[0m\n"
  printf "Please run it as a normal user. Sudo will be invoked for specific commands as needed.\n"
  exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Configuration ---
INSTALL_PARENT_DIR="$HOME/hype" # Parent directory for projects
REPO_NAME="ollama-mcp-bridge" # Cloned repository name
CLONE_DIR="$INSTALL_PARENT_DIR/$REPO_NAME"
WORKSPACE_DIR="$HOME/mcp-workspace" # General workspace directory
LLM_MODEL="qwen3:0.5b"

# --- Prerequisites ---
printf "\n\e[34mChecking prerequisites...\e[0m\n"

# 1. Check for Git, Node.js, and npm
missing_prereqs=()
if ! command_exists git; then missing_prereqs+=("git"); fi
if ! command_exists node; then missing_prereqs+=("Node.js (node executable)"); fi
if ! command_exists npm; then missing_prereqs+=("npm"); fi

if [ ${#missing_prereqs[@]} -ne 0 ]; then
    printf "\e[31mError: The following prerequisites are not found:\e[0m\n"
    for item in "${missing_prereqs[@]}"; do
        printf "  - %s\n" "$item"
    done
    printf "Please install them manually. For Fedora, you can typically use:\n"
    printf "  \e[36msudo dnf install -y git nodejs npm\e[0m\n"
    printf "After installation, please re-run this script.\n"
    exit 1
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

# 3. Clone/Update the repository
EXPECTED_REPO_URL="https://github.com/patruff/ollama-mcp-bridge.git"
REPO_SHOULD_BE_CLONED=false

if [ -d "$CLONE_DIR" ]; then
    printf "\e[33mDirectory $CLONE_DIR already exists. Checking its content...\e[0m\n"
    if [ -d "$CLONE_DIR/.git" ]; then
        # Temporarily change to CLONE_DIR to run git command, then change back
        CURRENT_REPO_URL=$( (cd "$CLONE_DIR" && git config --get remote.origin.url) || echo "ERROR_GETTING_URL" )

        if [ "$CURRENT_REPO_URL" = "$EXPECTED_REPO_URL" ]; then
            printf "\e[32mCorrect repository found in $CLONE_DIR.\e[0m\n"
            printf "Attempting to forcefully reset and update the repository to match remote 'main'...\n"
            (
                cd "$CLONE_DIR" || { printf "\e[31mFailed to cd into $CLONE_DIR for update. Exiting from subshell.\e[0m\n"; exit 1; }
                git fetch origin
                if [ $? -ne 0 ]; then
                    printf "\e[33mWarning: 'git fetch origin' failed. Continuing with existing local version.\e[0m\n"
                else
                    git reset --hard origin/main
                    if [ $? -ne 0 ]; then
                        printf "\e[33mWarning: 'git reset --hard origin/main' failed. Continuing with existing local version.\e[0m\n"
                    else
                        git clean -fdx
                        if [ $? -ne 0 ]; then
                            printf "\e[33mWarning: 'git clean -fdx' failed. Some untracked files may remain.\e[0m\n"
                        fi
                        git checkout main # Ensure we are on main branch
                        git pull origin main # Pull specifically from origin main
                        if [ $? -ne 0 ]; then
                            printf "\e[33mWarning: 'git pull origin main' after reset/clean failed. Continuing with existing local version.\e[0m\n"
                        else
                            printf "\e[32mRepository forcefully reset and updated successfully.\e[0m\n"
                        fi
                    fi
                fi
            )
        elif [ "$CURRENT_REPO_URL" = "ERROR_GETTING_URL" ]; then
            printf "\e[31mError: Could not get remote URL from $CLONE_DIR. It might be corrupted or not a git repo in the expected state.\e[0m\n"
            printf "Removing existing directory %s...\n" "$CLONE_DIR"
            if rm -rf "$CLONE_DIR"; then
                printf "\e[32mSuccessfully removed %s.\e[0m\n" "$CLONE_DIR"
                REPO_SHOULD_BE_CLONED=true
            else
                printf "\e[31mError: Failed to remove $CLONE_DIR. Please remove it manually and re-run. Exiting.\e[0m\n"
                exit 1
            fi
        else
            printf "\e[31mError: Directory $CLONE_DIR exists but contains the wrong repository.\e[0m\n"
            printf "  Expected: %s\n" "$EXPECTED_REPO_URL"
            printf "  Found:    %s\n" "$CURRENT_REPO_URL"
            printf "Removing existing directory %s...\n" "$CLONE_DIR"
            if rm -rf "$CLONE_DIR"; then
                printf "\e[32mSuccessfully removed %s.\e[0m\n" "$CLONE_DIR"
                REPO_SHOULD_BE_CLONED=true
            else
                printf "\e[31mError: Failed to remove $CLONE_DIR. Please remove it manually and re-run. Exiting.\e[0m\n"
                exit 1
            fi
        fi
    else
        printf "\e[31mError: Directory $CLONE_DIR exists but is not a git repository.\e[0m\n"
        printf "Removing existing directory %s...\n" "$CLONE_DIR"
        if rm -rf "$CLONE_DIR"; then
            printf "\e[32mSuccessfully removed %s.\e[0m\n" "$CLONE_DIR"
            REPO_SHOULD_BE_CLONED=true
        else
            printf "\e[31mError: Failed to remove $CLONE_DIR. Please remove it manually and re-run. Exiting.\e[0m\n"
            exit 1
        fi
    fi
else
    REPO_SHOULD_BE_CLONED=true
fi

if [ "$REPO_SHOULD_BE_CLONED" = true ]; then
    printf "Cloning %s repository into $CLONE_DIR...\n" "$EXPECTED_REPO_URL"
    git clone "$EXPECTED_REPO_URL" "$CLONE_DIR"
    if [ $? -ne 0 ]; then
        printf "\e[31mError cloning the repository. Exiting.\e[0m\n"
        # The backup mechanism has been removed, so no need to check for BACKUP_DIR
        # if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        #      printf "Your original content from the $CLONE_DIR path was backed up to $BACKUP_DIR\n"
        # fi
        exit 1
    fi
    printf "\e[32mRepository cloned successfully.\e[0m\n"
fi

# Change to the repository directory
cd "$CLONE_DIR" || { printf "\e[31mFailed to cd into $CLONE_DIR. Exiting.\e[0m\n"; exit 1; }
printf "Changed directory to $(pwd)\n"

# 4. Install bridge dependencies
printf "Installing bridge dependencies using npm...\n"

# Install dependencies in the cloned repository directory
printf "Installing dependencies in $CLONE_DIR\n"
cd "$CLONE_DIR" || { printf "\e[31mFailed to cd into $CLONE_DIR. Exiting.\e[0m\n"; exit 1; }
npm install
if [ $? -ne 0 ]; then
    printf "\e[31mError installing npm dependencies for the bridge. Exiting.\e[0m\n"
    exit 1
fi
printf "\e[32mBridge npm dependencies installed successfully.\e[0m\n"

# 5. Check for MCP Server executables
printf "\n\e[34mChecking for MCP Server executables...\e[0m\n"

# Attempt to update PATH to include npm global bin directory
NPM_GLOBAL_PREFIX_DETECT=$(npm get prefix -g 2>/dev/null)
if [ -n "$NPM_GLOBAL_PREFIX_DETECT" ]; then
    NPM_GLOBAL_BIN_PATH_DETECT="$NPM_GLOBAL_PREFIX_DETECT/bin"
    if [[ ":$PATH:" != *":$NPM_GLOBAL_BIN_PATH_DETECT:"* ]]; then
        printf "Adding %s to PATH for this script execution\n" "$NPM_GLOBAL_BIN_PATH_DETECT"
        export PATH="$NPM_GLOBAL_BIN_PATH_DETECT:$PATH"
    fi
else
    printf "\e[33mWarning: Could not determine npm global prefix. PATH modification for global executables might be incomplete.\e[0m\n"
fi
# Mapping package names to expected executable names
# Based on actual executable names found in npm global bin directory
declare -A MCP_SERVER_EXEC_MAP
MCP_SERVER_EXEC_MAP["@modelcontextprotocol/server-filesystem"]="mcp-server-filesystem"
MCP_SERVER_EXEC_MAP["@modelcontextprotocol/server-brave-search"]="mcp-server-brave-search"
MCP_SERVER_EXEC_MAP["@modelcontextprotocol/server-github"]="mcp-server-github"
MCP_SERVER_EXEC_MAP["@modelcontextprotocol/server-memory"]="mcp-server-memory"
MCP_SERVER_EXEC_MAP["@patruff/server-flux"]="server-flux"
MCP_SERVER_EXEC_MAP["@patruff/server-gmail-drive"]="server-gmail-drive"

MCP_SERVER_PACKAGES=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-brave-search"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-memory"
    "@patruff/server-flux"
    "@patruff/server-gmail-drive"
)

installation_failed_packages=()
all_servers_found_or_installed=true

for pkg_name in "${MCP_SERVER_PACKAGES[@]}"; do
    exec_name=${MCP_SERVER_EXEC_MAP[$pkg_name]}
    if ! command_exists "$exec_name"; then
        printf "\e[33mMCP Server %s (executable: %s) not found. Attempting to install...\e[0m\n" "$pkg_name" "$exec_name"
        printf "Running: sudo npm install -g %s\n" "$pkg_name"
        if sudo npm install -g "$pkg_name"; then
            printf "\e[32mSuccessfully installed %s.\e[0m\n" "$pkg_name"
            # Re-check npm global bin path and update PATH if necessary, then verify executable
            NPM_GLOBAL_PREFIX_POST_INSTALL=$(npm get prefix -g 2>/dev/null)
            if [ -n "$NPM_GLOBAL_PREFIX_POST_INSTALL" ]; then
                NPM_GLOBAL_BIN_PATH_POST_INSTALL="$NPM_GLOBAL_PREFIX_POST_INSTALL/bin"
                if [[ ":$PATH:" != *":$NPM_GLOBAL_BIN_PATH_POST_INSTALL:"* ]]; then
                    printf "Re-adding %s to PATH post-install for this script execution\n" "$NPM_GLOBAL_BIN_PATH_POST_INSTALL"
                    export PATH="$NPM_GLOBAL_BIN_PATH_POST_INSTALL:$PATH"
                fi
            else
                printf "\e[33mWarning: Could not determine npm global prefix post-install. PATH modification might be incomplete.\e[0m\n"
            fi

            if ! command_exists "$exec_name"; then
                printf "\e[31mError: %s installed, but executable '%s' still not found in PATH.\e[0m\n" "$pkg_name" "$exec_name"
                printf "This might be a PATH issue or the package's 'bin' definition is different.\n"
                printf "Please check your PATH and the package installation.\n"
                installation_failed_packages+=("$pkg_name (executable '$exec_name' not found post-install)")
                all_servers_found_or_installed=false
            else
                 printf "\e[32mExecutable '%s' for %s is now available.\e[0m\n" "$exec_name" "$pkg_name"
            fi
        else
            printf "\e[31mError: Failed to install %s using sudo npm install -g.\e[0m\n" "$pkg_name"
            printf "Please try installing it manually: sudo npm install -g %s\n" "$pkg_name"
            installation_failed_packages+=("$pkg_name (install command failed)")
            all_servers_found_or_installed=false
        fi
    else
        printf "\e[32mFound MCP Server: %s (executable: %s)\e[0m\n" "$pkg_name" "$exec_name"
    fi
done

if [ "$all_servers_found_or_installed" = true ]; then
    printf "\e[32mAll required MCP server executables are installed and found in PATH.\e[0m\n"
else
    printf "\n\e[31mError: Some MCP server packages could not be installed or their executables were not found after installation:\e[0m\n"
    for item in "${installation_failed_packages[@]}"; do
        printf "  - %s\n" "$item"
    done
    printf "Please review the errors above and try to resolve them manually.\n"
    printf "You may need to check your PATH or run 'sudo npm install -g <package_name>' for the failed packages.\n"
    exit 1
fi

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

# Resolve paths for JSON
NODE_EXEC_PATH=$(command -v node)
if [ -z "$NODE_EXEC_PATH" ]; then
    printf "\e[31mError: Node executable not found in PATH. Cannot create bridge_config.json correctly.\e[0m\n"
    # Attempt to find node in common locations if 'command -v node' fails for non-interactive shells
    if [ -x "/usr/bin/node" ]; then NODE_EXEC_PATH="/usr/bin/node"; 
    elif [ -x "/usr/local/bin/node" ]; then NODE_EXEC_PATH="/usr/local/bin/node";
    elif [ -x "$HOME/.nvm/versions/node/$(nvm current 2>/dev/null)/bin/node" ]; then NODE_EXEC_PATH="$HOME/.nvm/versions/node/$(nvm current)/bin/node";
    else 
        printf "\e[31mPlease ensure Node.js is installed and 'node' is in your PATH.\e[0m\n"; 
        exit 1; 
    fi
    printf "\e[33mFound node at %s. Proceeding.\e[0m\n" "$NODE_EXEC_PATH"
fi

NPM_GLOBAL_PREFIX=$(npm get prefix -g 2>/dev/null)
if [ -z "$NPM_GLOBAL_PREFIX" ]; then
    printf "\e[31mError: Could not determine npm global prefix directory.\e[0m\n"
    printf "\e[31mCannot create bridge_config.json correctly. Ensure npm is configured.\e[0m\n"
    exit 1
fi
NPM_GLOBAL_BIN="$NPM_GLOBAL_PREFIX/bin"

# Transform paths to use underscores instead of spaces for JSON config
NODE_EXEC_PATH_US=$(echo "$NODE_EXEC_PATH" | sed 's/ /_/g')
NPM_GLOBAL_BIN_US=$(echo "$NPM_GLOBAL_BIN" | sed 's/ /_/g')
WORKSPACE_DIR_US=$(echo "$WORKSPACE_DIR" | sed 's/ /_/g')

# Generate bridge configuration with conditional API key services
# Create the base configuration
cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "NODE_EXEC_PATH_PLACEHOLDER",
      "args": ["FS_SERVER_PATH_PLACEHOLDER", "WORKSPACE_DIR_PLACEHOLDER"]
    },
    "memory": {
      "command": "NODE_EXEC_PATH_PLACEHOLDER",
      "args": ["MEMORY_SERVER_PATH_PLACEHOLDER"]
    },
    "gmail-drive": {
      "command": "NODE_EXEC_PATH_PLACEHOLDER",
      "args": ["GMAIL_SERVER_PATH_PLACEHOLDER"]
    }ADDITIONAL_SERVERS_PLACEHOLDER
  },
  "llm": {
    "model": "LLM_MODEL_PLACEHOLDER",
    "baseUrl": "http://localhost:11434"
  }
}
EOF

# Build additional servers section
ADDITIONAL_SERVERS=""
if [[ "${HAS_BRAVE_API_KEY:-false}" == "true" ]]; then
    ADDITIONAL_SERVERS="$ADDITIONAL_SERVERS,
    \"brave-search\": {
      \"command\": \"NODE_EXEC_PATH_PLACEHOLDER\",
      \"args\": [\"$NPM_GLOBAL_BIN_US/mcp-server-brave-search\"],
      \"env\": {
        \"BRAVE_API_KEY\": \"\${BRAVE_API_KEY}\"
      }
    }"
fi

if [[ "${HAS_GITHUB_PERSONAL_ACCESS_TOKEN:-false}" == "true" ]]; then
    ADDITIONAL_SERVERS="$ADDITIONAL_SERVERS,
    \"github\": {
      \"command\": \"NODE_EXEC_PATH_PLACEHOLDER\",
      \"args\": [\"$NPM_GLOBAL_BIN_US/mcp-server-github\"],
      \"env\": {
        \"GITHUB_PERSONAL_ACCESS_TOKEN\": \"\${GITHUB_PERSONAL_ACCESS_TOKEN}\"
      }
    }"
fi

if [[ "${HAS_REPLICATE_API_TOKEN:-false}" == "true" ]]; then
    ADDITIONAL_SERVERS="$ADDITIONAL_SERVERS,
    \"flux\": {
      \"command\": \"NODE_EXEC_PATH_PLACEHOLDER\",
      \"args\": [\"$NPM_GLOBAL_BIN_US/server-flux\"],
      \"env\": {
        \"REPLICATE_API_TOKEN\": \"\${REPLICATE_API_TOKEN}\"
      }
    }"
fi

# Replace placeholders with actual values
sed -i "s|NODE_EXEC_PATH_PLACEHOLDER|$NODE_EXEC_PATH_US|g" "$CONFIG_FILE"
sed -i "s|FS_SERVER_PATH_PLACEHOLDER|$NPM_GLOBAL_BIN_US/mcp-server-filesystem|g" "$CONFIG_FILE"
sed -i "s|WORKSPACE_DIR_PLACEHOLDER|$WORKSPACE_DIR_US|g" "$CONFIG_FILE"
sed -i "s|MEMORY_SERVER_PATH_PLACEHOLDER|$NPM_GLOBAL_BIN_US/mcp-server-memory|g" "$CONFIG_FILE"
sed -i "s|GMAIL_SERVER_PATH_PLACEHOLDER|$NPM_GLOBAL_BIN_US/server-gmail-drive|g" "$CONFIG_FILE"
sed -i "s|LLM_MODEL_PLACEHOLDER|$LLM_MODEL|g" "$CONFIG_FILE"
sed -i "s|ADDITIONAL_SERVERS_PLACEHOLDER|$ADDITIONAL_SERVERS|g" "$CONFIG_FILE"

if [ -f "$CONFIG_FILE" ]; then
    printf "\e[32m$CONFIG_FILE created successfully.\e[0m\n"
    printf "\e[33mPlease review $CONFIG_FILE and update server paths in 'args' if 'npm bin -g' does not point to the correct executables.\e[0m\n"
    
    # Show which services are enabled/disabled
    printf "\n\e[34mMCP Services Configuration Summary:\e[0m\n"
    printf "\e[32m✓ Filesystem server: Enabled\e[0m\n"
    printf "\e[32m✓ Memory server: Enabled\e[0m\n"
    printf "\e[32m✓ Gmail-Drive server: Enabled\e[0m\n"
    
    if [[ "${HAS_BRAVE_API_KEY:-false}" == "true" ]]; then
        printf "\e[32m✓ Brave Search: Enabled (API key provided)\e[0m\n"
    else
        printf "\e[33m✗ Brave Search: Disabled (no API key)\e[0m\n"
    fi
    
    if [[ "${HAS_GITHUB_PERSONAL_ACCESS_TOKEN:-false}" == "true" ]]; then
        printf "\e[32m✓ GitHub: Enabled (API key provided)\e[0m\n"
    else
        printf "\e[33m✗ GitHub: Disabled (no API key)\e[0m\n"
    fi
    
    if [[ "${HAS_REPLICATE_API_TOKEN:-false}" == "true" ]]; then
        printf "\e[32m✓ Flux (Image Generation): Enabled (API key provided)\e[0m\n"
    else
        printf "\e[33m✗ Flux (Image Generation): Disabled (no API key)\e[0m\n"
    fi
    printf "\n"
else
    printf "\e[31mError: Failed to create $CONFIG_FILE. Please create it manually.\e[0m\n"
fi

# --- Post-installation --- 
printf "\n\e[34mPost-installation steps:\e[0m\n"
printf "\e[33mIMPORTANT: Configure API keys and OAuth for full functionality.\e[0m\n"
printf "The bridge may have limited capabilities without these.\n\n"

api_keys_to_configure=(
    "BRAVE_API_KEY:Brave Search API Key"
    "GITHUB_PERSONAL_ACCESS_TOKEN:GitHub Personal Access Token"
    "REPLICATE_API_TOKEN:Replicate API Token (for Flux image generation)"
)

for item in "${api_keys_to_configure[@]}"; do
    IFS=":" read -r env_var_name description <<< "$item"
    printf "\n\e[35m%s\e[0m (%s):\n" "$env_var_name" "$description"
    
    # Check if already set in environment
    current_env_val=$(env | grep "^${env_var_name}=" | cut -d= -f2-)
    if [ -n "$current_env_val" ]; then
        printf "Already set in environment: \e[36m%s\e[0m\n" "$current_env_val"
        read -r -p "Press Enter to keep current value, or enter new value (empty to disable): " api_key_value
        if [ -z "$api_key_value" ]; then
            # Keep existing value
            eval "HAS_${env_var_name}=true"
            printf "\e[32mKeeping existing %s value.\e[0m\n" "$env_var_name"
            continue
        fi
    else
        read -r -p "Enter your API key (leave empty to skip): " api_key_value
    fi
    
    if [ -n "$api_key_value" ]; then
        # Save the API key to environment
        export "$env_var_name"="$api_key_value"
        printf "\e[32m%s has been set for this session.\e[0m\n" "$env_var_name"
        printf "To make it permanent, add this to your shell startup file:\n"
        printf "  \e[36mexport %s=\"%s\"\e[0m\n" "$env_var_name" "$api_key_value"
        
        # Mark this API key as available for bridge config
        eval "HAS_${env_var_name}=true"
    else
        printf "\e[33mSkipped %s - related services will be disabled.\e[0m\n" "$env_var_name"
        eval "HAS_${env_var_name}=false"
    fi
done

# Gmail/Drive Authentication
printf "\nGmail/Drive MCP Authentication:\n"
NPM_GLOBAL_BIN_PATH=$(npm bin -g 2>/dev/null)
# The executable name for @patruff/server-gmail-drive is typically 'server-gmail-drive'
# as defined in its package.json 'bin' field.
GMAIL_DRIVE_SERVER_EXEC="server-gmail-drive"

if [ -n "$NPM_GLOBAL_BIN_PATH" ] && [ -x "${NPM_GLOBAL_BIN_PATH}/${GMAIL_DRIVE_SERVER_EXEC}" ]; then
    GMAIL_DRIVE_AUTH_CMD="node \"${NPM_GLOBAL_BIN_PATH}/${GMAIL_DRIVE_SERVER_EXEC}\" auth"
    printf "To authenticate Gmail/Drive, run the following command in your terminal after this script finishes:
"
    printf "  \e[36m%s\e[0m\n" "$GMAIL_DRIVE_AUTH_CMD"
    read -r -p "Do you want to attempt to run this authentication command now? (Requires browser interaction) (yes/no) [no]: " run_gmail_auth_now
    if [[ "$run_gmail_auth_now" == "yes" ]]; then
        printf "Attempting to run: %s\n" "$GMAIL_DRIVE_AUTH_CMD"
        eval "$GMAIL_DRIVE_AUTH_CMD"
        printf "Gmail/Drive authentication process attempted. Check terminal output for status or errors.\n"
    fi
else
    # Fallback if detection fails
    printf "Could not automatically determine the path for Gmail/Drive server authentication command.
"
    printf "You may need to find the 'server-gmail-drive' script installed globally by npm.
"
    printf "Typically, you can run it with a command like: \e[36mnode path/to/your/global/node_modules/@patruff/server-gmail-drive/dist/index.js auth\e[0m
"
    printf "Or, if 'server-gmail-drive' (the executable) is in your PATH: \e[36mnode server-gmail-drive auth\e[0m
"
fi
printf "This step requires interaction in your browser to grant access if run.

"

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
        
        # --- Start Enhanced Debugging ---
        printf "\n\e[35mDEBUG: --- Ollama MCP Bridge Startup --- \e[0m\n"
        printf "\e[35mDEBUG: Target bridge directory: %s\e[0m\n" "$CLONE_DIR"
        printf "\e[35mDEBUG: Current directory for starting bridge: $(pwd)\e[0m\n"
        printf "\e[35mDEBUG: Listing contents of current directory ($(pwd)) (before checks):\e[0m\n"
        ls -la
        
        if [ -d "src" ]; then
            printf "\e[35mDEBUG: Listing contents of src/ directory:\e[0m\n"
            ls -la src/
        else
            printf "\e[33mDEBUG: src/ directory NOT FOUND in $(pwd)\e[0m\n"
        fi
        
        # Check if src/main.ts exists
        if [ ! -f "src/main.ts" ]; then
            printf "\e[31mCRITICAL ERROR: src/main.ts not found in $(pwd). Bridge will not start.\e[0m\n"
            if [ -f ".git/config" ]; then
                printf "\e[35mDEBUG: .git/config contents:\n"
                cat .git/config
            else
                printf "\e[33mDEBUG: .git/config NOT FOUND in $(pwd)\e[0m\n"
            fi
            printf "\e[35mDEBUG: --- End Ollama MCP Bridge Startup Debug (src/main.ts not found) ---\e[0m\n\n"
            exit 1
        fi

        # Check if node_modules/.bin/ts-node exists
        if [ ! -x "./node_modules/.bin/ts-node" ]; then
             printf "\e[31mCRITICAL ERROR: ./node_modules/.bin/ts-node not found or not executable in $(pwd). Bridge will not start.\e[0m\n"
             printf "\e[35mDEBUG: Listing contents of node_modules/.bin/ directory:\e[0m\n"
             if [ -d "node_modules/.bin" ]; then
                ls -la node_modules/.bin/
             else
                printf "\e[33mDEBUG: node_modules/.bin/ directory NOT FOUND in $(pwd)\e[0m\n"
             fi
             printf "\e[35mDEBUG: --- End Ollama MCP Bridge Startup Debug (ts-node not found) ---\e[0m\n\n"
             exit 1
        fi
        # --- End Enhanced Debugging (Checks Passed) ---
        
        nohup "./node_modules/.bin/ts-node" "src/main.ts" > "$LOG_FILE" 2>&1 &
        NOHUP_PID=$!

        printf "Waiting a few seconds for the bridge to initialize...\n"
        sleep 5 

        if ps -p $NOHUP_PID > /dev/null; then
            printf "\e[32mOllama-MCP-Bridge appears to have started successfully in the background (PID: %s).\e[0m\n" "$NOHUP_PID"
            printf "You can view the logs with: \e[36mtail -f %s\e[0m\n" "$LOG_FILE"
            printf "To stop this instance of the bridge, you can use: \e[36mkill %s\e[0m\n" "$NOHUP_PID"
            printf "Alternatively, find the process with 'pgrep -f \"npm run start.*ollama-mcp-bridge\"' or similar and kill it.\n"
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