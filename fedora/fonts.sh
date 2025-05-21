#!/bin/bash
set -e

t="$HOME/.cache/depends/"
rm -rf "$t"
mkdir -p "$t"
cd "$t"

# Clone the fonts repository
git clone https://github.com/EisregenHaha/end4fonts
cd end4fonts/fonts

# Ensure the fonts directory exists
mkdir -p ~/.local/share/fonts

# Copy fonts
cp -R * ~/.local/share/fonts

# Optional: refresh font cache
fc-cache -f

# Cleanup
rm -rf "$t"

# Success
echo -e "\e[1m✅ Installation complete. Proceed with the manual-install-helper script.\e[0m"
