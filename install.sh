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
    
    # Display themes in organized groups
    echo -e "${PURPLE}Catppuccin Themes:${NC}"
    echo "  1. Catppuccin Mocha     5. TokyoNight Night     9. Gruvbox Dark"
    echo "  2. Catppuccin Macchiato 6. TokyoNight Storm    10. Gruvbox Light"
    echo "  3. Catppuccin Latte     7. TokyoNight Day      11. Nord"
    echo "  4. Catppuccin Frappe    8. Nord Light          12. Rose Pine"
    echo
    echo -e "${CYAN}Additional Themes:${NC}"
    echo " 13. Rose Pine Moon      17. Solarized Dark"
    echo " 14. Rose Pine Dawn      18. Solarized Light"
    echo " 15. Dracula             19. Everforest Dark"
    echo " 16. Monokai Pro         20. Everforest Light"
    echo
    
    while true; do
        read -p "Select theme (1-20): " choice
        if [[ -n "${THEMES[$choice]}" ]]; then
            THEME_CHOICE="${THEMES[$choice]}"
            success "Selected theme: $THEME_CHOICE"
            break
        else
            warning "Invalid selection. Please choose 1-20."
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
    echo "  6. NVIDIA Integration & Display Scaling"
    echo "  7. SDDM Simple2 Theme Setup"
    echo "  8. Advanced Configuration (Keybinds, Window Rules, Rainbow Effects)"
    echo
    
    # Additional apps selection
    read -p "Install additional applications? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_APPS="yes"
        echo "Additional apps will be installed"
    else
        INSTALL_APPS="no"
        echo "Core system only"
    fi
    
    # NVIDIA integration
    echo
    read -p "Setup NVIDIA integration and display scaling? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_NVIDIA="yes"
        success "NVIDIA integration will be configured"
    else
        INSTALL_NVIDIA="no"
    fi
    
    # SDDM setup
    echo
    read -p "Install SDDM Simple2 theme? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_SDDM="yes"
        success "SDDM Simple2 theme will be installed"
    else
        INSTALL_SDDM="no"
    fi
    
    # Advanced configuration
    echo
    read -p "Install advanced configuration (keybinds, window rules, rainbow effects)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_ADVANCED="yes"
        success "Advanced configuration will be installed"
    else
        INSTALL_ADVANCED="no"
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
        "Catppuccin-Latte")
            deploy_catppuccin_latte
            ;;
        "Catppuccin-Frappe")
            deploy_catppuccin_frappe
            ;;
        "TokyoNight-Night")
            deploy_tokyonight_night
            ;;
        "TokyoNight-Storm")
            deploy_tokyonight_storm
            ;;
        "TokyoNight-Day")
            deploy_tokyonight_day
            ;;
        "Gruvbox-Dark")
            deploy_gruvbox_dark
            ;;
        "Gruvbox-Light")
            deploy_gruvbox_light
            ;;
        "Nord")
            deploy_nord
            ;;
        "Nord-Light")
            deploy_nord_light
            ;;
        "Rose-Pine")
            deploy_rosepine
            ;;
        "Rose-Pine-Moon")
            deploy_rosepine_moon
            ;;
        "Rose-Pine-Dawn")
            deploy_rosepine_dawn
            ;;
        "Dracula")
            deploy_dracula
            ;;
        "Monokai-Pro")
            deploy_monokai_pro
            ;;
        "Solarized-Dark")
            deploy_solarized_dark
            ;;
        "Solarized-Light")
            deploy_solarized_light
            ;;
        "Everforest-Dark")
            deploy_everforest_dark
            ;;
        "Everforest-Light")
            deploy_everforest_light
            ;;
        *)
            error "Unknown theme: $THEME_CHOICE"
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

# Catppuccin Latte theme (Light)
deploy_catppuccin_latte() {
    local bg="#eff1f5"
    local surface0="#ccd0da"
    local surface1="#bcc0cc"
    local text="#4c4f69"
    local accent="#8839ef"
    local accent2="#1e66f5"
    local red="#d20f39"
    local green="#40a02b"
    local yellow="#df8e1d"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "latte" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "latte" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "latte" "$bg" "$text" "$accent"
    create_kitty_config "latte"
    create_dunst_config "latte" "$bg" "$text" "$accent2"
    download_wallpapers_catppuccin "latte"
}

# Catppuccin Frappe theme
deploy_catppuccin_frappe() {
    local bg="#303446"
    local surface0="#414559"
    local surface1="#51576d"
    local text="#c6d0f5"
    local accent="#ca9ee6"
    local accent2="#8caaee"
    local red="#e78284"
    local green="#a6d189"
    local yellow="#e5c890"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "frappe" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "frappe" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "frappe" "$bg" "$text" "$accent"
    create_kitty_config "frappe"
    create_dunst_config "frappe" "$bg" "$text" "$accent2"
    download_wallpapers_catppuccin "frappe"
}

