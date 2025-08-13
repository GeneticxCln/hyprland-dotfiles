#!/bin/bash

# Configuration Verification Script
# Checks that all required configuration files are present

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TOTAL=0
FOUND=0
MISSING=0

echo "Configuration Files Verification"
echo "================================="
echo

# Function to check file
check_file() {
    local file=$1
    local description=$2
    TOTAL=$((TOTAL + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        echo "  └─ $file"
        FOUND=$((FOUND + 1))
    else
        echo -e "${RED}✗${NC} $description"
        echo "  └─ Missing: $file"
        MISSING=$((MISSING + 1))
    fi
}

# Function to check directory
check_dir() {
    local dir=$1
    local description=$2
    TOTAL=$((TOTAL + 1))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description directory exists"
        echo "  └─ $dir"
        FOUND=$((FOUND + 1))
    else
        echo -e "${RED}✗${NC} $description directory missing"
        echo "  └─ Expected: $dir"
        MISSING=$((MISSING + 1))
    fi
}

# Check main scripts
echo "Main Scripts:"
echo "-------------"
check_file "install.sh" "Main installation script"
check_file "setup.sh" "Quick setup script"
check_file "advanced-config.sh" "Advanced configuration"
check_file "nvidia-integration.sh" "NVIDIA integration"
check_file "sddm-setup.sh" "SDDM theme setup"
echo

# Check configuration files
echo "Configuration Files:"
echo "-------------------"
check_file "configs/hypr/hyprland.conf" "Hyprland configuration"
check_file "configs/waybar/config.jsonc" "Waybar configuration"
check_file "configs/waybar/style.css" "Waybar styles"
check_file "configs/dunst/dunstrc" "Dunst notification config"
check_file "configs/kitty/kitty.conf" "Kitty terminal config"
check_file "configs/rofi/config.rasi" "Rofi launcher config"
check_file "configs/quickshell/shell.qml" "Quickshell configuration"
echo

# Check theme files
echo "Theme Files:"
echo "------------"
check_file "configs/rofi/themes/catppuccin-mocha.rasi" "Catppuccin Mocha theme"
echo

# Check directories
echo "Directories:"
echo "------------"
check_dir "configs" "Main configs"
check_dir "scripts" "Scripts"
check_dir "wallpapers" "Wallpapers"
check_dir "configs/scripts" "Config scripts"
echo

# Check utility scripts
echo "Utility Scripts:"
echo "----------------"
check_file "scripts/utils/screenshot.sh" "Screenshot utility"
check_file "scripts/utils/volume-control.sh" "Volume control"
check_file "scripts/utils/brightness-control.sh" "Brightness control"
check_file "scripts/utils/wallpaper-changer.sh" "Wallpaper changer"
check_file "scripts/utils/system-monitor.sh" "System monitor"
echo

# Check AI scripts
echo "AI Automation Scripts:"
echo "---------------------"
check_file "scripts/ai/ai-manager.sh" "AI Manager"
check_file "scripts/ai/smart-optimizer.sh" "Smart Optimizer"
check_file "scripts/ai/predictive-maintenance.sh" "Predictive Maintenance"
check_file "scripts/ai/workload-automation.sh" "Workload Automation"
echo

# Summary
echo "================================="
echo "Verification Summary:"
echo "================================="
echo -e "Total checks: $TOTAL"
echo -e "${GREEN}Found: $FOUND${NC}"
if [ $MISSING -gt 0 ]; then
    echo -e "${RED}Missing: $MISSING${NC}"
else
    echo -e "${GREEN}All files present!${NC}"
fi
echo

# Exit code based on missing files
if [ $MISSING -gt 0 ]; then
    echo -e "${YELLOW}Some configuration files are missing.${NC}"
    echo "Run './install.sh' for full installation or check missing files."
    exit 1
else
    echo -e "${GREEN}All configuration files are in place!${NC}"
    echo "You can run './setup.sh' for quick installation."
    exit 0
fi
