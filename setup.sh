#!/bin/bash

# Hyprland Setup Script - Quick Installation
# Installs core packages and copies all configuration files

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Log functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

log "Starting Hyprland setup..."

# Required packages
PACKAGES="hyprland waybar dunst kitty rofi-wayland swww grim slurp wl-clipboard"

# Additional recommended packages
OPTIONAL_PACKAGES="polkit-kde-agent brightnessctl pavucontrol thunar"

# Install required packages
log "Installing required packages..."
for pkg in $PACKAGES; do
    if pacman -Qi "$pkg" &>/dev/null; then
        log "$pkg is already installed"
    else
        log "Installing $pkg..."
        sudo pacman -S --needed --noconfirm "$pkg" || warning "Failed to install $pkg"
    fi
done

# Ask about optional packages
read -p "Install optional packages (polkit, brightnessctl, etc.)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for pkg in $OPTIONAL_PACKAGES; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            sudo pacman -S --needed --noconfirm "$pkg" || warning "Failed to install $pkg"
        fi
    done
fi

# Backup existing configs
log "Backing up existing configurations..."
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
CONFIG_DIRS=("hypr" "waybar" "dunst" "kitty" "rofi" "quickshell")

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/.config/$dir" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" 2>/dev/null
        log "Backed up $dir to $BACKUP_DIR"
    fi
done

# Copy all configuration files
log "Installing configuration files..."
cp -r configs/hypr ~/.config/ 2>/dev/null && success "Hyprland config installed"
cp -r configs/waybar ~/.config/ 2>/dev/null && success "Waybar config installed"
cp -r configs/dunst ~/.config/ 2>/dev/null && success "Dunst config installed"
cp -r configs/kitty ~/.config/ 2>/dev/null && success "Kitty config installed"
cp -r configs/rofi ~/.config/ 2>/dev/null && success "Rofi config installed"
cp -r configs/quickshell ~/.config/ 2>/dev/null && success "Quickshell config installed"

# Create necessary directories
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/Pictures/Wallpapers

# Copy wallpapers if they exist
if [ -d "wallpapers" ] && [ "$(ls -A wallpapers)" ]; then
    cp -r wallpapers/* ~/Pictures/Wallpapers/ 2>/dev/null
    success "Wallpapers copied to ~/Pictures/Wallpapers"
fi

# Set executable permissions for scripts
find ~/.config -name "*.sh" -exec chmod +x {} \;

# Initialize swww
log "Initializing wallpaper daemon..."
swww init 2>/dev/null || warning "Could not initialize swww"

# Success message
echo
success "Hyprland setup completed successfully!"
echo
log "Configuration files installed to ~/.config/"
if [ -d "$BACKUP_DIR" ]; then
    log "Previous configs backed up to: $BACKUP_DIR"
fi
echo
log "To start Hyprland, logout and select it from your display manager"
log "Or run 'Hyprland' from TTY"
echo
log "Quick commands:"
echo "  - Super+Return: Open terminal"
echo "  - Super+Space: Open app launcher"
echo "  - Super+Q: Close window"
echo "  - Super+M: Exit Hyprland"
