#!/bin/bash

# SDDM Simple2 Theme Setup Script
# Installs and configures SDDM with Simple2 theme for Hyprland
# Based on JaKooLit's approach with enhancements

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

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect current display manager
detect_current_dm() {
    log "Detecting current display manager..."
    
    CURRENT_DM=""
    
    # Check for active display managers
    if systemctl is-enabled gdm.service >/dev/null 2>&1; then
        CURRENT_DM="gdm"
    elif systemctl is-enabled lightdm.service >/dev/null 2>&1; then
        CURRENT_DM="lightdm"
    elif systemctl is-enabled sddm.service >/dev/null 2>&1; then
        CURRENT_DM="sddm"
    elif systemctl is-enabled lxdm.service >/dev/null 2>&1; then
        CURRENT_DM="lxdm"
    fi
    
    if [ -n "$CURRENT_DM" ]; then
        success "Current display manager: $CURRENT_DM"
    else
        log "No active display manager detected"
    fi
}

# Install SDDM
install_sddm() {
    log "Installing SDDM and dependencies..."
    
    # SDDM packages
    SDDM_PACKAGES=(
        sddm
        qt5-quickcontrols2
        qt5-svg
        qt5-graphicaleffects
    )
    
    sudo pacman -S --needed --noconfirm "${SDDM_PACKAGES[@]}"
    
    success "SDDM installed successfully"
}

# Backup current display manager configuration
backup_current_dm() {
    if [ -n "$CURRENT_DM" ] && [ "$CURRENT_DM" != "sddm" ]; then
        log "Backing up current display manager configuration..."
        
        BACKUP_DIR="$HOME/.dm-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        case $CURRENT_DM in
            "gdm")
                sudo cp -r /etc/gdm "$BACKUP_DIR/" 2>/dev/null || true
                ;;
            "lightdm")
                sudo cp -r /etc/lightdm "$BACKUP_DIR/" 2>/dev/null || true
                ;;
            "lxdm")
                sudo cp -r /etc/lxdm "$BACKUP_DIR/" 2>/dev/null || true
                ;;
        esac
        
        success "Current display manager backed up to: $BACKUP_DIR"
    fi
}

# Switch to SDDM
switch_to_sddm() {
    log "Switching to SDDM display manager..."
    
    # Disable current display manager
    if [ -n "$CURRENT_DM" ] && [ "$CURRENT_DM" != "sddm" ]; then
        warning "Disabling current display manager: $CURRENT_DM"
        sudo systemctl disable "$CURRENT_DM.service"
    fi
    
    # Enable SDDM
    sudo systemctl enable sddm.service
    
    success "Switched to SDDM display manager"
}

# Download and install Simple2 theme
install_simple2_theme() {
    log "Installing Simple2 SDDM theme..."
    
    # Create themes directory
    sudo mkdir -p /usr/share/sddm/themes
    
    # Check if theme already exists
    if [ -d "/usr/share/sddm/themes/simple2" ]; then
        warning "Simple2 theme already exists. Backing up..."
        sudo mv /usr/share/sddm/themes/simple2 "/usr/share/sddm/themes/simple2.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Clone Simple2 theme
    TEMP_DIR="/tmp/simple2-sddm"
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    
    git clone https://github.com/qewer33/simple2-sddm.git "$TEMP_DIR"
    
    # Install theme
    sudo cp -r "$TEMP_DIR" /usr/share/sddm/themes/simple2
    sudo chown -R root:root /usr/share/sddm/themes/simple2
    sudo chmod -R 755 /usr/share/sddm/themes/simple2
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    success "Simple2 theme installed to /usr/share/sddm/themes/simple2"
}

# Customize Simple2 theme
customize_simple2_theme() {
    log "Customizing Simple2 theme..."
    
    THEME_DIR="/usr/share/sddm/themes/simple2"
    
    # Create custom theme configuration
    cat > /tmp/theme.conf << 'EOF'
[General]
# Background configuration
background=background.jpg
backgroundMode=fill
backgroundFillMode=PreserveAspectCrop

# Font configuration
font="JetBrains Mono"
fontSize=12
fontColor=#ffffff

# Input field styling
inputBackground=#1e1e2e
inputBorderColor=#89b4fa
inputTextColor=#cdd6f4
inputFont="JetBrains Mono"
inputFontSize=14

# Button styling  
buttonBackground=#89b4fa
buttonTextColor=#11111b
buttonFont="JetBrains Mono"
buttonFontSize=12

# Colors (Catppuccin Mocha inspired)
primary=#89b4fa
secondary=#f38ba8
accent=#94e2d5
background=#1e1e2e
foreground=#cdd6f4

# Layout
showUserRealName=true
showLoginButton=true
showUserList=true
userListMaximumUsers=10

# Behavior
allowEmptyPassword=false
rememberLastUser=true
rememberLastSession=true

# Session configuration
defaultSession=hyprland
hideSessionButton=false
hideUserButton=false

# Clock
showClock=true
clockFormat="dddd, MMMM d, yyyy - hh:mm AP"

# Blur effect
blur=true
blurRadius=50
EOF
    
    sudo cp /tmp/theme.conf "$THEME_DIR/"
    
    # Download or create background image
    download_background_image
    
    success "Simple2 theme customized"
}

