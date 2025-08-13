#!/bin/bash

# Hyprland Dotfiles Installation Script
# Comprehensive desktop environment setup with multiple themes and configurations
# Author: Your Name
# Version: 2.0

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global variables
THEME_CHOICE=""
INSTALL_APPS=""
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Available themes (20 complete themes)
declare -A THEMES=(
    ["1"]="Catppuccin-Mocha"
    ["2"]="Catppuccin-Macchiato"
    ["3"]="Catppuccin-Latte"
    ["4"]="Catppuccin-Frappe"
    ["5"]="TokyoNight-Night"
    ["6"]="TokyoNight-Storm"
    ["7"]="TokyoNight-Day"
    ["8"]="Gruvbox-Dark"
    ["9"]="Gruvbox-Light"
    ["10"]="Nord"
    ["11"]="Nord-Light"
    ["12"]="Rose-Pine"
    ["13"]="Rose-Pine-Moon"
    ["14"]="Rose-Pine-Dawn"
    ["15"]="Dracula"
    ["16"]="Monokai-Pro"
    ["17"]="Solarized-Dark"
    ["18"]="Solarized-Light"
    ["19"]="Everforest-Dark"
    ["20"]="Everforest-Light"
)

# Show banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗ ║
║      ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║ ║
║      ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║ ║
║      ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║ ║
║      ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║ ║
║      ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ║
║                                                                  ║
║            🚀 COMPLETE DOTFILES INSTALLATION SUITE 🚀           ║
║                                                                  ║
║  • Multiple Theme Options          • Wallpaper Collections       ║
║  • Quickshell Desktop Environment  • Custom Waybar Configs       ║
║  • Rofi Launcher Themes            • Application Presets         ║
║  • Complete Backup System          • Interactive Setup           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# System check
check_system() {
    log "Performing system compatibility check..."
    
    if ! command -v pacman &> /dev/null; then
        error "This script is designed for Arch Linux and derivatives only!"
    fi
    
    # Check if running on supported distros
    if ! grep -qE "(Arch|CachyOS|EndeavourOS|Manjaro)" /etc/os-release; then
        warning "This script is optimized for Arch-based distributions"
        echo "Current system: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
    
    success "System compatibility check passed"
}

# Theme selection menu
select_theme() {
    echo -e "${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│            🎨 THEME SELECTION           │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}"
    echo
    
    echo "Available themes:"
    for key in $(printf '%s\n' "${!THEMES[@]}" | sort -n); do
        theme_name="${THEMES[$key]}"
        case $theme_name in
            "Catppuccin-Mocha") echo -e "  ${key}. ${PURPLE}$theme_name${NC} - Dark purple elegance" ;;
            "Catppuccin-Macchiato") echo -e "  ${key}. ${BLUE}$theme_name${NC} - Warm blue comfort" ;;
            "TokyoNight") echo -e "  ${key}. ${CYAN}$theme_name${NC} - Cyberpunk vibes" ;;
            "Gruvbox") echo -e "  ${key}. ${YELLOW}$theme_name${NC} - Retro warm colors" ;;
            "Nord") echo -e "  ${key}. ${WHITE}$theme_name${NC} - Arctic frost theme" ;;
            "Rose-Pine") echo -e "  ${key}. ${RED}$theme_name${NC} - Soft rose aesthetic" ;;
        esac
    done
    echo
    
    while true; do
        read -p "Select theme (1-6): " choice
        if [[ -n "${THEMES[$choice]}" ]]; then
            THEME_CHOICE="${THEMES[$choice]}"
            success "Selected theme: $THEME_CHOICE"
            break
        else
            warning "Invalid selection. Please choose 1-6."
        fi
    done
}

