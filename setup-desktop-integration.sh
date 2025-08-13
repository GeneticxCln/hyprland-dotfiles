#!/bin/bash
# Desktop Integration Setup Script
# Seamlessly integrate all system scripts with Waybar and Rofi

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_CONFIG="$HOME/.config/hypr"
WAYBAR_CONFIG="$HOME/.config/waybar"
ROFI_CONFIG="$HOME/.config/rofi"

# Logging
log() { echo -e "${BLUE}[SETUP]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            Desktop Integration Setup                         ║"
echo "║        Hyprland Dotfiles GUI Integration                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("waybar" "rofi" "hyprctl" "notify-send")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        echo "Please install them first:"
        echo "  Arch: sudo pacman -S waybar rofi libnotify"
        echo "  Ubuntu: sudo apt install waybar rofi libnotify-bin"
        exit 1
    fi
    
    success "All dependencies found"
}

# Setup directory structure
setup_directories() {
    log "Setting up directory structure..."
    
    # Create config directories
    mkdir -p "$HYPR_CONFIG/scripts/waybar"
    mkdir -p "$HYPR_CONFIG/scripts/rofi"
    mkdir -p "$WAYBAR_CONFIG"
    mkdir -p "$ROFI_CONFIG/themes"
    
    success "Directory structure created"
}

# Install Waybar configuration
install_waybar_config() {
    log "Installing Waybar configuration..."
    
    # Copy main config
    cp "$PROJECT_DIR/configs/waybar/config.jsonc" "$WAYBAR_CONFIG/config.jsonc"
    cp "$PROJECT_DIR/configs/waybar/style.css" "$WAYBAR_CONFIG/style.css"
    
    # Copy Waybar scripts
    cp -r "$PROJECT_DIR/configs/scripts/waybar/"* "$HYPR_CONFIG/scripts/waybar/"
    
    # Make scripts executable
    chmod +x "$HYPR_CONFIG/scripts/waybar/"*.sh
    
    success "Waybar configuration installed"
}

# Install Rofi configuration
install_rofi_config() {
    log "Installing Rofi configuration..."
    
    # Copy Rofi scripts
    cp -r "$PROJECT_DIR/configs/scripts/rofi/"* "$HYPR_CONFIG/scripts/rofi/"
    
    # Make scripts executable
    chmod +x "$HYPR_CONFIG/scripts/rofi/"*.sh
    
    success "Rofi configuration installed"
}

