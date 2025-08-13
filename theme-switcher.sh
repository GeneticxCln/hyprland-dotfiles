#!/bin/bash

# Theme Switcher for Hyprland Dotfiles
# Allows easy switching between all 20 configured themes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration directories
CONFIG_DIR="$HOME/.config"
THEMES_DIR="$(dirname "$0")/themes"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Available themes
declare -A THEMES=(
    ["1"]="catppuccin-mocha"
    ["2"]="catppuccin-macchiato"
    ["3"]="catppuccin-latte"
    ["4"]="catppuccin-frappe"
    ["5"]="tokyonight-night"
    ["6"]="tokyonight-storm"
    ["7"]="tokyonight-day"
    ["8"]="gruvbox-dark"
    ["9"]="gruvbox-light"
    ["10"]="nord"
    ["11"]="nord-light"
    ["12"]="rose-pine"
    ["13"]="rose-pine-moon"
    ["14"]="rose-pine-dawn"
    ["15"]="dracula"
    ["16"]="monokai-pro"
    ["17"]="solarized-dark"
    ["18"]="solarized-light"
    ["19"]="everforest-dark"
    ["20"]="everforest-light"
)

# Theme descriptions
declare -A THEME_DESC=(
    ["catppuccin-mocha"]="🟣 Dark purple elegance"
    ["catppuccin-macchiato"]="🔵 Warm blue comfort"
    ["catppuccin-latte"]="☕ Light coffee theme"
    ["catppuccin-frappe"]="🥐 Soft pastel theme"
    ["tokyonight-night"]="🌃 Cyberpunk night"
    ["tokyonight-storm"]="⛈️ Stormy blue theme"
    ["tokyonight-day"]="☀️ Bright day theme"
    ["gruvbox-dark"]="🟫 Retro warm dark"
    ["gruvbox-light"]="🟨 Retro warm light"
    ["nord"]="❄️ Arctic frost"
    ["nord-light"]="🏔️ Arctic light"
    ["rose-pine"]="🌹 Soft rose aesthetic"
    ["rose-pine-moon"]="🌙 Moonlit rose"
    ["rose-pine-dawn"]="🌅 Dawn rose"
    ["dracula"]="🧛 Classic vampire"
    ["monokai-pro"]="💻 Developer favorite"
    ["solarized-dark"]="🌒 Scientific dark"
    ["solarized-light"]="☀️ Scientific light"
    ["everforest-dark"]="🌲 Forest night"
    ["everforest-light"]="🌿 Forest day"
)

# Log functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Show banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════╗"
    echo "║        HYPRLAND THEME SWITCHER         ║"
    echo "║         20 Complete Themes             ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Display theme menu
show_themes() {
    echo -e "${CYAN}Available Themes:${NC}\n"
    
    echo -e "${PURPLE}Catppuccin Family:${NC}"
    echo "  1. Catppuccin Mocha     ${THEME_DESC[catppuccin-mocha]}"
    echo "  2. Catppuccin Macchiato ${THEME_DESC[catppuccin-macchiato]}"
    echo "  3. Catppuccin Latte     ${THEME_DESC[catppuccin-latte]}"
    echo "  4. Catppuccin Frappe    ${THEME_DESC[catppuccin-frappe]}"
    echo
    
    echo -e "${CYAN}TokyoNight Family:${NC}"
    echo "  5. TokyoNight Night     ${THEME_DESC[tokyonight-night]}"
    echo "  6. TokyoNight Storm     ${THEME_DESC[tokyonight-storm]}"
    echo "  7. TokyoNight Day       ${THEME_DESC[tokyonight-day]}"
    echo
    
    echo -e "${YELLOW}Gruvbox Family:${NC}"
    echo "  8. Gruvbox Dark         ${THEME_DESC[gruvbox-dark]}"
    echo "  9. Gruvbox Light        ${THEME_DESC[gruvbox-light]}"
    echo
    
    echo -e "${BLUE}Nord Family:${NC}"
    echo " 10. Nord                 ${THEME_DESC[nord]}"
    echo " 11. Nord Light           ${THEME_DESC[nord-light]}"
    echo
    
    echo -e "${RED}Rose Pine Family:${NC}"
    echo " 12. Rose Pine            ${THEME_DESC[rose-pine]}"
    echo " 13. Rose Pine Moon       ${THEME_DESC[rose-pine-moon]}"
    echo " 14. Rose Pine Dawn       ${THEME_DESC[rose-pine-dawn]}"
    echo
    
    echo -e "${PURPLE}Additional Themes:${NC}"
    echo " 15. Dracula              ${THEME_DESC[dracula]}"
    echo " 16. Monokai Pro          ${THEME_DESC[monokai-pro]}"
    echo " 17. Solarized Dark       ${THEME_DESC[solarized-dark]}"
    echo " 18. Solarized Light      ${THEME_DESC[solarized-light]}"
    echo " 19. Everforest Dark      ${THEME_DESC[everforest-dark]}"
    echo " 20. Everforest Light     ${THEME_DESC[everforest-light]}"
    echo
}

