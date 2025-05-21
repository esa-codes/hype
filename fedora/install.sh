#!/bin/bash
set -e

t="$HOME/.cache/depends/"
rm -rf "$t"
mkdir -p "$t"
cd "$t"

# Group installation
sudo dnf4 group install "Development Tools" -y

# COPR repositories
sudo dnf copr enable atim/starship -y
sudo dnf copr enable solopasha/hyprland -y

# Core development tools
sudo dnf install cmake clang -y
sudo dnf install cargo -y

# Python packages
sudo dnf install python3 python3-pip python3-devel -y
sudo dnf install python3-build python3-pillow python3-setuptools_scm python3-wheel -y
sudo dnf install python3-regex unzip -y
sudo dnf install python3-pywayland python3-psutil hypridle -y
sudo dnf install python3-gobject python3-dbus python3-requests python3-qrcode python3-setproctitle -y
sudo dnf install python3-gobject-devel libsoup-devel -y
sudo dnf install python3-libsass -y

# Hyprland and related packages
sudo dnf install hyprland hyprland-qtutils -y
sudo dnf install hyprpicker hyprutils hyprwayland-scanner hyprlock wlogout pugixml -y
sudo dnf install hyprlang-devel -y

# GUI and toolkit dependencies
sudo dnf install gtk4-devel libadwaita-devel -y
sudo dnf install gtk-layer-shell-devel gtk3 gtksourceview3 gtksourceview3-devel gobject-introspection upower -y
sudo dnf install gtksourceviewmm3-devel -y
sudo dnf install webp-pixbuf-loader -y
sudo dnf install gobject-introspection-devel gjs-devel pulseaudio-libs-devel -y

# Desktop integrations and utilities
sudo dnf install xrandr xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland -y
sudo dnf install gnome-bluetooth bluez-cups bluez blueman -y
sudo dnf install gammastep mate-polkit -y

# Core utilities
sudo dnf install coreutils wl-clipboard xdg-utils curl fuzzel rsync wget ripgrep gojq npm meson typescript gjs axel -y
sudo dnf install brightnessctl ddcutil -y

# Audio & media
sudo dnf install pavucontrol wireplumber libdbusmenu-gtk3-devel libdbusmenu playerctl swww -y

# Other individual tools
sudo dnf install yad -y
sudo dnf install scdoc -y
sudo dnf install ydotool -y
sudo dnf install tinyxml -y
sudo dnf install tinyxml2 tinyxml2-devel -y
sudo dnf install file-devel libwebp-devel libdrm-devel libgbm-devel pam-devel libsass-devel libsass -y

# Theming and appearance
sudo dnf install gnome-themes-extra adw-gtk3-theme qt5ct qt6-qtwayland qt5-qtwayland fontconfig jetbrains-mono-fonts gdouros-symbola-fonts lato-fonts fish foot starship -y
sudo dnf install aylurs-gtk-shell -y
sudo dnf install kvantum kvantum-qt5 -y
sudo dnf install libxdp-devel libxdp libportal -y

# Screenshot and screen recording tools
sudo dnf install swappy wf-recorder grim tesseract slurp -y

# AppStream and web libs
sudo dnf install appstream-util libsoup3-devel uv -y

# Networking and power tools
sudo dnf install -y NetworkManager power-profiles-daemon usbguard make --allowerasing

# Custom tool: cliphist
wget https://github.com/sentriz/cliphist/releases/download/v0.5.0/v0.5.0-linux-amd64 -O cliphist
chmod +x cliphist
sudo cp cliphist /usr/local/bin/cliphist

# Custom tool: dart-sass
cd "$t"
wget https://github.com/sass/dart-sass/releases/download/1.77.0/dart-sass-1.77.0-linux-x64.tar.gz
tar -xzf dart-sass-1.77.0-linux-x64.tar.gz
cd dart-sass
sudo cp -rf * /usr/local/bin/

# Build & install anyrun
cd "$t"
git clone https://github.com/anyrun-org/anyrun.git
cd anyrun
cargo build --release
cargo install --path anyrun/
sudo cp "$HOME/.cargo/bin/anyrun" /usr/local/bin/
mkdir -p ~/.config/anyrun/plugins
cp target/release/*.so ~/.config/anyrun/plugins
cp examples/config.ron ~/.config/anyrun/config.ron

# Build & install better-control
cd "$t"
git clone https://github.com/quantumvoid0/better-control.git
cd better-control
sudo make install
rm -rf ~/better-control

# Final message
echo -e "\e[1m✅ Installation complete. Proceed with the fonts script.\e[0m"