# Create additional Waybar modules
create_additional_modules() {
    log "Creating additional Waybar modules..."
    
    # VPN Status Module
    cat > "$HYPR_CONFIG/scripts/waybar/vpn-status.sh" << 'EOF'
#!/bin/bash
# VPN Status Module for Waybar

# Check OpenVPN
if pgrep -x "openvpn" > /dev/null; then
    echo '{"text": "🔒 VPN", "class": "connected", "tooltip": "VPN Connected (OpenVPN)"}'
    exit 0
fi

# Check WireGuard
if wg show interfaces 2>/dev/null | grep -q "."; then
    echo '{"text": "🔒 VPN", "class": "connected", "tooltip": "VPN Connected (WireGuard)"}'
    exit 0
fi

# No VPN connection
echo '{"text": "🔓", "class": "disconnected", "tooltip": "VPN Disconnected - Click to connect"}'
EOF

    # Audio Profile Module
    cat > "$HYPR_CONFIG/scripts/waybar/audio-profile.sh" << 'EOF'
#!/bin/bash
# Audio Profile Module for Waybar

PROFILES_DIR="$HOME/.config/hypr/audio/profiles"

if [ -d "$PROFILES_DIR" ] && [ "$(ls -A "$PROFILES_DIR" 2>/dev/null)" ]; then
    PROFILE_COUNT=$(ls -1 "$PROFILES_DIR"/*.conf 2>/dev/null | wc -l)
    if [ "$PROFILE_COUNT" -gt 0 ]; then
        echo "{\"text\": \"🎵 $PROFILE_COUNT\", \"class\": \"active\", \"tooltip\": \"$PROFILE_COUNT audio profiles available\"}"
    else
        echo '{"text": "🎵", "class": "inactive", "tooltip": "No audio profiles - Click to create"}'
    fi
else
    echo '{"text": "🎵", "class": "inactive", "tooltip": "No audio profiles - Click to create"}'
fi
EOF

    # Theme Status Module
    cat > "$HYPR_CONFIG/scripts/waybar/theme-status.sh" << 'EOF'
#!/bin/bash
# Theme Status Module for Waybar

THEMES_DIR="$HOME/.config/hypr/theming/themes"

if [ -d "$THEMES_DIR" ] && [ "$(ls -A "$THEMES_DIR" 2>/dev/null)" ]; then
    THEME_COUNT=$(ls -1 "$THEMES_DIR"/*.conf 2>/dev/null | wc -l)
    if [ "$THEME_COUNT" -gt 0 ]; then
        echo "{\"text\": \"🎨 $THEME_COUNT\", \"class\": \"active\", \"tooltip\": \"$THEME_COUNT theme profiles available\"}"
    else
        echo '{"text": "🎨", "class": "inactive", "tooltip": "No theme profiles - Click to create"}'
    fi
else
    echo '{"text": "🎨", "class": "inactive", "tooltip": "No theme profiles - Click to create"}'
fi
EOF

    # Mobile Sync Status Module
    cat > "$HYPR_CONFIG/scripts/waybar/mobile-sync-status.sh" << 'EOF'
#!/bin/bash
# Mobile Sync Status Module for Waybar

# Check KDE Connect
if command -v kdeconnect-cli >/dev/null 2>&1; then
    DEVICES=$(kdeconnect-cli --list-devices --id-only 2>/dev/null | wc -l)
    CONNECTED=$(kdeconnect-cli --list-available --id-only 2>/dev/null | wc -l)
    
    if [ "$CONNECTED" -gt 0 ]; then
        echo "{\"text\": \"📱 $CONNECTED\", \"class\": \"connected\", \"tooltip\": \"$CONNECTED devices connected, $DEVICES total\"}"
    elif [ "$DEVICES" -gt 0 ]; then
        echo "{\"text\": \"📱 $DEVICES\", \"class\": \"paired\", \"tooltip\": \"$DEVICES devices paired, none connected\"}"
    else
        echo '{"text": "📱", "class": "inactive", "tooltip": "No devices paired - Click to setup"}'
    fi
else
    echo '{"text": "📱", "class": "inactive", "tooltip": "KDE Connect not installed"}'
fi
EOF

    # Weather Module
    cat > "$HYPR_CONFIG/scripts/waybar/weather.sh" << 'EOF'
#!/bin/bash
# Weather Module for Waybar

# Simple weather using curl (requires internet)
if command -v curl >/dev/null 2>&1 && ping -c 1 wttr.in >/dev/null 2>&1; then
    WEATHER=$(curl -s "wttr.in/?format=%C+%t" 2>/dev/null | head -1)
    if [ -n "$WEATHER" ]; then
        echo "{\"text\": \"$WEATHER\", \"tooltip\": \"Click for detailed weather\"}"
    else
        echo '{"text": "🌤️", "tooltip": "Weather unavailable"}'
    fi
else
    echo '{"text": "🌤️", "tooltip": "Weather offline"}'
fi
EOF

    # Make all modules executable
    chmod +x "$HYPR_CONFIG/scripts/waybar/"*.sh
    
    success "Additional Waybar modules created"
}

# Update Hyprland configuration
update_hyprland_config() {
    log "Updating Hyprland configuration..."
    
    local HYPRLAND_CONF="$HYPR_CONFIG/hyprland.conf"
    
    # Backup existing config
    if [ -f "$HYPRLAND_CONF" ]; then
        cp "$HYPRLAND_CONF" "$HYPRLAND_CONF.backup.$(date +%s)"
        warning "Existing hyprland.conf backed up"
    fi
    
    # Add desktop integration binds if not present
    if ! grep -q "# Desktop Integration Keybinds" "$HYPRLAND_CONF" 2>/dev/null; then
        cat >> "$HYPRLAND_CONF" << 'EOF'

# Desktop Integration Keybinds
# Added by setup-desktop-integration.sh

# Application launcher
bind = SUPER, SPACE, exec, ~/.config/hypr/scripts/rofi/launcher.sh

# System menu
bind = SUPER, ESCAPE, exec, ~/.config/hypr/scripts/rofi/system-menu.sh

# Power menu
bind = SUPER SHIFT, Q, exec, ~/.config/hypr/scripts/rofi/power-menu.sh

# Quick actions
bind = SUPER, G, exec, ~/hyprland-project/scripts/gaming/gaming-mode.sh toggle
bind = SUPER SHIFT, S, exec, ~/hyprland-project/scripts/utils/screenshot.sh selection
bind = SUPER CTRL, S, exec, ~/hyprland-project/scripts/utils/screenshot.sh full

# Volume controls (if no media keys)
bind = SUPER, EQUAL, exec, ~/hyprland-project/scripts/utils/volume-control.sh up
bind = SUPER, MINUS, exec, ~/hyprland-project/scripts/utils/volume-control.sh down
bind = SUPER SHIFT, M, exec, ~/hyprland-project/scripts/utils/volume-control.sh toggle

# Brightness controls (if no function keys)
bind = SUPER SHIFT, EQUAL, exec, ~/hyprland-project/scripts/utils/brightness-control.sh up
bind = SUPER SHIFT, MINUS, exec, ~/hyprland-project/scripts/utils/brightness-control.sh down

# Waybar restart
bind = SUPER SHIFT, B, exec, killall waybar && sleep 1 && waybar &

EOF
    fi
    
    # Add auto-start for Waybar if not present
    if ! grep -q "exec-once.*waybar" "$HYPRLAND_CONF" 2>/dev/null; then
        echo "exec-once = waybar" >> "$HYPRLAND_CONF"
    fi
    
    success "Hyprland configuration updated"
}

# Create desktop entry for system menu
create_desktop_entries() {
    log "Creating desktop entries..."
    
    mkdir -p "$HOME/.local/share/applications"
    
    # System Manager desktop entry
    cat > "$HOME/.local/share/applications/hyprland-system-manager.desktop" << EOF
[Desktop Entry]
Name=Hyprland System Manager
Comment=Comprehensive system management tools
Exec=$HYPR_CONFIG/scripts/rofi/system-menu.sh
Icon=applications-system
Type=Application
Categories=System;Settings;
Terminal=false
StartupWMClass=rofi
EOF
    
    success "Desktop entries created"
}

# Install system tray integration
setup_system_tray() {
    log "Setting up system tray integration..."
    
    # Create tray applications autostart directory
    mkdir -p "$HOME/.config/autostart"
    
    # NetworkManager applet
    if command -v nm-applet >/dev/null 2>&1; then
        cat > "$HOME/.config/autostart/nm-applet.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Exec=nm-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=NetworkManager Applet
Comment=Network Manager
EOF
    fi
    
    # Bluetooth applet
    if command -v blueman-applet >/dev/null 2>&1; then
        cat > "$HOME/.config/autostart/blueman-applet.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Exec=blueman-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Bluetooth Manager
Comment=Bluetooth Manager
EOF
    fi
    
    success "System tray integration setup complete"
}

# Final configuration
finalize_setup() {
    log "Finalizing setup..."
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    # Create quick-access script
    cat > "$HOME/.local/bin/hyprland-system" << EOF
#!/bin/bash
# Quick access to Hyprland system management
exec $HYPR_CONFIG/scripts/rofi/system-menu.sh
EOF
    chmod +x "$HOME/.local/bin/hyprland-system" 2>/dev/null || true
    
    success "Setup finalized"
}

# Main execution
main() {
    check_dependencies
    setup_directories
    install_waybar_config
    install_rofi_config
    create_additional_modules
    update_hyprland_config
    create_desktop_entries
    setup_system_tray
    finalize_setup
    
    echo
    echo -e "${GREEN}🎉 Desktop Integration Setup Complete! 🎉${NC}"
    echo
    echo "Next steps:"
    echo "1. Restart Hyprland or run: hyprctl reload"
    echo "2. Start Waybar: waybar &"
    echo "3. Test the launcher: Super + Space"
    echo "4. Access system menu: Super + Escape"
    echo "5. Power menu: Super + Shift + Q"
    echo
    echo "Key bindings added:"
    echo "  Super + Space      - Application launcher"
    echo "  Super + Escape     - System menu"
    echo "  Super + G          - Toggle gaming mode"
    echo "  Super + Shift + S  - Screenshot selection"
    echo "  Super + Ctrl + S   - Screenshot full"
    echo "  Super + Shift + B  - Restart Waybar"
    echo
    echo -e "${CYAN}Enjoy your enhanced Hyprland experience! 🚀${NC}"
}

# Run main function
main "$@"
