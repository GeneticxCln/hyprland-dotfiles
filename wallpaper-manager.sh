#!/bin/bash

# Wallpaper Management System for Hyprland Project
# Imports, organizes, and manages theme-matching wallpapers
# Version: 1.0

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_WALLPAPERS="$SCRIPT_DIR/wallpapers"
PERSONAL_WALLPAPERS="/home/sasha/Pictures/wallpapers"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Theme mappings for wallpaper selection
declare -A THEME_KEYWORDS=(
    # Catppuccin themes
    ["catppuccin-mocha"]="dark purple night coffee lofi anime"
    ["catppuccin-macchiato"]="blue warm cozy coffee"
    ["catppuccin-latte"]="light coffee warm bright"
    ["catppuccin-frappe"]="pastel soft warm light"
    
    # TokyoNight themes  
    ["tokyonight-night"]="night city neon purple tokyo cyber"
    ["tokyonight-storm"]="storm rain city night blue"
    ["tokyonight-day"]="bright light city tokyo day"
    
    # Gruvbox themes
    ["gruvbox-dark"]="autumn warm retro nature forest"
    ["gruvbox-light"]="light warm nature bright"
    
    # Nord themes
    ["nord"]="northern lights aurora ice cold blue"
    ["nord-light"]="bright cold ice mountain light"
    
    # Rose Pine themes
    ["rose-pine"]="flower nature soft pink rose"
    ["rose-pine-moon"]="moon night soft dark"
    ["rose-pine-dawn"]="sunset dawn warm light"
    
    # Additional themes
    ["dracula"]="dark vampire red purple night"
    ["monokai-pro"]="dark night coding tech programmer"
    ["solarized-dark"]="dark technical minimal"
    ["solarized-light"]="bright minimal clean light"
    ["everforest-dark"]="forest nature dark green"
    ["everforest-light"]="forest nature light green bright"
)

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                🖼️  WALLPAPER MANAGEMENT SYSTEM 🖼️               ║
║                                                                  ║
║  Import, organize, and manage theme-matching wallpapers         ║
║  Smart theme detection and wallpaper assignment                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Analyze existing wallpapers
analyze_personal_wallpapers() {
    log "Analyzing personal wallpaper collection..."
    
    if [ ! -d "$PERSONAL_WALLPAPERS" ]; then
        warning "Personal wallpapers directory not found: $PERSONAL_WALLPAPERS"
        return 1
    fi
    
    local total=$(find "$PERSONAL_WALLPAPERS" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | wc -l)
    log "Found $total wallpapers in personal collection"
    
    # Show some examples
    echo -e "${CYAN}Sample wallpapers found:${NC}"
    find "$PERSONAL_WALLPAPERS" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | head -10 | while read -r file; do
        echo "  • $(basename "$file")"
    done
    
    if [ $total -gt 10 ]; then
        echo "  • ... and $((total - 10)) more wallpapers"
    fi
    echo
}

# Smart theme matching based on filename keywords
suggest_theme_for_wallpaper() {
    local wallpaper_file="$1"
    local basename=$(basename "$wallpaper_file" | tr '[:upper:]' '[:lower:]')
    local best_theme=""
    local best_score=0
    
    for theme in "${!THEME_KEYWORDS[@]}"; do
        local keywords="${THEME_KEYWORDS[$theme]}"
        local score=0
        
        # Check each keyword
        for keyword in $keywords; do
            if [[ "$basename" == *"$keyword"* ]]; then
                ((score++))
            fi
        done
        
        # Special scoring for common patterns
        case "$basename" in
            *"night"*|*"dark"*) 
                [[ "$theme" == *"night"* || "$theme" == *"dark"* || "$theme" == *"mocha"* ]] && ((score += 2))
                ;;
            *"light"*|*"bright"*|*"day"*)
                [[ "$theme" == *"light"* || "$theme" == *"day"* || "$theme" == *"latte"* ]] && ((score += 2))
                ;;
            *"city"*|*"urban"*|*"tokyo"*)
                [[ "$theme" == *"tokyo"* ]] && ((score += 3))
                ;;
            *"nature"*|*"forest"*|*"tree"*)
                [[ "$theme" == *"forest"* || "$theme" == *"gruvbox"* ]] && ((score += 3))
                ;;
            *"coffee"*|*"cafe"*|*"lofi"*)
                [[ "$theme" == *"catppuccin"* ]] && ((score += 3))
                ;;
            *"anime"*|*"manga"*)
                [[ "$theme" == *"tokyo"* || "$theme" == *"mocha"* ]] && ((score += 2))
                ;;
        esac
        
        if [ $score -gt $best_score ]; then
            best_score=$score
            best_theme=$theme
        fi
    done
    
    if [ $best_score -gt 0 ]; then
        echo "$best_theme"
    else
        echo "default"
    fi
}

