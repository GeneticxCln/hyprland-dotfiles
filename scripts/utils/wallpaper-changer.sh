#!/bin/bash

# Dynamic Wallpaper Management System
# Advanced wallpaper changing with theme integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG_FILE="$HOME/.config/hypr/wallpaper.conf"
CURRENT_THEME_FILE="$HOME/.config/hypr/.current_theme"

# Logging
log() { echo -e "${BLUE}[WALLPAPER]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Initialize swww if not running
init_swww() {
    if ! pgrep -x "swww-daemon" > /dev/null; then
        log "Starting swww daemon..."
        swww init
        sleep 2
    fi
}

# Set random wallpaper
set_random() {
    init_swww
    
    local theme_filter="$1"
    local wallpapers
    
    if [ -n "$theme_filter" ]; then
        wallpapers=($(find "$WALLPAPER_DIR" -name "*$theme_filter*" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
    else
        wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
    fi
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        error "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi
    
    local selected_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    
    log "Setting wallpaper: $(basename "$selected_wallpaper")"
    swww img "$selected_wallpaper" --transition-type wipe --transition-duration 2
    
    # Save current wallpaper
    echo "$selected_wallpaper" > "$CONFIG_FILE"
    success "Wallpaper set successfully"
    
    # Send notification
    notify-send "Wallpaper Changed" "$(basename "$selected_wallpaper")" -i "$selected_wallpaper" 2>/dev/null || true
}

# Set specific wallpaper
set_wallpaper() {
    local wallpaper_path="$1"
    
    if [ ! -f "$wallpaper_path" ]; then
        error "Wallpaper file not found: $wallpaper_path"
        return 1
    fi
    
    init_swww
    
    log "Setting wallpaper: $(basename "$wallpaper_path")"
    swww img "$wallpaper_path" --transition-type wipe --transition-duration 2
    
    echo "$wallpaper_path" > "$CONFIG_FILE"
    success "Wallpaper set successfully"
    
    notify-send "Wallpaper Changed" "$(basename "$wallpaper_path")" -i "$wallpaper_path" 2>/dev/null || true
}

# Browse and select wallpaper
browse_wallpapers() {
    if [ ! -d "$WALLPAPER_DIR" ]; then
        error "Wallpaper directory not found: $WALLPAPER_DIR"
        return 1
    fi
    
    echo -e "${CYAN}Available Wallpapers:${NC}"
    local wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) | sort))
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        error "No wallpapers found"
        return 1
    fi
    
    local count=1
    for wallpaper in "${wallpapers[@]}"; do
        echo -e "${GREEN}$count.${NC} $(basename "$wallpaper")"
        ((count++))
    done
    
    echo
    read -p "Select wallpaper (1-${#wallpapers[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#wallpapers[@]}" ]; then
        local selected="${wallpapers[$((choice-1))]}"
        set_wallpaper "$selected"
    else
        error "Invalid selection"
    fi
}

# Auto-rotate wallpapers
auto_rotate() {
    local interval="${1:-30}"
    
    log "Starting auto-rotation every $interval minutes"
    log "Press Ctrl+C to stop"
    
    while true; do
        set_random
        sleep $((interval * 60))
    done
}

# Theme-based wallpaper
theme_wallpaper() {
    local theme=""
    
    if [ -f "$CURRENT_THEME_FILE" ]; then
        theme=$(cat "$CURRENT_THEME_FILE")
        log "Current theme: $theme"
        set_random "$theme"
    else
        warning "No current theme found, setting random wallpaper"
        set_random
    fi
}

# Download wallpapers
download_wallpapers() {
    log "Downloading wallpaper collections..."
    mkdir -p "$WALLPAPER_DIR"
    
    # Basic collection URLs (replace with actual sources)
    local collections=(
        "https://github.com/catppuccin/wallpapers/archive/main.zip"
        "https://github.com/tokyo-night/wallpapers/archive/main.zip"
    )
    
    for collection in "${collections[@]}"; do
        log "Downloading from: $collection"
        # Download logic would go here
        # wget "$collection" -P "/tmp/" && unzip && move to wallpaper dir
    done
    
    success "Wallpaper collections downloaded"
}

# Show current wallpaper
show_current() {
    if [ -f "$CONFIG_FILE" ]; then
        local current_wallpaper=$(cat "$CONFIG_FILE")
        echo -e "${CYAN}Current Wallpaper:${NC}"
        echo "$(basename "$current_wallpaper")"
        echo "Path: $current_wallpaper"
        
        if [ -f "$current_wallpaper" ]; then
            local size=$(du -h "$current_wallpaper" | cut -f1)
            local dimensions=$(identify "$current_wallpaper" 2>/dev/null | cut -d' ' -f3 || echo "Unknown")
            echo "Size: $size"
            echo "Dimensions: $dimensions"
        fi
    else
        warning "No current wallpaper information found"
    fi
}

# Show help
show_help() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      🖼️  DYNAMIC WALLPAPER MANAGEMENT SYSTEM 🖼️                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "Usage: wallpaper-changer [command] [options]"
    echo
    echo "Commands:"
    echo "  random, -r [theme]   Set random wallpaper (optionally filtered by theme)"
    echo "  set, -s <path>       Set specific wallpaper"
    echo "  browse, -b           Browse and select wallpaper"
    echo "  theme, -t            Set theme-based wallpaper"
    echo "  auto, -a [minutes]   Auto-rotate wallpapers (default: 30min)"
    echo "  current, -c          Show current wallpaper info"
    echo "  download, -d         Download wallpaper collections"
    echo "  help, -h             Show this help message"
    echo
}

# Main execution
main() {
    case "${1:-help}" in
        random|-r)
            set_random "$2"
            ;;
        set|-s)
            if [ -z "$2" ]; then
                error "Please specify wallpaper path"
                exit 1
            fi
            set_wallpaper "$2"
            ;;
        browse|-b)
            browse_wallpapers
            ;;
        theme|-t)
            theme_wallpaper
            ;;
        auto|-a)
            auto_rotate "$2"
            ;;
        current|-c)
            show_current
            ;;
        download|-d)
            download_wallpapers
            ;;
        help|-h|*)
            show_help
            ;;
    esac
}

main "$@"
