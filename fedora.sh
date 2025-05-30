#!/bin/bash

# Exit immediately on command error inside functions
set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script paths
INSTALL_SCRIPT="fedora/install.sh"
FONTS_SCRIPT="fedora/fonts.sh"
MANUAL_HELPER_SCRIPT="manual-install-helper.sh"

# Ask if user wants to exit
ask_exit() {
    echo -ne "${YELLOW}Do you want to exit the installer? (y/N): ${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
    fi
}

# Run script with or without sudo
run_script() {
    local script="$1"
    local sudo_flag="$2"

    if [[ "$sudo_flag" == "sudo" ]]; then
        echo -e "${YELLOW}Running $script with sudo...${NC}"
        sudo bash "$script"
    else
        echo -e "${YELLOW}Running $script as current user...${NC}"
        bash "$script"
    fi
    echo -e "${GREEN}✅ $script completed successfully.${NC}"
}

# Copy dotfiles into ~/.config and ~/.local (initial copy — no exclusions)
copy_dotfiles() {
    echo -e "${YELLOW}Copying dotfiles to ~/.config and ~/.local...${NC}"
    cp -Rf .config/* ~/.config/ || { echo -e "${RED}❌ Failed copying .config${NC}"; exit 1; }
    cp -Rf .local/* ~/.local/   || { echo -e "${RED}❌ Failed copying .local${NC}"; exit 1; }
    echo -e "${GREEN}✅ Dotfiles copied successfully.${NC}"
}

# Copy dotfiles for update (exclude hypr/custom)
copy_dotfiles_update() {
    echo -e "${YELLOW}Updating dotfiles in ~/.config and ~/.local (preserving hypr/custom)...${NC}"
    rsync -a --exclude 'hypr/custom/**' .config/ ~/.config/ || { echo -e "${RED}❌ Failed updating .config${NC}"; exit 1; }
    rsync -a .local/ ~/.local/ || { echo -e "${RED}❌ Failed updating .local${NC}"; exit 1; }
    echo -e "${GREEN}✅ Dotfiles updated successfully.${NC}"
}

# Full install: all scripts + dotfiles
run_full_install() {
    echo -e "${YELLOW}Starting full installation...${NC}"
    run_script "$INSTALL_SCRIPT" sudo || { echo -e "${RED}❌ Failed: $INSTALL_SCRIPT${NC}"; exit 1; }
    run_script "$FONTS_SCRIPT" ""     || { echo -e "${RED}❌ Failed: $FONTS_SCRIPT${NC}"; exit 1; }
    run_script "$MANUAL_HELPER_SCRIPT" "" || { echo -e "${RED}❌ Failed: $MANUAL_HELPER_SCRIPT${NC}"; exit 1; }
    copy_dotfiles
    echo -e "${GREEN}🎉 Full installation completed successfully! You can now reboot and select Hyprland at login.${NC}"
}

# Update: install deps + update dotfiles
run_update() {
    echo -e "${YELLOW}Running update (dependencies + configs)...${NC}"
    run_script "$INSTALL_SCRIPT" sudo || { echo -e "${RED}❌ Failed: $INSTALL_SCRIPT${NC}"; exit 1; }
    copy_dotfiles_update
    run_script "$MANUAL_HELPER_SCRIPT" "" || { echo -e "${RED}❌ Failed: $MANUAL_HELPER_SCRIPT${NC}"; exit 1; }
    echo -e "${GREEN}🎉 Update completed successfully!${NC}"
}

# Menu loop
while true; do
    echo -e "\n${YELLOW}Select an option:${NC}"
    echo "1) Full install"
    echo "2) Update dotfiles (preserves hypr/custom)"
    echo ""
    echo -e "\n${YELLOW}Partial Installations (be sure of what you are doing):${NC}"
    echo "3) Install Fonts"
    echo "4) Run manual-install-helper.sh"
    echo "5) Copy dotfiles to ~/.config and ~/.local"
    echo "6) Install Dependencies"
    echo "7) Exit"
    echo ""

    read -rp "Enter your choice [1-7]: " choice

    case "$choice" in
        1)
            run_full_install
            ;;
        2)
            run_update
            ask_exit
            ;;
        3)
            run_script "$FONTS_SCRIPT" "" || { echo -e "${RED}❌ Failed: $FONTS_SCRIPT${NC}"; }
            ask_exit
            ;;
        4)
            run_script "$MANUAL_HELPER_SCRIPT" "" || { echo -e "${RED}❌ Failed: $MANUAL_HELPER_SCRIPT${NC}"; }
            ask_exit
            ;;
        5)
            copy_dotfiles
            ask_exit
            ;;
        6)
            run_script "$INSTALL_SCRIPT" sudo || { echo -e "${RED}❌ Failed: $INSTALL_SCRIPT${NC}"; }
            ask_exit
            ;;
        7)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please enter a number from 1 to 7.${NC}"
            ;;
    esac
done