# Installation options
select_options() {
    echo -e "\n${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│         📦 INSTALLATION OPTIONS         │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}"
    echo
    
    echo "Installation components:"
    echo "  1. Core System (Hyprland, Waybar, Quickshell, Rofi)"
    echo "  2. Development Tools (VS Code, Git tools, terminals)"
    echo "  3. Media Applications (MPV, Image viewers, Audio tools)"
    echo "  4. Gaming Setup (Steam, Lutris, gaming utilities)"
    echo "  5. Productivity Suite (LibreOffice, PDF tools, etc.)"
    echo
    
    read -p "Install additional applications? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_APPS="yes"
        echo "Additional apps will be installed"
    else
        INSTALL_APPS="no"
        echo "Core system only"
    fi
}

# AUR helper check/install
setup_aur_helper() {
    log "Checking AUR helper..."
    
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    else
        log "Installing yay AUR helper..."
        sudo pacman -S --needed --noconfirm git base-devel
        
        if [ -d "/tmp/yay" ]; then
            rm -rf /tmp/yay
        fi
        
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        AUR_HELPER="yay"
    fi
    
    success "AUR helper ready: $AUR_HELPER"
}

# Backup existing configurations
backup_configs() {
    log "Creating backup of existing configurations..."
    
    BACKUP_DIRS=(
        ".config/hypr"
        ".config/waybar"
        ".config/quickshell"
        ".config/rofi"
        ".config/dunst"
        ".config/kitty"
        ".config/alacritty"
        ".config/wlogout"
        ".config/swappy"
    )
    
    mkdir -p "$BACKUP_DIR"
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$HOME/$dir" ]; then
            cp -r "$HOME/$dir" "$BACKUP_DIR/"
            log "Backed up: $dir"
        fi
    done
    
    if [ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        success "Configurations backed up to: $BACKUP_DIR"
    else
        rm -rf "$BACKUP_DIR"
        log "No existing configurations found to backup"
    fi
}

# Install core packages
install_core_packages() {
    log "Installing core packages..."
    
    # Core Hyprland ecosystem
    CORE_PACKAGES=(
        # Compositor and portals
        hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        
        # Wayland support
        qt5-wayland qt6-wayland
        
        # Core desktop components
        waybar dunst
        
        # File managers
        thunar thunar-archive-plugin thunar-volman
        
        # Terminals
        kitty alacritty
        
        # Media and screenshots
        grim slurp swappy wl-clipboard
        
        # Audio
        pipewire pipewire-alsa pipewire-pulse pipewire-jack
        pavucontrol pamixer
        
        # Network
        networkmanager network-manager-applet
        
        # Fonts
        ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
        ttf-fira-code ttf-opensans
        
        # Icons and themes
        papirus-icon-theme adwaita-icon-theme
        
        # System utilities
        polkit-gnome brightnessctl
        
        # Basic applications
        firefox nautilus
    )
    
    sudo pacman -S --needed --noconfirm "${CORE_PACKAGES[@]}"
    
    # AUR packages
    AUR_CORE=(
        rofi-wayland
        quickshell-git
        swww
        wlogout
        hyprpicker
        hyprshot
    )
    
    for pkg in "${AUR_CORE[@]}"; do
        $AUR_HELPER -S --needed --noconfirm "$pkg"
    done
    
    success "Core packages installed!"
}

# Install additional applications
install_additional_apps() {
    if [ "$INSTALL_APPS" = "no" ]; then
        return 0
    fi
    
    log "Installing additional applications..."
    
    ADDITIONAL_PACKAGES=(
        # Development
        code git github-cli
        
        # Media
        mpv imv gwenview
        spotify-launcher
        
        # Productivity
        libreoffice-fresh
        thunderbird
        
        # Gaming
        steam lutris
        
        # Utilities
        btop htop neofetch
        tree zip unzip
        
        # Graphics
        gimp inkscape
    )
    
    sudo pacman -S --needed --noconfirm "${ADDITIONAL_PACKAGES[@]}"
    
    # Additional AUR packages
    AUR_ADDITIONAL=(
        visual-studio-code-bin
        discord
        obsidian
    )
    
    for pkg in "${AUR_ADDITIONAL[@]}"; do
        $AUR_HELPER -S --needed --noconfirm "$pkg" 2>/dev/null || true
    done
    
    success "Additional applications installed!"
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    
    DIRECTORIES=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
        "$HOME/.config/quickshell"
        "$HOME/.config/rofi/themes"
        "$HOME/.config/dunst"
        "$HOME/.config/kitty"
        "$HOME/.config/alacritty"
        "$HOME/.config/wlogout"
        "$HOME/.config/swappy"
        "$HOME/.local/bin"
        "$HOME/.local/share/themes"
        "$HOME/.local/share/icons"
        "$HOME/Pictures/Wallpapers"
        "$HOME/Pictures/Screenshots"
        "$HOME/Documents/Scripts"
    )
    
    for dir in "${DIRECTORIES[@]}"; do
        mkdir -p "$dir"
    done
    
    success "Directory structure created!"
}

