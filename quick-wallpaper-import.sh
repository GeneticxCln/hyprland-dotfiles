#!/bin/bash

# Quick Wallpaper Import - Auto-import best matching wallpapers
# This script automatically selects the best wallpapers for each theme

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_WALLPAPERS="$SCRIPT_DIR/wallpapers"
PERSONAL_WALLPAPERS="/home/sasha/Pictures/wallpapers"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

echo -e "${YELLOW}🖼️  Quick Wallpaper Import${NC}"
echo "Auto-selecting best wallpapers for themes..."
echo

# Smart wallpaper selection based on filename analysis (actual files)
declare -A AUTO_SELECTIONS=(
    # Best matches found in your collection
    ["catppuccin-mocha"]="Anime-Room.png"                # Dark, anime, cozy
    ["catppuccin-macchiato"]="Coffee-1.png"              # Coffee, warm
    ["catppuccin-latte"]="Coffee-2.png"                  # Coffee, brighter
    ["catppuccin-frappe"]="Pastel-Window.png"            # Pastel, soft
    
    ["tokyonight-night"]="Anime-City-Night.png"          # City, night, anime
    ["tokyonight-storm"]="City-Rainy-Night.png"          # Rainy city night
    ["tokyonight-day"]="Tokyo_Pink.png"                  # Tokyo, bright
    
    ["gruvbox-dark"]="Fantasy-Autumn.png"                # Warm autumn colors
    ["gruvbox-light"]="Fantasy-Landscape1.png"           # Nature, bright
    
    ["nord"]="Northern Lights3.png"                      # Perfect match!
    ["nord-light"]="Northern Lights6.png"                # Light northern theme
    
    ["rose-pine"]="Flower-1.png"                         # Flower, nature
    ["rose-pine-moon"]="Under_Starlit_Sky.png"           # Night sky, stars
    ["rose-pine-dawn"]="Fantasy - Sunset.png"            # Dawn colors
    
    ["dracula"]="Dark_window.png"                        # Dark theme
    ["monokai-pro"]="IT_guy.png"                         # Tech/coding theme
    ["solarized-dark"]="Minimal_Squares.png"             # Minimal, technical
    ["solarized-light"]="Abstract - Nature.jpg"          # Clean, bright
    ["everforest-dark"]="Fog-Forest-Everforest.png"      # Perfect match!
    ["everforest-light"]="Fantasy-Garden.png"            # Nature, bright
)

log "Starting automatic wallpaper import..."

imported_count=0
for theme in "${!AUTO_SELECTIONS[@]}"; do
    wallpaper_name="${AUTO_SELECTIONS[$theme]}"
    source_path="$PERSONAL_WALLPAPERS/$wallpaper_name"
    
    if [ -f "$source_path" ]; then
        # Get file extension
        extension="${wallpaper_name##*.}"
        dest_path="$PROJECT_WALLPAPERS/${theme}.${extension}"
        
        # Copy the file
        cp "$source_path" "$dest_path"
        success "✓ $theme ← $wallpaper_name"
        ((imported_count++))
    else
        echo "  ⚠ Skipped $theme (wallpaper not found: $wallpaper_name)"
    fi
done

# Create a default wallpaper
if [ ! -f "$PROJECT_WALLPAPERS/default.jpg" ] && [ ! -f "$PROJECT_WALLPAPERS/default.png" ]; then
    default_source="$PERSONAL_WALLPAPERS/Fantasy-Landscape1.png"
    if [ -f "$default_source" ]; then
        cp "$default_source" "$PROJECT_WALLPAPERS/default.png"
        success "✓ default ← Fantasy-Landscape1.png"
        ((imported_count++))
    fi
fi

echo
success "Import completed! Imported $imported_count wallpapers."
log "Your themes now have beautiful, matching wallpapers!"

echo
echo "Next steps:"
echo "• Test with: ./theme-switcher.sh"
echo "• Record demo: ./demo-themes.sh record"
echo "• View status: ./wallpaper-manager.sh (option 3)"