# TokyoNight Night theme
deploy_tokyonight_night() {
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
    create_waybar_config "tokyonight-night" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight-night" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight-night" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight-night"
    create_dunst_config "tokyonight-night" "$bg" "$text" "$accent"
    download_wallpapers_tokyonight_night
}

# TokyoNight Storm theme
deploy_tokyonight_storm() {
    local bg="#24283b"
    local surface0="#1f2335"
    local surface1="#414868"
    local text="#c0caf5"
    local accent="#7aa2f7"
    local accent2="#7dcfff"
    local red="#f7768e"
    local green="#73daca"
    local yellow="#e0af68"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "tokyonight-storm" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight-storm" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight-storm" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight-storm"
    create_dunst_config "tokyonight-storm" "$bg" "$text" "$accent2"
    download_wallpapers_tokyonight_storm
}

# TokyoNight Day theme (Light)
deploy_tokyonight_day() {
    local bg="#e1e2e7"
    local surface0="#e9e9ed"
    local surface1="#dcd6d6"
    local text="#3760bf"
    local accent="#2e7de9"
    local accent2="#587539"
    local red="#f52a65"
    local green="#587539"
    local yellow="#8c6c3e"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "tokyonight-day" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight-day" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight-day" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight-day"
    create_dunst_config "tokyonight-day" "$bg" "$text" "$accent2"
    download_wallpapers_tokyonight_day
}

# Gruvbox Dark theme
deploy_gruvbox_dark() {
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
    create_waybar_config "gruvbox-dark" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "gruvbox-dark" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "gruvbox-dark" "$bg" "$text" "$accent"
    create_kitty_config "gruvbox-dark"
    create_dunst_config "gruvbox-dark" "$bg" "$text" "$accent2"
    download_wallpapers_gruvbox_dark
}

# Gruvbox Light theme
deploy_gruvbox_light() {
    local bg="#fbf1c7"
    local surface0="#ebdbb2"
    local surface1="#d5c4a1"
    local text="#3c3836"
    local accent="#b57614"
    local accent2="#076678"
    local red="#cc241d"
    local green="#98971a"
    local yellow="#d79921"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "gruvbox-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "gruvbox-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "gruvbox-light" "$bg" "$text" "$accent"
    create_kitty_config "gruvbox-light"
    create_dunst_config "gruvbox-light" "$bg" "$text" "$accent2"
    download_wallpapers_gruvbox_light
}

# Nord Light theme
deploy_nord_light() {
    local bg="#eceff4"
    local surface0="#e5e9f0"
    local surface1="#d8dee9"
    local text="#2e3440"
    local accent="#5e81ac"
    local accent2="#81a1c1"
    local red="#bf616a"
    local green="#a3be8c"
    local yellow="#ebcb8b"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "nord-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "nord-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "nord-light" "$bg" "$text" "$accent"
    create_kitty_config "nord-light"
    create_dunst_config "nord-light" "$bg" "$text" "$accent"
    download_wallpapers_nord_light
}

# Rose Pine Moon theme
deploy_rosepine_moon() {
    local bg="#232136"
    local surface0="#2a273f"
    local surface1="#393552"
    local text="#e0def4"
    local accent="#ea9a97"
    local accent2="#c4a7e7"
    local red="#eb6f92"
    local green="#3e8fb0"
    local yellow="#f6c177"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "rosepine-moon" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "rosepine-moon" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "rosepine-moon" "$bg" "$text" "$accent"
    create_kitty_config "rosepine-moon"
    create_dunst_config "rosepine-moon" "$bg" "$text" "$accent2"
    download_wallpapers_rosepine_moon
}

# Rose Pine Dawn theme (Light)
deploy_rosepine_dawn() {
    local bg="#faf4ed"
    local surface0="#f2e9de"
    local surface1="#ede4d3"
    local text="#575279"
    local accent="#d7827e"
    local accent2="#907aa9"
    local red="#b4637a"
    local green="#56949f"
    local yellow="#ea9d34"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "rosepine-dawn" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "rosepine-dawn" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "rosepine-dawn" "$bg" "$text" "$accent"
    create_kitty_config "rosepine-dawn"
    create_dunst_config "rosepine-dawn" "$bg" "$text" "$accent2"
    download_wallpapers_rosepine_dawn
}