# Deploy theme configurations
deploy_theme_configs() {
    log "Deploying $THEME_CHOICE theme configurations..."
    
    case $THEME_CHOICE in
        "Catppuccin-Mocha")
            deploy_catppuccin_mocha
            ;;
        "Catppuccin-Macchiato")
            deploy_catppuccin_macchiato
            ;;
        "TokyoNight")
            deploy_tokyonight
            ;;
        "Gruvbox")
            deploy_gruvbox
            ;;
        "Nord")
            deploy_nord
            ;;
        "Rose-Pine")
            deploy_rosepine
            ;;
    esac
    
    success "$THEME_CHOICE theme deployed!"
}

# Catppuccin Mocha theme
deploy_catppuccin_mocha() {
    # Colors for Mocha
    local bg="#1e1e2e"
    local surface0="#313244"
    local surface1="#45475a"
    local text="#cdd6f4"
    local accent="#cba6f7"
    local accent2="#89b4fa"
    local red="#f38ba8"
    local green="#a6e3a1"
    local yellow="#f9e2af"
    
    # Deploy configurations with Mocha colors
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "mocha" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "mocha" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "mocha" "$bg" "$text" "$accent"
    create_kitty_config "mocha"
    create_dunst_config "mocha" "$bg" "$text" "$accent2"
    
    # Download Catppuccin Mocha wallpapers
    download_wallpapers_catppuccin "mocha"
}

# Catppuccin Macchiato theme
deploy_catppuccin_macchiato() {
    local bg="#24273a"
    local surface0="#363a4f"
    local surface1="#494d64"
    local text="#cad3f5"
    local accent="#c6a0f6"
    local accent2="#8aadf4"
    local red="#ed8796"
    local green="#a6da95"
    local yellow="#eed49f"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "macchiato" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "macchiato" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "macchiato" "$bg" "$text" "$accent"
    create_kitty_config "macchiato"
    create_dunst_config "macchiato" "$bg" "$text" "$accent2"
    
    download_wallpapers_catppuccin "macchiato"
}

# TokyoNight theme
deploy_tokyonight() {
    local bg="#1a1b26"
    local surface0="#24283b"
    local surface1="#414868"
    local text="#c0caf5"
    local accent="#7aa2f7"
    local accent2="#bb9af7"
    local red="#f7768e"
    local green="#9ece6a"
    local yellow="#e0af68"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "tokyonight" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight"
    create_dunst_config "tokyonight" "$bg" "$text" "$accent"
    
    download_wallpapers_tokyonight
}

# Gruvbox theme
deploy_gruvbox() {
    local bg="#282828"
    local surface0="#3c3836"
    local surface1="#504945"
    local text="#ebdbb2"
    local accent="#d79921"
    local accent2="#458588"
    local red="#cc241d"
    local green="#98971a"
    local yellow="#d79921"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "gruvbox" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "gruvbox" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "gruvbox" "$bg" "$text" "$accent"
    create_kitty_config "gruvbox"
    create_dunst_config "gruvbox" "$bg" "$text" "$accent2"
    
    download_wallpapers_gruvbox
}