# Import wallpapers with smart theme matching
import_wallpapers() {
    log "Starting smart wallpaper import process..."
    
    if [ ! -d "$PERSONAL_WALLPAPERS" ]; then
        error "Personal wallpapers directory not found: $PERSONAL_WALLPAPERS"
    fi
    
    # Create theme assignments associative array
    declare -A theme_assignments
    declare -A manual_assignments
    
    echo -e "${CYAN}Analyzing and assigning wallpapers to themes...${NC}\n"
    
    # First pass: automatic assignments
    while IFS= read -r -d '' wallpaper; do
        local basename=$(basename "$wallpaper")
        local suggested_theme=$(suggest_theme_for_wallpaper "$wallpaper")
        
        if [ "$suggested_theme" != "default" ]; then
            if [ -z "${theme_assignments[$suggested_theme]}" ]; then
                theme_assignments[$suggested_theme]="$wallpaper"
                echo -e "${GREEN}✓${NC} Auto-assigned: ${YELLOW}$basename${NC} → ${PURPLE}$suggested_theme${NC}"
            fi
        else
            manual_assignments["$wallpaper"]="$basename"
        fi
    done < <(find "$PERSONAL_WALLPAPERS" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) -print0)
    
    echo
    log "Auto-assignment complete. ${#theme_assignments[@]} themes assigned automatically."
    
    # Second pass: manual assignments for remaining themes
    local remaining_themes=()
    for theme in "${!THEME_KEYWORDS[@]}"; do
        if [ -z "${theme_assignments[$theme]}" ]; then
            remaining_themes+=("$theme")
        fi
    done
    
    if [ ${#remaining_themes[@]} -gt 0 ]; then
        echo -e "${YELLOW}Manual assignment needed for ${#remaining_themes[@]} themes:${NC}"
        
        for theme in "${remaining_themes[@]}"; do
            echo -e "\n${CYAN}Assigning wallpaper for theme: ${WHITE}$theme${NC}"
            echo "Keywords: ${THEME_KEYWORDS[$theme]}"
            echo
            
            if [ ${#manual_assignments[@]} -eq 0 ]; then
                warning "No unassigned wallpapers remaining. Using default."
                continue
            fi
            
            echo "Available wallpapers:"
            local i=1
            local wallpaper_list=()
            for wallpaper in "${!manual_assignments[@]}"; do
                echo "  $i. ${manual_assignments[$wallpaper]}"
                wallpaper_list[$i]="$wallpaper"
                ((i++))
            done
            echo "  $i. Skip (use default)"
            echo
            
            read -p "Select wallpaper for $theme (1-$i): " choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt $i ]; then
                local selected_wallpaper="${wallpaper_list[$choice]}"
                theme_assignments[$theme]="$selected_wallpaper"
                unset manual_assignments["$selected_wallpaper"]
                success "Assigned: ${manual_assignments[$selected_wallpaper]} → $theme"
            else
                log "Skipped $theme - will use default wallpaper"
            fi
        done
    fi
    
    # Copy wallpapers to project directory
    echo -e "\n${CYAN}Copying wallpapers to project directory...${NC}"
    
    for theme in "${!theme_assignments[@]}"; do
        local source_file="${theme_assignments[$theme]}"
        local extension="${source_file##*.}"
        local dest_file="$PROJECT_WALLPAPERS/${theme}.${extension}"
        
        cp "$source_file" "$dest_file"
        success "Copied: $(basename "$source_file") → ${theme}.${extension}"
    done
    
    # Create a default wallpaper if none exists
    if [ ! -f "$PROJECT_WALLPAPERS/default.jpg" ] && [ ! -f "$PROJECT_WALLPAPERS/default.png" ]; then
        log "Creating default wallpaper..."
        
        # Try to find a good default
        local default_candidates=()
        for wallpaper in "${!manual_assignments[@]}"; do
            local basename=$(basename "$wallpaper" | tr '[:upper:]' '[:lower:]')
            if [[ "$basename" == *"nature"* || "$basename" == *"landscape"* || "$basename" == *"abstract"* ]]; then
                default_candidates+=("$wallpaper")
            fi
        done
        
        if [ ${#default_candidates[@]} -gt 0 ]; then
            local default_source="${default_candidates[0]}"
            local extension="${default_source##*.}"
            cp "$default_source" "$PROJECT_WALLPAPERS/default.${extension}"
            success "Created default wallpaper: $(basename "$default_source")"
        fi
    fi
    
    echo
    success "Wallpaper import completed!"
    log "Imported wallpapers for ${#theme_assignments[@]} themes"
}

# Show current wallpaper assignments
show_wallpaper_status() {
    log "Current wallpaper assignments:"
    echo
    
    for theme in "${!THEME_KEYWORDS[@]}"; do
        local wallpaper_found=""
        
        # Check for different extensions
        for ext in jpg jpeg png webp; do
            if [ -f "$PROJECT_WALLPAPERS/${theme}.${ext}" ]; then
                wallpaper_found="$PROJECT_WALLPAPERS/${theme}.${ext}"
                break
            fi
        done
        
        if [ -n "$wallpaper_found" ]; then
            local size=$(du -h "$wallpaper_found" | cut -f1)
            echo -e "${GREEN}✓${NC} $theme → $(basename "$wallpaper_found") (${size})"
        else
            echo -e "${RED}✗${NC} $theme → No wallpaper assigned"
        fi
    done
    
    echo
    
    # Check for default wallpaper
    local default_found=""
    for ext in jpg jpeg png webp; do
        if [ -f "$PROJECT_WALLPAPERS/default.${ext}" ]; then
            default_found="$PROJECT_WALLPAPERS/default.${ext}"
            break
        fi
    done
    
    if [ -n "$default_found" ]; then
        local size=$(du -h "$default_found" | cut -f1)
        echo -e "${BLUE}Default wallpaper:${NC} $(basename "$default_found") (${size})"
    else
        echo -e "${YELLOW}Warning: No default wallpaper found${NC}"
    fi
}

# Download curated wallpapers from theme repositories
download_curated_wallpapers() {
    log "Downloading curated wallpapers from theme repositories..."
    
    local temp_dir="/tmp/hyprland-wallpapers"
    mkdir -p "$temp_dir"
    
    echo -e "${CYAN}This will download high-quality wallpapers matching each theme${NC}"
    echo "This requires internet connection and git."
    echo
    
    read -p "Continue with curated wallpaper download? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Skipping curated wallpaper download"
        return 0
    fi
    
    # Download Catppuccin wallpapers
    log "Downloading Catppuccin wallpapers..."
    if git clone --depth=1 https://github.com/catppuccin/wallpapers.git "$temp_dir/catppuccin" 2>/dev/null; then
        # Find suitable Catppuccin wallpapers
        find "$temp_dir/catppuccin" -name "*.jpg" -o -name "*.png" | head -4 | while read -r i; do
            local index=$(($(echo "$i" | grep -o '[0-9]*' | tail -1) % 4))
            local themes=("catppuccin-mocha" "catppuccin-macchiato" "catppuccin-latte" "catppuccin-frappe")
            local theme="${themes[$index]}"
            local ext="${i##*.}"
            
            if [ ! -f "$PROJECT_WALLPAPERS/${theme}.${ext}" ]; then
                cp "$i" "$PROJECT_WALLPAPERS/${theme}.${ext}" 2>/dev/null || true
                success "Downloaded: ${theme}.${ext}"
            fi
        done
    else
        warning "Failed to download Catppuccin wallpapers"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    success "Curated wallpaper download completed!"
}

# Main menu
show_menu() {
    echo -e "${CYAN}Wallpaper Management Options:${NC}"
    echo "  1. Analyze personal wallpaper collection"
    echo "  2. Import wallpapers with smart theme matching"
    echo "  3. Show current wallpaper assignments"
    echo "  4. Download curated theme wallpapers"
    echo "  5. Test wallpaper with current theme"
    echo "  6. Exit"
    echo
}

# Test wallpaper setting
test_wallpaper() {
    log "Testing wallpaper setting functionality..."
    
    if ! command -v swww &>/dev/null; then
        error "swww not found. Install with: sudo pacman -S swww"
    fi
    
    # Get current theme if available
    local current_theme=""
    if [ -f "$HOME/.config/.current-theme" ]; then
        current_theme=$(cat "$HOME/.config/.current-theme")
        log "Current theme: $current_theme"
    else
        log "No current theme set, using default"
        current_theme="default"
    fi
    
    # Find wallpaper for current theme
    local wallpaper_file=""
    for ext in jpg jpeg png webp; do
        if [ -f "$PROJECT_WALLPAPERS/${current_theme}.${ext}" ]; then
            wallpaper_file="$PROJECT_WALLPAPERS/${current_theme}.${ext}"
            break
        fi
    done
    
    if [ -z "$wallpaper_file" ]; then
        # Try default
        for ext in jpg jpeg png webp; do
            if [ -f "$PROJECT_WALLPAPERS/default.${ext}" ]; then
                wallpaper_file="$PROJECT_WALLPAPERS/default.${ext}"
                break
            fi
        done
    fi
    
    if [ -n "$wallpaper_file" ]; then
        log "Setting wallpaper: $(basename "$wallpaper_file")"
        swww img "$wallpaper_file" --transition-type grow --transition-pos center --transition-duration 1
        success "Wallpaper applied successfully!"
    else
        warning "No wallpaper found for theme: $current_theme"
    fi
}

# Main function
main() {
    show_banner
    
    while true; do
        show_menu
        read -p "Select option (1-6): " choice
        echo
        
        case $choice in
            1) analyze_personal_wallpapers ;;
            2) import_wallpapers ;;
            3) show_wallpaper_status ;;
            4) download_curated_wallpapers ;;
            5) test_wallpaper ;;
            6) 
                log "Exiting wallpaper manager"
                exit 0 
                ;;
            *) warning "Invalid choice. Please select 1-6." ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        clear
        show_banner
    done
}

# Check if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