# Dracula theme
deploy_dracula() {
    local bg="#282a36"
    local surface0="#44475a"
    local surface1="#6272a4"
    local text="#f8f8f2"
    local accent="#bd93f9"
    local accent2="#8be9fd"
    local red="#ff5555"
    local green="#50fa7b"
    local yellow="#f1fa8c"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "dracula" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "dracula" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "dracula" "$bg" "$text" "$accent"
    create_kitty_config "dracula"
    create_dunst_config "dracula" "$bg" "$text" "$accent2"
    download_wallpapers_dracula
}

# Monokai Pro theme
deploy_monokai_pro() {
    local bg="#2d2a2e"
    local surface0="#403e41"
    local surface1="#5b595c"
    local text="#fcfcfa"
    local accent="#ab9df2"
    local accent2="#78dce8"
    local red="#ff6188"
    local green="#a9dc76"
    local yellow="#ffd866"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "monokai-pro" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "monokai-pro" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "monokai-pro" "$bg" "$text" "$accent"
    create_kitty_config "monokai-pro"
    create_dunst_config "monokai-pro" "$bg" "$text" "$accent2"
    download_wallpapers_monokai_pro
}

# Solarized Dark theme
deploy_solarized_dark() {
    local bg="#002b36"
    local surface0="#073642"
    local surface1="#586e75"
    local text="#839496"
    local accent="#268bd2"
    local accent2="#2aa198"
    local red="#dc322f"
    local green="#859900"
    local yellow="#b58900"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "solarized-dark" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "solarized-dark" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "solarized-dark" "$bg" "$text" "$accent"
    create_kitty_config "solarized-dark"
    create_dunst_config "solarized-dark" "$bg" "$text" "$accent2"
    download_wallpapers_solarized_dark
}

# Solarized Light theme
deploy_solarized_light() {
    local bg="#fdf6e3"
    local surface0="#eee8d5"
    local surface1="#93a1a1"
    local text="#657b83"
    local accent="#268bd2"
    local accent2="#2aa198"
    local red="#dc322f"
    local green="#859900"
    local yellow="#b58900"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "solarized-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "solarized-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "solarized-light" "$bg" "$text" "$accent"
    create_kitty_config "solarized-light"
    create_dunst_config "solarized-light" "$bg" "$text" "$accent2"
    download_wallpapers_solarized_light
}

# Everforest Dark theme
deploy_everforest_dark() {
    local bg="#2d353b"
    local surface0="#343f44"
    local surface1="#475258"
    local text="#d3c6aa"
    local accent="#a7c080"
    local accent2="#83c092"
    local red="#e67e80"
    local green="#a7c080"
    local yellow="#dbbc7f"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "everforest-dark" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "everforest-dark" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "everforest-dark" "$bg" "$text" "$accent"
    create_kitty_config "everforest-dark"
    create_dunst_config "everforest-dark" "$bg" "$text" "$accent2"
    download_wallpapers_everforest_dark
}

# Everforest Light theme
deploy_everforest_light() {
    local bg="#fdf6e3"
    local surface0="#f3efda"
    local surface1="#edeada"
    local text="#5c6a72"
    local accent="#8da101"
    local accent2="#35a77c"
    local red="#f85552"
    local green="#8da101"
    local yellow="#dfa000"
    
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "everforest-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "everforest-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "everforest-light" "$bg" "$text" "$accent"
    create_kitty_config "everforest-light"
    create_dunst_config "everforest-light" "$bg" "$text" "$accent2"
    download_wallpapers_everforest_light
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
    
    # Run NVIDIA integration if selected
    if [ "$INSTALL_NVIDIA" = "yes" ]; then
        log "Running NVIDIA integration setup..."
        if [ -f "$SCRIPT_DIR/nvidia-integration.sh" ]; then
            bash "$SCRIPT_DIR/nvidia-integration.sh"
        else
            warning "nvidia-integration.sh not found, skipping NVIDIA setup"
        fi
    fi
    
    # Run SDDM setup if selected
    if [ "$INSTALL_SDDM" = "yes" ]; then
        log "Running SDDM Simple2 theme setup..."
        if [ -f "$SCRIPT_DIR/sddm-setup.sh" ]; then
            bash "$SCRIPT_DIR/sddm-setup.sh"
        else
            warning "sddm-setup.sh not found, skipping SDDM setup"
        fi
    fi
    
    # Run advanced configuration if selected
    if [ "$INSTALL_ADVANCED" = "yes" ]; then
        log "Running advanced configuration setup..."
        if [ -f "$SCRIPT_DIR/advanced-config.sh" ]; then
            bash "$SCRIPT_DIR/advanced-config.sh"
        else
            warning "advanced-config.sh not found, skipping advanced configuration"
        fi
    fi
    
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