# Nord theme
deploy_nord() {
    local bg="#2e3440"
    local surface0="#3b4252"
    local surface1="#434c5e"
    local text="#eceff4"
    local accent="#88c0d0"
    local accent2="#8fbcbb"
    local red="#bf616a"
    local green="#a3be8c"
    local yellow="#ebcb8b"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "nord" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "nord" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "nord" "$bg" "$text" "$accent"
    create_kitty_config "nord"
    create_dunst_config "nord" "$bg" "$text" "$accent"
    
    download_wallpapers_nord
}

# Rose Pine theme
deploy_rosepine() {
    local bg="#191724"
    local surface0="#1f1d2e"
    local surface1="#26233a"
    local text="#e0def4"
    local accent="#ebbcba"
    local accent2="#c4a7e7"
    local red="#eb6f92"
    local green="#31748f"
    local yellow="#f6c177"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "rosepine" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "rosepine" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "rosepine" "$bg" "$text" "$accent"
    create_kitty_config "rosepine"
    create_dunst_config "rosepine" "$bg" "$text" "$accent2"
    
    download_wallpapers_rosepine
}

# Source configuration functions
source "$SCRIPT_DIR/configs.sh" 2>/dev/null || true
source "$SCRIPT_DIR/theme-configs.sh" 2>/dev/null || {
    error "theme-configs.sh not found! Please ensure all files are in the same directory."
}

# Wallpaper download functions
download_wallpapers_catppuccin() {
    log "Setting up Catppuccin wallpapers ($1 variant)..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    
    # Create gradient wallpapers
    if command -v convert &> /dev/null; then
        case $1 in
            "mocha")
                convert -size 1920x1080 gradient:"#1e1e2e"-"#313244" "$HOME/Pictures/Wallpapers/catppuccin-mocha-1.jpg"
                convert -size 1920x1080 radial-gradient:"#cba6f7"-"#1e1e2e" "$HOME/Pictures/Wallpapers/catppuccin-mocha-2.jpg"
                ;;
            "macchiato")
                convert -size 1920x1080 gradient:"#24273a"-"#363a4f" "$HOME/Pictures/Wallpapers/catppuccin-macchiato-1.jpg"
                convert -size 1920x1080 radial-gradient:"#c6a0f6"-"#24273a" "$HOME/Pictures/Wallpapers/catppuccin-macchiato-2.jpg"
                ;;
        esac
        ln -sf "$HOME/Pictures/Wallpapers/catppuccin-$1-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

