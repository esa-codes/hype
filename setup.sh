#!/bin/bash
set -e

echo "Cloning Fedora dotfiles..."
git clone https://github.com/EisregenHaha/fedora-hyprland ~/fedora-dotfiles

cd ~/fedora-dotfiles

echo "Running installer..."
chmod +x fedora.sh
./fedora.sh
