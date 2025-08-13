#!/bin/bash

# Theme Demo Script for Video Recording
# Shows all 20 themes with smooth transitions
# Perfect for creating showcase videos

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Demo settings
DEMO_DELAY=5  # Seconds between theme switches
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Theme list with descriptions
declare -A DEMO_THEMES=(
    ["catppuccin-mocha"]="🟣 Catppuccin Mocha - Dark purple elegance"
    ["catppuccin-macchiato"]="🔵 Catppuccin Macchiato - Warm blue comfort"
    ["catppuccin-latte"]="☕ Catppuccin Latte - Light coffee theme"
    ["catppuccin-frappe"]="🥐 Catppuccin Frappe - Soft pastel theme"
    ["tokyonight-night"]="🌃 TokyoNight Night - Cyberpunk darkness"
    ["tokyonight-storm"]="⛈️ TokyoNight Storm - Stormy blue theme"
    ["tokyonight-day"]="☀️ TokyoNight Day - Bright day theme"
    ["gruvbox-dark"]="🟫 Gruvbox Dark - Retro warm dark"
    ["gruvbox-light"]="🟨 Gruvbox Light - Retro warm light"
    ["nord"]="❄️ Nord - Arctic frost"
    ["nord-light"]="🏔️ Nord Light - Arctic light"
    ["rose-pine"]="🌹 Rose Pine - Soft rose aesthetic"
    ["rose-pine-moon"]="🌙 Rose Pine Moon - Moonlit rose"
    ["rose-pine-dawn"]="🌅 Rose Pine Dawn - Dawn rose"
    ["dracula"]="🧛 Dracula - Classic vampire"
    ["monokai-pro"]="💻 Monokai Pro - Developer favorite"
    ["solarized-dark"]="🌒 Solarized Dark - Scientific dark"
    ["solarized-light"]="☀️ Solarized Light - Scientific light"
    ["everforest-dark"]="🌲 Everforest Dark - Forest night"
    ["everforest-light"]="🌿 Everforest Light - Forest day"
)

# Theme order for demo
THEME_ORDER=(
    "catppuccin-mocha"
    "catppuccin-macchiato"
    "catppuccin-latte"
    "catppuccin-frappe"
    "tokyonight-night"
    "tokyonight-storm"
    "tokyonight-day"
    "gruvbox-dark"
    "gruvbox-light"
    "nord"
    "nord-light"
    "rose-pine"
    "rose-pine-moon"
    "rose-pine-dawn"
    "dracula"
    "monokai-pro"
    "solarized-dark"
    "solarized-light"
    "everforest-dark"
    "everforest-light"
)

