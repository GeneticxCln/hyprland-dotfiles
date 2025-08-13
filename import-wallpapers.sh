#!/bin/bash

# Simple Wallpaper Import - Use your existing collection
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_WALLPAPERS="$SCRIPT_DIR/wallpapers"
PERSONAL_WALLPAPERS="/home/sasha/Pictures/wallpapers"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${YELLOW}🖼️  Wallpaper Import System${NC}"
echo "Importing wallpapers from your personal collection..."
echo

if [ ! -d "$PERSONAL_WALLPAPERS" ]; then
    error "Personal wallpapers directory not found: $PERSONAL_WALLPAPERS"
fi

# Find actual available wallpapers and import them
echo "Available wallpapers:"
available_wallpapers=($(ls "$PERSONAL_WALLPAPERS"/*.{jpg,jpeg,png,webp} 2>/dev/null | head -20))

if [ ${#available_wallpapers[@]} -eq 0 ]; then
    error "No wallpapers found in $PERSONAL_WALLPAPERS"
fi

# Show some available wallpapers
for i in "${!available_wallpapers[@]}"; do
    if [ $i -lt 10 ]; then
        basename="${available_wallpapers[$i]##*/}"
        echo "  • $basename"
    fi
done

echo
log "Importing best matches..."

imported_count=0

# Use available wallpapers for themes
declare -A theme_mappings=(
    ["catppuccin-mocha"]="Anime-City-Night.png"
    ["catppuccin-macchiato"]="Anime-Room.png" 
    ["catppuccin-latte"]="Backyard.png"
    ["catppuccin-frappe"]="Fantasy-Landscape1.png"
    ["tokyonight-night"]="Anime-City-Night.png"
    ["tokyonight-storm"]="City-Rainy-Night.png"
    ["tokyonight-day"]="Anime-Japan-Street.png"
    ["gruvbox-dark"]="Garage.jpg"
    ["gruvbox-light"]="Backyard.png"
    ["nord"]="Under_Starlit_Sky.png"
    ["nord-light"]="Fantasy-Lake1.png"
    ["rose-pine"]="Flower-1.png"
    ["rose-pine-moon"]="Under_Starlit_Sky.png"
    ["rose-pine-dawn"]="Sunset-room.png"
    ["dracula"]="Anime-Purple-eyes.png"
    ["monokai-pro"]="IT_guy.png"
    ["solarized-dark"]="Minimal_Squares.png"
    ["solarized-light"]="Abstract - Nature.jpg"
    ["everforest-dark"]="Fantasy-Garden.png"
    ["everforest-light"]="Fantasy-Garden.png"
)

# Import wallpapers that exist
for theme in "${!theme_mappings[@]}"; do
    wallpaper_name="${theme_mappings[$theme]}"
    source_path="$PERSONAL_WALLPAPERS/$wallpaper_name"
    
    if [ -f "$source_path" ]; then
        extension="${wallpaper_name##*.}"
        dest_path="$PROJECT_WALLPAPERS/${theme}.${extension}"
        
        cp "$source_path" "$dest_path"
        success "✓ $theme ← $wallpaper_name"
        ((imported_count++))
    else
        # Try to find a similar wallpaper
        for wallpaper in "${available_wallpapers[@]}"; do
            wallpaper_basename=$(basename "$wallpaper")
            
            # Simple matching logic
            case "$theme" in
                *"dark"*|*"night"*|*"mocha"*)
                    if [[ "$wallpaper_basename" == *"dark"* || "$wallpaper_basename" == *"night"* || "$wallpaper_basename" == *"anime"* ]]; then
                        extension="${wallpaper_basename##*.}"
                        dest_path="$PROJECT_WALLPAPERS/${theme}.${extension}"
                        cp "$wallpaper" "$dest_path"
                        success "✓ $theme ← $wallpaper_basename (auto-matched)"
                        ((imported_count++))
                        break
                    fi
                    ;;
                *"light"*|*"day"*|*"latte"*)
                    if [[ "$wallpaper_basename" == *"light"* || "$wallpaper_basename" == *"day"* || "$wallpaper_basename" == *"nature"* ]]; then
                        extension="${wallpaper_basename##*.}"
                        dest_path="$PROJECT_WALLPAPERS/${theme}.${extension}"
                        cp "$wallpaper" "$dest_path"
                        success "✓ $theme ← $wallpaper_basename (auto-matched)"
                        ((imported_count++))
                        break
                    fi
                    ;;
                *"tokyo"*)
                    if [[ "$wallpaper_basename" == *"tokyo"* || "$wallpaper_basename" == *"city"* || "$wallpaper_basename" == *"anime"* ]]; then
                        extension="${wallpaper_basename##*.}"
                        dest_path="$PROJECT_WALLPAPERS/${theme}.${extension}"
                        cp "$wallpaper" "$dest_path"
                        success "✓ $theme ← $wallpaper_basename (auto-matched)"
                        ((imported_count++))
                        break
                    fi
                    ;;
            esac
        done
    fi
done

# Create default wallpaper from the first available one
if [ ! -f "$PROJECT_WALLPAPERS/default.jpg" ] && [ ! -f "$PROJECT_WALLPAPERS/default.png" ] && [ ${#available_wallpapers[@]} -gt 0 ]; then
    default_source="${available_wallpapers[0]}"
    default_basename=$(basename "$default_source")
    extension="${default_basename##*.}"
    
    cp "$default_source" "$PROJECT_WALLPAPERS/default.$extension"
    success "✓ default ← $default_basename"
    ((imported_count++))
fi

echo
success "Import completed! Imported $imported_count wallpapers."

# Show what was imported
echo
log "Checking imported wallpapers..."
ls -la "$PROJECT_WALLPAPERS"/*.{jpg,jpeg,png,webp} 2>/dev/null | while read -r line; do
    filename=$(echo "$line" | awk '{print $NF}')
    size=$(echo "$line" | awk '{print $5}' | numfmt --to=iec)
    echo "  ✓ $(basename "$filename") ($size)"
done

echo
echo "🎉 Your wallpaper system is now set up!"
echo
echo "Next steps:"
echo "• Test themes: ./theme-switcher.sh"  
echo "• Record demo: ./demo-themes.sh record"
echo "• Full management: ./wallpaper-manager.sh"