download_wallpapers_tokyonight() {
    log "Setting up TokyoNight wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#1a1b26"-"#24283b" "$HOME/Pictures/Wallpapers/tokyonight-1.jpg"
        convert -size 1920x1080 radial-gradient:"#7aa2f7"-"#1a1b26" "$HOME/Pictures/Wallpapers/tokyonight-2.jpg"
        ln -sf "$HOME/Pictures/Wallpapers/tokyonight-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

download_wallpapers_gruvbox() {
    log "Setting up Gruvbox wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#282828"-"#3c3836" "$HOME/Pictures/Wallpapers/gruvbox-1.jpg"
        convert -size 1920x1080 radial-gradient:"#d79921"-"#282828" "$HOME/Pictures/Wallpapers/gruvbox-2.jpg"
        ln -sf "$HOME/Pictures/Wallpapers/gruvbox-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

download_wallpapers_nord() {
    log "Setting up Nord wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#2e3440"-"#3b4252" "$HOME/Pictures/Wallpapers/nord-1.jpg"
        convert -size 1920x1080 radial-gradient:"#88c0d0"-"#2e3440" "$HOME/Pictures/Wallpapers/nord-2.jpg"
        ln -sf "$HOME/Pictures/Wallpapers/nord-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

download_wallpapers_rosepine() {
    log "Setting up Rose Pine wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#191724"-"#1f1d2e" "$HOME/Pictures/Wallpapers/rosepine-1.jpg"
        convert -size 1920x1080 radial-gradient:"#ebbcba"-"#191724" "$HOME/Pictures/Wallpapers/rosepine-2.jpg"
        ln -sf "$HOME/Pictures/Wallpapers/rosepine-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

# Enable services
enable_services() {
    log "Enabling system services..."
    
    sudo systemctl enable NetworkManager --quiet
    sudo systemctl enable bluetooth --quiet 2>/dev/null || true
    
    success "System services enabled!"
}

# Final setup
final_setup() {
    log "Performing final setup tasks..."
    
    # Add user to relevant groups
    sudo usermod -aG video,audio "$USER" 2>/dev/null || true
    
    # Set GTK theme
    mkdir -p "$HOME/.config/gtk-3.0"
    echo "[Settings]" > "$HOME/.config/gtk-3.0/settings.ini"
    echo "gtk-theme-name=$THEME_CHOICE" >> "$HOME/.config/gtk-3.0/settings.ini"
    echo "gtk-icon-theme-name=Papirus" >> "$HOME/.config/gtk-3.0/settings.ini"
    
    success "Final setup completed!"
}

# Main installation function
main() {
    show_banner
    
    echo -e "${WHITE}Welcome to the Hyprland Dotfiles Installation Suite!${NC}"
    echo
    echo "This comprehensive script will set up a complete Hyprland desktop environment with:"
    echo "  • Multiple theme options with coordinated color schemes"
    echo "  • Quickshell desktop environment with custom panels and widgets"
    echo "  • Waybar status bar with theme-specific configurations"
    echo "  • Rofi application launcher with beautiful themes"
    echo "  • Wallpaper collections matching each theme"
    echo "  • Complete application suite (optional)"
    echo "  • Automatic backup of existing configurations"
    echo
    
    read -p "Do you want to proceed with the installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Installation cancelled by user."
        exit 0
    fi
    
    # Installation workflow
    check_system
    select_theme
    select_options
    setup_aur_helper
    backup_configs
    install_core_packages
    install_additional_apps
    create_directories
    deploy_theme_configs
    enable_services
    final_setup
    
    # Success message
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                  ║${NC}"
    echo -e "${GREEN}║                🎉 INSTALLATION COMPLETED! 🎉                   ║${NC}"
    echo -e "${GREEN}║                                                                  ║${NC}"
    echo -e "${GREEN}║  Your Hyprland desktop environment has been successfully        ║${NC}"
    echo -e "${GREEN}║  installed with the $THEME_CHOICE theme!                        ║${NC}"
    echo -e "${GREEN}║                                                                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Reboot your system: ${YELLOW}sudo reboot${NC}"
    echo "  2. Select Hyprland from your display manager"
    echo "  3. Enjoy your beautiful new desktop!"
    echo
    echo -e "${CYAN}Key Bindings:${NC}"
    echo "  • Super + Enter: Terminal"
    echo "  • Super + Space: App launcher" 
    echo "  • Super + E: File manager"
    echo "  • Super + Q: Close window"
    echo "  • Print: Screenshot area"
    echo
    echo -e "${CYAN}Configuration Files:${NC}"
    echo "  • Hyprland: ~/.config/hypr/"
    echo "  • Waybar: ~/.config/waybar/"
    echo "  • Quickshell: ~/.config/quickshell/"
    echo "  • Rofi: ~/.config/rofi/"
    echo
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Your original configurations have been backed up to:${NC}"
        echo "$BACKUP_DIR"
    fi
    echo
    warning "A reboot is required to start using your new desktop environment!"
}

# Run the script
main "$@"