# Apply theme
apply_theme() {
    local theme=$1
    
    log "Applying theme: $theme"
    
    # Update Rofi theme
    if [ -f "$CONFIG_DIR/rofi/themes/${theme}.rasi" ]; then
        log "Updating Rofi theme..."
        sed -i "s/@import.*/@import \"themes\/${theme}.rasi\"/" "$CONFIG_DIR/rofi/config.rasi" 2>/dev/null || \
        echo "@import \"themes/${theme}.rasi\"" >> "$CONFIG_DIR/rofi/config.rasi"
        success "Rofi theme updated"
    else
        warning "Rofi theme file not found for $theme"
    fi
    
    # Update Kitty theme
    if [ -f "$CONFIG_DIR/kitty/themes/${theme}.conf" ]; then
        log "Updating Kitty theme..."
        sed -i "s/include themes.*/include themes\/${theme}.conf/" "$CONFIG_DIR/kitty/kitty.conf" 2>/dev/null || \
        echo "include themes/${theme}.conf" >> "$CONFIG_DIR/kitty/kitty.conf"
        success "Kitty theme updated"
        
        # Reload kitty if running
        killall -USR1 kitty 2>/dev/null || true
    else
        warning "Kitty theme file not found for $theme"
    fi
    
    # Update Waybar theme
    if [ -f "$CONFIG_DIR/waybar/themes/${theme}.css" ]; then
        log "Updating Waybar theme..."
        sed -i "s/@import.*/@import \"themes\/${theme}.css\";/" "$CONFIG_DIR/waybar/style.css" 2>/dev/null || \
        echo "@import \"themes/${theme}.css\";" > "$CONFIG_DIR/waybar/style.css.tmp" && \
        cat "$CONFIG_DIR/waybar/style.css" >> "$CONFIG_DIR/waybar/style.css.tmp" && \
        mv "$CONFIG_DIR/waybar/style.css.tmp" "$CONFIG_DIR/waybar/style.css"
        success "Waybar theme updated"
        
        # Restart waybar
        killall waybar 2>/dev/null || true
        waybar &>/dev/null &
        disown
    else
        warning "Waybar theme file not found for $theme"
    fi
    
    # Update wallpaper
    local wallpaper_file=""
    if [ -f "$WALLPAPER_DIR/${theme}.jpg" ]; then
        wallpaper_file="$WALLPAPER_DIR/${theme}.jpg"
    elif [ -f "$WALLPAPER_DIR/${theme}.png" ]; then
        wallpaper_file="$WALLPAPER_DIR/${theme}.png"
    elif [ -f "$WALLPAPER_DIR/default.jpg" ]; then
        wallpaper_file="$WALLPAPER_DIR/default.jpg"
    fi
    
    if [ -n "$wallpaper_file" ]; then
        log "Setting wallpaper..."
        swww img "$wallpaper_file" --transition-type grow --transition-pos center --transition-duration 1
        success "Wallpaper updated"
    else
        warning "No wallpaper found for theme $theme"
    fi
    
    # Save current theme
    echo "$theme" > "$CONFIG_DIR/.current-theme"
    
    success "Theme '$theme' applied successfully!"
}

# Get current theme
get_current_theme() {
    if [ -f "$CONFIG_DIR/.current-theme" ]; then
        cat "$CONFIG_DIR/.current-theme"
    else
        echo "none"
    fi
}

# Main menu
main() {
    show_banner
    
    # Show current theme
    current_theme=$(get_current_theme)
    if [ "$current_theme" != "none" ]; then
        echo -e "${GREEN}Current theme: $current_theme${NC}\n"
    fi
    
    show_themes
    
    # Get user selection
    while true; do
        read -p "Select theme (1-20, q to quit): " choice
        
        if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
            log "Exiting theme switcher"
            exit 0
        fi
        
        if [[ -n "${THEMES[$choice]}" ]]; then
            selected_theme="${THEMES[$choice]}"
            echo
            log "Selected: $selected_theme"
            apply_theme "$selected_theme"
            echo
            read -p "Press Enter to continue..."
            main
        else
            warning "Invalid selection. Please choose 1-20 or 'q' to quit."
        fi
    done
}

# Check dependencies
check_dependencies() {
    local deps=("swww" "rofi" "waybar" "kitty")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warning "Missing dependencies: ${missing[*]}"
        echo "Some features may not work properly."
        echo "Install missing packages with: sudo pacman -S ${missing[*]}"
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
}

# Initialize
check_dependencies

# Handle command line arguments
if [ $# -eq 1 ]; then
    # Direct theme application
    theme_name="$1"
    
    # Check if it's a number
    if [[ "$theme_name" =~ ^[0-9]+$ ]]; then
        if [[ -n "${THEMES[$theme_name]}" ]]; then
            apply_theme "${THEMES[$theme_name]}"
            exit 0
        else
            error "Invalid theme number: $theme_name"
        fi
    else
        # Try to apply by name
        for key in "${!THEMES[@]}"; do
            if [ "${THEMES[$key]}" = "$theme_name" ]; then
                apply_theme "$theme_name"
                exit 0
            fi
        done
        error "Unknown theme: $theme_name"
    fi
else
    # Interactive mode
    main
fi
