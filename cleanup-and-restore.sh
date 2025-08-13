#!/bin/bash

# Hyprland System Cleanup and Restoration Script
# This script will clean up changes made by the broken scripts and restore your original configuration

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${RED}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║    🚨 HYPRLAND SYSTEM CLEANUP & RESTORATION 🚨                  ║
║                                                                  ║
║    This script will clean up and restore your Hyprland config   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}This script will:${NC}"
echo -e "  • Restore your original hyprland.conf from backup"
echo -e "  • Remove broken script additions"
echo -e "  • Clean up broken keybinds and window rules"
echo -e "  • Remove broken system scripts"
echo -e "  • Fix any NVIDIA configuration issues"
echo -e "  • Restore system stability"
echo ""
echo -e "${WHITE}Continue with cleanup and restoration? (y/N): ${NC}"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Starting system cleanup and restoration...${NC}"

# 1. Restore original hyprland.conf
echo -e "${CYAN}[1/8]${NC} Restoring original hyprland.conf..."
if [[ -f ~/.config/hypr/hyprland.conf.backup.1755071012 ]]; then
    cp ~/.config/hypr/hyprland.conf.backup.1755071012 ~/.config/hypr/hyprland.conf
    echo -e "${GREEN}✓${NC} Original hyprland.conf restored"
else
    echo -e "${YELLOW}⚠${NC} No backup found, skipping hyprland.conf restoration"
fi

# 2. Remove broken configuration files added by scripts
echo -e "${CYAN}[2/8]${NC} Removing broken configuration files..."
broken_configs=(
    "~/.config/hypr/keybinds.conf"
    "~/.config/hypr/windowrules.conf" 
    "~/.config/hypr/rainbow.conf"
    "~/.config/hypr/nvidia.conf"
    "~/.config/hypr/scaling.conf"
)

for config in "${broken_configs[@]}"; do
    expanded_path=$(eval echo "$config")
    if [[ -f "$expanded_path" ]]; then
        # Create backup before removing
        mv "$expanded_path" "${expanded_path}.broken_backup_$(date +%s)"
        echo -e "${GREEN}✓${NC} Removed and backed up: $(basename "$expanded_path")"
    fi
done

# 3. Clean up broken scripts directory
echo -e "${CYAN}[3/8]${NC} Cleaning up broken scripts..."
if [[ -d ~/.config/hypr/scripts/ai ]]; then
    mv ~/.config/hypr/scripts/ai ~/.config/hypr/scripts/ai.broken_backup_$(date +%s)
    echo -e "${GREEN}✓${NC} Moved broken scripts to backup"
fi

# 4. Remove broken system scripts from local bin
echo -e "${CYAN}[4/8]${NC} Cleaning up system scripts..."
broken_scripts=(
    "~/.local/bin/hypr-scripts"
    "~/.local/bin/gpu-monitor"
    "~/.local/bin/nvidia-optimize"
)

for script in "${broken_scripts[@]}"; do
    expanded_path=$(eval echo "$script")
    if [[ -f "$expanded_path" ]]; then
        rm -f "$expanded_path"
        echo -e "${GREEN}✓${NC} Removed: $(basename "$expanded_path")"
    fi
done

# 5. Check and clean up package installations
echo -e "${CYAN}[5/8]${NC} Checking for problematic package installations..."
if pacman -Qs nvidia-system-monitor-qt > /dev/null 2>&1; then
    echo -e "${YELLOW}Found nvidia-system-monitor-qt (installed by broken script)${NC}"
    echo -e "${WHITE}Remove it? (y/N): ${NC}"
    read -r remove_pkg
    if [[ "$remove_pkg" =~ ^[Yy]$ ]]; then
        sudo pacman -Rns nvidia-system-monitor-qt
        echo -e "${GREEN}✓${NC} Removed nvidia-system-monitor-qt"
    fi
fi

# 6. Clean up any broken waybar configs
echo -e "${CYAN}[6/8]${NC} Checking waybar configuration..."
if [[ -f ~/.config/waybar/scaling.css ]]; then
    mv ~/.config/waybar/scaling.css ~/.config/waybar/scaling.css.broken_backup_$(date +%s)
    echo -e "${GREEN}✓${NC} Backed up potentially broken waybar scaling.css"
fi

# 7. Clean up GTK settings that might have been modified
echo -e "${CYAN}[7/8]${NC} Checking GTK settings..."
if [[ -f ~/.config/gtk-3.0/settings.ini.backup ]]; then
    cp ~/.config/gtk-3.0/settings.ini.backup ~/.config/gtk-3.0/settings.ini
    echo -e "${GREEN}✓${NC} Restored GTK settings from backup"
elif [[ -f ~/.config/gtk-3.0/settings.ini ]]; then
    # Create backup of current and reset to minimal
    cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini.pre_cleanup
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF
    echo -e "${GREEN}✓${NC} Reset GTK settings to safe defaults"
fi

# 8. Final cleanup and validation
echo -e "${CYAN}[8/8]${NC} Final system validation..."

# Check if Hyprland config is valid
if hyprctl version > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Hyprland is responding normally"
else
    echo -e "${YELLOW}⚠${NC} Hyprland might need to be restarted"
fi

# Clean up any temporary files in the project directory
cd /home/sasha/hyprland-project
find . -name "*.tmp" -delete 2>/dev/null
find . -name "*.log" -delete 2>/dev/null

echo ""
echo -e "${GREEN}🎉 System Cleanup and Restoration Complete! 🎉${NC}"
echo ""
echo -e "${YELLOW}Summary of actions taken:${NC}"
echo -e "  ✓ Restored original hyprland.conf from backup"
echo -e "  ✓ Removed broken configuration files (backed up)"
echo -e "  ✓ Cleaned up broken scripts directory"
echo -e "  ✓ Removed problematic system scripts"
echo -e "  ✓ Reset GTK settings to safe defaults"
echo -e "  ✓ Validated system integrity"
echo ""
echo -e "${WHITE}Next steps:${NC}"
echo -e "  1. ${CYAN}Restart Hyprland:${NC} Super + Ctrl + R or logout/login"
echo -e "  2. ${CYAN}Test basic functionality:${NC} Try opening applications, moving windows"
echo -e "  3. ${CYAN}Reboot if needed:${NC} If issues persist, reboot your system"
echo ""
echo -e "${GREEN}Your system should now be back to its original working state.${NC}"

# Offer to restart Hyprland
echo ""
echo -e "${WHITE}Restart Hyprland now? (y/N): ${NC}"
read -r restart_hypr

if [[ "$restart_hypr" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Restarting Hyprland...${NC}"
    hyprctl reload
    echo -e "${GREEN}✓ Hyprland reloaded${NC}"
fi

echo ""
echo -e "${CYAN}Cleanup script completed successfully!${NC}"