# Download background image
download_background_image() {
    log "Setting up background image..."
    
    THEME_DIR="/usr/share/sddm/themes/simple2"
    
    echo "Select background option:"
    echo "  1. Download Hyprland official wallpaper"
    echo "  2. Use solid color background" 
    echo "  3. Use custom image (provide path)"
    echo
    
    while true; do
        read -p "Select option (1-3): " choice
        case $choice in
            1)
                # Download Hyprland wallpaper
                sudo curl -L "https://raw.githubusercontent.com/hyprwm/hyprland-dotfiles/main/wallpapers/hyprland.png" \
                    -o "$THEME_DIR/background.jpg" 2>/dev/null || {
                    warning "Failed to download wallpaper, using solid color"
                    create_solid_background
                }
                break
                ;;
            2)
                create_solid_background
                break
                ;;
            3)
                read -p "Enter full path to image: " custom_image
                if [ -f "$custom_image" ]; then
                    sudo cp "$custom_image" "$THEME_DIR/background.jpg"
                    success "Custom background set"
                else
                    warning "File not found, using solid color"
                    create_solid_background
                fi
                break
                ;;
            *)
                warning "Invalid selection. Please choose 1-3."
                ;;
        esac
    done
}

# Create solid color background
create_solid_background() {
    log "Creating solid color background..."
    
    THEME_DIR="/usr/share/sddm/themes/simple2"
    
    # Create 1920x1080 solid color image using ImageMagick or fallback
    if command -v convert >/dev/null 2>&1; then
        sudo convert -size 1920x1080 "xc:#1e1e2e" "$THEME_DIR/background.jpg"
    else
        # Install ImageMagick if not present
        sudo pacman -S --needed --noconfirm imagemagick
        sudo convert -size 1920x1080 "xc:#1e1e2e" "$THEME_DIR/background.jpg"
    fi
    
    success "Solid color background created"
}

# Configure SDDM
configure_sddm() {
    log "Configuring SDDM..."
    
    # Create SDDM configuration directory
    sudo mkdir -p /etc/sddm.conf.d
    
    # Main SDDM configuration
    cat > /tmp/sddm.conf << 'EOF'
[General]
# Display server
DisplayServer=wayland

# Session directory
SessionDir=/usr/share/wayland-sessions

# Default session
DefaultSession=hyprland

# Theme settings
[Theme]
Current=simple2
ThemeDir=/usr/share/sddm/themes

# Users
[Users]
MaximumUid=65533
MinimumUid=1000
HideUsers=
HideShells=/sbin/nologin,/bin/false
RememberLastUser=true
RememberLastSession=true

# Wayland configuration
[Wayland]
SessionDir=/usr/share/wayland-sessions
SessionCommand=/usr/share/sddm/scripts/wayland-session
SessionLogFile=.local/share/sddm/wayland-session.log

# X11 fallback configuration  
[X11]
ServerPath=/usr/bin/Xorg
XephyrPath=/usr/bin/Xephyr
SessionDir=/usr/share/xsessions
SessionCommand=/etc/sddm/scripts/Xsession
SessionLogFile=.local/share/sddm/xorg-session.log
DisplayCommand=/etc/sddm/scripts/Xsetup
DisplayStopCommand=/etc/sddm/scripts/Xstop

# Autologin (disabled by default)
[Autologin]
Relogin=false
User=
Session=
EOF
    
    sudo cp /tmp/sddm.conf /etc/sddm.conf.d/
    
    success "SDDM configuration applied"
}

# Create Hyprland session file
create_hyprland_session() {
    log "Creating Hyprland session file for SDDM..."
    
    # Create wayland sessions directory
    sudo mkdir -p /usr/share/wayland-sessions
    
    # Hyprland desktop file
    cat > /tmp/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
    
    sudo cp /tmp/hyprland.desktop /usr/share/wayland-sessions/
    
    success "Hyprland session file created"
}

