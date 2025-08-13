#!/bin/bash

# Test Installation Script
# Verifies that the Hyprland setup is working correctly

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Hyprland Installation Test${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Test 1: Check if Hyprland is installed
echo -n "Checking Hyprland installation... "
if command -v Hyprland &>/dev/null; then
    echo -e "${GREEN}✓ Installed${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
fi

# Test 2: Check if Waybar is installed
echo -n "Checking Waybar installation... "
if command -v waybar &>/dev/null; then
    echo -e "${GREEN}✓ Installed${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
fi

# Test 3: Check if configuration files exist
echo -n "Checking Hyprland config... "
if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

echo -n "Checking Waybar config... "
if [ -f "$HOME/.config/waybar/config.jsonc" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

echo -n "Checking Kitty config... "
if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

echo -n "Checking Rofi config... "
if [ -f "$HOME/.config/rofi/config.rasi" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

echo -n "Checking Dunst config... "
if [ -f "$HOME/.config/dunst/dunstrc" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

# Test 4: Check if essential utilities are installed
echo
echo "Essential utilities:"
for cmd in kitty rofi dunst grim slurp swww; do
    echo -n "  $cmd: "
    if command -v $cmd &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
done

echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}Test completed!${NC}"
echo
echo "To start Hyprland:"
echo "  1. Log out of your current session"
echo "  2. Select Hyprland from your display manager"
echo "  3. Or run 'Hyprland' from TTY"
echo
echo "Basic keybinds:"
echo "  Super+Return - Open terminal"
echo "  Super+Space  - Open app launcher"
echo "  Super+Q      - Close window"
echo "  Super+M      - Exit Hyprland"
