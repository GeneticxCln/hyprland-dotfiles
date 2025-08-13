#!/bin/bash
# Advanced Brightness Control with OSD
# Comprehensive brightness management for Hyprland

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
MAX_BRIGHTNESS=$(brightnessctl max)
CURRENT=$(brightnessctl get)
PERCENTAGE=$((CURRENT * 100 / MAX_BRIGHTNESS))

# Logging
log() { echo -e "${BLUE}[BRIGHTNESS]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Show OSD notification
show_osd() {
    local brightness_percent="$1"
    local bar_length=20
    local filled=$((brightness_percent * bar_length / 100))
    local empty=$((bar_length - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    notify-send "Brightness" "$brightness_percent% [$bar]" \
        -h int:value:$brightness_percent \
        -h string:x-canonical-private-synchronous:brightness \
        -t 2000 2>/dev/null || true
}

# Increase brightness
increase() {
    local step="${1:-5}"
    brightnessctl set "+${step}%"
    local new_percent=$(($(brightnessctl get) * 100 / MAX_BRIGHTNESS))
    show_osd "$new_percent"
    success "Brightness increased to $new_percent%"
}

# Decrease brightness
decrease() {
    local step="${1:-5}"
    brightnessctl set "${step}%-"
    local new_percent=$(($(brightnessctl get) * 100 / MAX_BRIGHTNESS))
    show_osd "$new_percent"
    success "Brightness decreased to $new_percent%"
}

# Set specific brightness
set_brightness() {
    local percent="$1"
    if [[ ! "$percent" =~ ^[0-9]+$ ]] || [ "$percent" -lt 1 ] || [ "$percent" -gt 100 ]; then
        warning "Invalid brightness value. Use 1-100"
        return 1
    fi
    
    brightnessctl set "${percent}%"
    show_osd "$percent"
    success "Brightness set to $percent%"
}

# Get current brightness
get_brightness() {
    echo -e "${GREEN}Current Brightness:${NC} $PERCENTAGE%"
    echo -e "${GREEN}Raw Value:${NC} $CURRENT/$MAX_BRIGHTNESS"
}

# Auto brightness based on time
auto_brightness() {
    local hour=$(date +%H)
    local target_brightness
    
    if [ "$hour" -ge 6 ] && [ "$hour" -lt 9 ]; then
        target_brightness=30  # Morning
    elif [ "$hour" -ge 9 ] && [ "$hour" -lt 18 ]; then
        target_brightness=80  # Day
    elif [ "$hour" -ge 18 ] && [ "$hour" -lt 22 ]; then
        target_brightness=50  # Evening
    else
        target_brightness=20  # Night
    fi
    
    log "Auto-adjusting brightness to $target_brightness% (time-based)"
    set_brightness "$target_brightness"
}

# Show help
show_help() {
    echo "Usage: brightness-control [command] [value]"
    echo
    echo "Commands:"
    echo "  up, + [step]       Increase brightness (default: 5%)"
    echo "  down, - [step]     Decrease brightness (default: 5%)"
    echo "  set [percent]      Set specific brightness (1-100%)"
    echo "  get                Show current brightness"
    echo "  auto               Auto-adjust based on time"
    echo "  help               Show this help message"
    echo
}

# Main execution
case "${1:-help}" in
    up|+) increase "$2" ;;
    down|-) decrease "$2" ;;
    set) set_brightness "$2" ;;
    get) get_brightness ;;
    auto) auto_brightness ;;
    help|*) show_help ;;
esac