log() { echo -e "${BLUE}[DEMO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║                  🎬 THEME SHOWCASE DEMO MODE 🎬                   ║
║                                                                    ║
║  Perfect for recording videos and showcasing all 20 themes        ║
║  Each theme displays for 5 seconds with smooth transitions        ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

show_theme_info() {
    local theme="$1"
    local description="${DEMO_THEMES[$theme]}"
    local count="$2"
    local total="$3"
    
    clear
    echo -e "${CYAN}╭─────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                THEME SHOWCASE                       │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────╯${NC}"
    echo
    echo -e "${WHITE}Theme $count of $total:${NC}"
    echo -e "${GREEN}$description${NC}"
    echo
    echo -e "${YELLOW}Applied: $(date '+%H:%M:%S')${NC}"
    echo -e "${BLUE}Next theme in $DEMO_DELAY seconds...${NC}"
    echo
    echo -e "${PURPLE}Recording Tips:${NC}"
    echo "• Switch to different applications to show theme consistency"
    echo "• Open terminal, file manager, and rofi launcher"
    echo "• Notice wallpaper coordination and color harmony"
    echo "• Observe smooth theme transitions"
}

apply_demo_theme() {
    local theme="$1"
    
    # Apply theme using existing theme switcher
    if [ -f "$SCRIPT_DIR/theme-switcher.sh" ]; then
        "$SCRIPT_DIR/theme-switcher.sh" "$theme" &>/dev/null || {
            warning "Failed to apply theme $theme using theme-switcher.sh"
            return 1
        }
    else
        warning "theme-switcher.sh not found - manual theme application needed"
        return 1
    fi
}

demo_mode() {
    show_banner
    
    log "Starting theme showcase demo..."
    log "Each theme will display for $DEMO_DELAY seconds"
    echo
    
    read -p "Press Enter to start demo, or Ctrl+C to cancel..."
    
    local total=${#THEME_ORDER[@]}
    local count=1
    
    for theme in "${THEME_ORDER[@]}"; do
        log "Applying theme: $theme ($count/$total)"
        
        if apply_demo_theme "$theme"; then
            show_theme_info "$theme" "$count" "$total"
            
            # Show countdown
            for i in $(seq $DEMO_DELAY -1 1); do
                echo -ne "\r${YELLOW}Next theme in: $i seconds...${NC} "
                sleep 1
            done
            echo
        else
            error "Failed to apply theme: $theme"
        fi
        
        ((count++))
    done
    
    success "Theme showcase demo completed!"
    echo
    echo -e "${GREEN}All 20 themes have been demonstrated!${NC}"
    echo -e "${BLUE}Perfect for creating showcase videos${NC}"
    echo
    echo "Recording suggestions:"
    echo "• Edit the video to show 2-3 seconds per theme"
    echo "• Add smooth transitions between theme switches"
    echo "• Include desktop applications to show consistency"
    echo "• Highlight unique features of each theme family"
}

interactive_mode() {
    show_banner
    
    echo "Interactive theme demo mode"
    echo "Press Enter to advance to next theme, or 'q' to quit"
    echo
    
    local total=${#THEME_ORDER[@]}
    local count=1
    
    for theme in "${THEME_ORDER[@]}"; do
        log "Theme $count/$total: ${DEMO_THEMES[$theme]}"
        
        if apply_demo_theme "$theme"; then
            echo -e "${GREEN}✓ Applied theme: $theme${NC}"
        else
            warning "Failed to apply theme: $theme"
        fi
        
        echo
        read -p "Press Enter for next theme (or 'q' to quit): " input
        
        if [[ "$input" = "q" || "$input" = "Q" ]]; then
            log "Demo stopped by user"
            break
        fi
        
        ((count++))
    done
    
    success "Interactive demo completed!"
}

record_mode() {
    show_banner
    
    echo -e "${RED}🔴 RECORDING MODE${NC}"
    echo
    echo "This mode is optimized for video recording:"
    echo "• Faster transitions (3 seconds per theme)"
    echo "• No interactive prompts"
    echo "• Optimized for screen capture"
    echo
    
    DEMO_DELAY=3  # Faster for recording
    
    read -p "Start recording and press Enter when ready..."
    
    local total=${#THEME_ORDER[@]}
    local count=1
    
    for theme in "${THEME_ORDER[@]}"; do
        apply_demo_theme "$theme" || continue
        
        # Minimal overlay for recording
        echo -ne "\r${WHITE}Theme: ${DEMO_THEMES[$theme]} ($count/$total)${NC}"
        
        sleep $DEMO_DELAY
        ((count++))
    done
    
    echo
    success "Recording demo completed!"
}

show_help() {
    echo "Theme Demo Script - Showcase all 20 themes"
    echo
    echo "Usage: $0 [mode]"
    echo
    echo "Modes:"
    echo "  demo      - Auto demo with 5-second intervals (default)"
    echo "  interactive - Manual control, press Enter for next theme"
    echo "  record    - Optimized for video recording (3-second intervals)"
    echo "  help      - Show this help message"
    echo
    echo "Examples:"
    echo "  $0                  # Run auto demo"
    echo "  $0 interactive      # Interactive mode"
    echo "  $0 record          # Recording mode"
    echo
    echo "Before recording:"
    echo "  1. Start your screen recording software"
    echo "  2. Set up desktop with terminal and applications open"
    echo "  3. Run: $0 record"
    echo "  4. Stop recording when demo completes"
}

# Check dependencies
if ! command -v swww &> /dev/null; then
    warning "swww not installed - wallpaper changes may not work"
fi

if [ ! -f "$SCRIPT_DIR/theme-switcher.sh" ]; then
    error "theme-switcher.sh not found in $SCRIPT_DIR"
fi

# Parse arguments
case "${1:-demo}" in
    "demo")
        demo_mode
        ;;
    "interactive")
        interactive_mode
        ;;
    "record")
        record_mode
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown mode: $1"
        show_help
        exit 1
        ;;
esac