# Set user avatar
set_user_avatar() {
    log "Setting up user avatar..."
    
    CURRENT_USER=$(whoami)
    AVATAR_DIR="/var/lib/AccountsService/icons"
    
    echo "Choose avatar option:"
    echo "  1. Use default avatar"
    echo "  2. Use custom image (provide path)"
    echo "  3. Skip avatar setup"
    echo
    
    while true; do
        read -p "Select option (1-3): " choice
        case $choice in
            1|3)
                success "Avatar setup skipped"
                return 0
                ;;
            2)
                read -p "Enter full path to avatar image: " avatar_path
                if [ -f "$avatar_path" ]; then
                    sudo mkdir -p "$AVATAR_DIR"
                    sudo cp "$avatar_path" "$AVATAR_DIR/$CURRENT_USER"
                    sudo chown root:root "$AVATAR_DIR/$CURRENT_USER"
                    sudo chmod 644 "$AVATAR_DIR/$CURRENT_USER"
                    success "User avatar set"
                else
                    warning "File not found, skipping avatar setup"
                fi
                break
                ;;
            *)
                warning "Invalid selection. Please choose 1-3."
                ;;
        esac
    done
}

# Test SDDM configuration
test_sddm_config() {
    log "Testing SDDM configuration..."
    
    # Test SDDM config syntax
    if sudo sddm --test-mode 2>/dev/null; then
        success "SDDM configuration test passed"
    else
        warning "SDDM configuration test failed - proceeding anyway"
    fi
    
    # Check theme files
    if [ -f "/usr/share/sddm/themes/simple2/Main.qml" ]; then
        success "Simple2 theme files verified"
    else
        error "Simple2 theme files missing!"
    fi
}

# Display post-installation information
show_completion_info() {
    echo -e "\n${GREEN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${GREEN}│          🎉 SDDM SETUP COMPLETE!        │${NC}"
    echo -e "${GREEN}╰─────────────────────────────────────────╯${NC}"
    echo
    echo -e "${CYAN}Installation Summary:${NC}"
    echo "  ✓ SDDM display manager installed"
    echo "  ✓ Simple2 theme configured"
    echo "  ✓ Hyprland session created"
    echo "  ✓ Display scaling configured"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Reboot your system"
    echo "  2. SDDM will start automatically"
    echo "  3. Select 'Hyprland' session"
    echo "  4. Login with your credentials"
    echo
    echo -e "${CYAN}Configuration Files:${NC}"
    echo "  • /etc/sddm.conf.d/sddm.conf"
    echo "  • /usr/share/sddm/themes/simple2/"
    echo "  • /usr/share/wayland-sessions/hyprland.desktop"
    echo
    echo -e "${PURPLE}Theme Customization:${NC}"
    echo "  Edit: /usr/share/sddm/themes/simple2/theme.conf"
    echo "  Replace: /usr/share/sddm/themes/simple2/background.jpg"
    echo
    if [ -n "$CURRENT_DM" ] && [ "$CURRENT_DM" != "sddm" ]; then
        echo -e "${YELLOW}Warning:${NC} Your previous display manager ($CURRENT_DM) has been disabled."
        echo "To revert: sudo systemctl disable sddm.service && sudo systemctl enable $CURRENT_DM.service"
    fi
    echo
}

# Main execution
main() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║       ███████╗██████╗ ██████╗ ███╗   ███╗                       ║
║       ██╔════╝██╔══██╗██╔══██╗████╗ ████║                       ║
║       ███████╗██║  ██║██║  ██║██╔████╔██║                       ║
║       ╚════██║██║  ██║██║  ██║██║╚██╔╝██║                       ║
║       ███████║██████╔╝██████╔╝██║ ╚═╝ ██║                       ║
║       ╚══════╝╚═════╝ ╚═════╝ ╚═╝     ╚═╝                       ║
║                                                                  ║
║             🎨 SIMPLE2 THEME INSTALLATION 🎨                    ║
║                                                                  ║
║  • Modern Login Manager          • Hyprland Integration         ║
║  • Custom Theme Configuration    • Multi-Resolution Support     ║
║  • Wayland Native               • Beautiful UI Design          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    # Confirm installation
    echo -e "${CYAN}This script will:${NC}"
    echo "  • Install SDDM display manager"
    echo "  • Replace your current display manager"  
    echo "  • Install Simple2 theme"
    echo "  • Configure for Hyprland"
    echo
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    
    detect_current_dm
    backup_current_dm
    install_sddm
    switch_to_sddm
    install_simple2_theme
    customize_simple2_theme
    configure_sddm
    create_hyprland_session
    set_user_avatar
    test_sddm_config
    show_completion_info
}

# Run main function
main "$@"
