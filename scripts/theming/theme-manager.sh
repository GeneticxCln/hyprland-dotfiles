#!/bin/bash
# Advanced Theme Manager
# Comprehensive theming for cursors, icons, plymouth, GRUB, and system themes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config/hypr/theming"
THEMES_DIR="$CONFIG_DIR/themes"
ICONS_DIR="/usr/share/icons"
CURSOR_DIR="/usr/share/icons"
GTK_THEMES_DIR="/usr/share/themes"
FONTS_DIR="/usr/share/fonts"

# Logging
log() { echo -e "${BLUE}[THEME]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$THEMES_DIR"
}

# List available cursor themes
list_cursor_themes() {
    echo -e "${CYAN}=== Available Cursor Themes ===${NC}"
    
    for theme_dir in "$CURSOR_DIR"/*/cursors; do
        if [ -d "$theme_dir" ]; then
            local theme_name=$(basename "$(dirname "$theme_dir")")
            local current=""
            
            # Check if currently active
            local current_cursor=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
            if [ "$current_cursor" = "$theme_name" ]; then
                current=" ${GREEN}[ACTIVE]${NC}"
            fi
            
            echo -e "  ${GREEN}$theme_name${NC}$current"
        fi
    done
}

# Set cursor theme
set_cursor_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        list_cursor_themes
        read -p "Enter cursor theme name: " theme_name
    fi
    
    if [ -z "$theme_name" ]; then
        error "Cursor theme name required"
        return 1
    fi
    
    # Check if theme exists
    if [ ! -d "$CURSOR_DIR/$theme_name/cursors" ]; then
        error "Cursor theme '$theme_name' not found"
        return 1
    fi
    
    log "Setting cursor theme: $theme_name"
    
    # Set for GTK applications
    gsettings set org.gnome.desktop.interface cursor-theme "$theme_name"
    
    # Set for Qt applications
    if command -v qt5ct >/dev/null 2>&1; then
        mkdir -p "$HOME/.config/qt5ct"
        sed -i "s/^cursor_theme=.*/cursor_theme=$theme_name/" "$HOME/.config/qt5ct/qt5ct.conf" 2>/dev/null || \
        echo "cursor_theme=$theme_name" >> "$HOME/.config/qt5ct/qt5ct.conf"
    fi
    
    # Set environment variables
    export XCURSOR_THEME="$theme_name"
    echo "export XCURSOR_THEME=\"$theme_name\"" >> "$HOME/.profile"
    
    # Update Hyprland cursor
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl keyword cursor:theme "$theme_name"
    fi
    
    success "Cursor theme set to: $theme_name"
    warning "Restart applications or re-login for full effect"
}

# List available icon themes
list_icon_themes() {
    echo -e "${CYAN}=== Available Icon Themes ===${NC}"
    
    for theme_dir in "$ICONS_DIR"/*; do
        if [ -d "$theme_dir" ] && [ -f "$theme_dir/index.theme" ]; then
            local theme_name=$(basename "$theme_dir")
            local display_name=$(grep "^Name=" "$theme_dir/index.theme" 2>/dev/null | cut -d'=' -f2)
            local current=""
            
            # Check if currently active
            local current_icon=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
            if [ "$current_icon" = "$theme_name" ]; then
                current=" ${GREEN}[ACTIVE]${NC}"
            fi
            
            echo -e "  ${GREEN}$theme_name${NC} - $display_name$current"
        fi
    done
}

# Set icon theme
set_icon_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        list_icon_themes
        read -p "Enter icon theme name: " theme_name
    fi
    
    if [ -z "$theme_name" ]; then
        error "Icon theme name required"
        return 1
    fi
    
    # Check if theme exists
    if [ ! -f "$ICONS_DIR/$theme_name/index.theme" ]; then
        error "Icon theme '$theme_name' not found"
        return 1
    fi
    
    log "Setting icon theme: $theme_name"
    
    # Set for GTK applications
    gsettings set org.gnome.desktop.interface icon-theme "$theme_name"
    
    success "Icon theme set to: $theme_name"
}

# List available GTK themes
list_gtk_themes() {
    echo -e "${CYAN}=== Available GTK Themes ===${NC}"
    
    for theme_dir in "$GTK_THEMES_DIR"/*; do
        if [ -d "$theme_dir" ]; then
            local theme_name=$(basename "$theme_dir")
            local current=""
            
            # Check if currently active
            local current_gtk=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
            if [ "$current_gtk" = "$theme_name" ]; then
                current=" ${GREEN}[ACTIVE]${NC}"
            fi
            
            # Check for GTK3/4 support
            local versions=""
            [ -d "$theme_dir/gtk-3.0" ] && versions+="GTK3 "
            [ -d "$theme_dir/gtk-4.0" ] && versions+="GTK4 "
            
            echo -e "  ${GREEN}$theme_name${NC} ($versions)$current"
        fi
    done
}

# Set GTK theme
set_gtk_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        list_gtk_themes
        read -p "Enter GTK theme name: " theme_name
    fi
    
    if [ -z "$theme_name" ]; then
        error "GTK theme name required"
        return 1
    fi
    
    # Check if theme exists
    if [ ! -d "$GTK_THEMES_DIR/$theme_name" ]; then
        error "GTK theme '$theme_name' not found"
        return 1
    fi
    
    log "Setting GTK theme: $theme_name"
    
    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
    
    # Set window manager theme
    gsettings set org.gnome.desktop.wm.preferences theme "$theme_name"
    
    success "GTK theme set to: $theme_name"
}

# Install popular theme packages
install_popular_themes() {
    log "Installing popular theme packages..."
    
    local themes_to_install=(
        "papirus-icon-theme"
        "arc-gtk-theme"
        "numix-gtk-theme"
        "breeze-gtk"
        "adwaita-icon-theme"
        "bibata-cursor-theme"
    )
    
    for theme in "${themes_to_install[@]}"; do
        if command -v pacman >/dev/null 2>&1; then
            if ! pacman -Qi "$theme" >/dev/null 2>&1; then
                log "Installing $theme..."
                sudo pacman -S --noconfirm "$theme" 2>/dev/null || warning "Failed to install $theme"
            fi
        elif command -v apt >/dev/null 2>&1; then
            if ! dpkg -l "$theme" >/dev/null 2>&1; then
                log "Installing $theme..."
                sudo apt install -y "$theme" 2>/dev/null || warning "Failed to install $theme"
            fi
        fi
    done
    
    success "Popular themes installation complete"
}

# Plymouth theme management
list_plymouth_themes() {
    echo -e "${CYAN}=== Available Plymouth Themes ===${NC}"
    
    if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
        warning "Plymouth not installed"
        return 1
    fi
    
    local themes=$(plymouth-set-default-theme --list 2>/dev/null)
    local current=$(plymouth-set-default-theme 2>/dev/null)
    
    for theme in $themes; do
        local marker=""
        if [ "$theme" = "$current" ]; then
            marker=" ${GREEN}[ACTIVE]${NC}"
        fi
        echo -e "  ${GREEN}$theme${NC}$marker"
    done
}

# Set Plymouth theme
set_plymouth_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        list_plymouth_themes
        read -p "Enter Plymouth theme name: " theme_name
    fi
    
    if [ -z "$theme_name" ]; then
        error "Plymouth theme name required"
        return 1
    fi
    
    if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
        error "Plymouth not installed"
        return 1
    fi
    
    log "Setting Plymouth theme: $theme_name"
    
    # Set Plymouth theme
    sudo plymouth-set-default-theme "$theme_name"
    
    # Rebuild initramfs
    log "Rebuilding initramfs..."
    if command -v mkinitcpio >/dev/null 2>&1; then
        sudo mkinitcpio -p linux
    elif command -v update-initramfs >/dev/null 2>&1; then
        sudo update-initramfs -u
    fi
    
    success "Plymouth theme set to: $theme_name"
    warning "Reboot required to see Plymouth changes"
}

# GRUB theme management
list_grub_themes() {
    echo -e "${CYAN}=== Available GRUB Themes ===${NC}"
    
    local grub_themes_dir="/usr/share/grub/themes"
    local boot_grub_themes_dir="/boot/grub/themes"
    
    for themes_dir in "$grub_themes_dir" "$boot_grub_themes_dir"; do
        if [ -d "$themes_dir" ]; then
            for theme_dir in "$themes_dir"/*; do
                if [ -d "$theme_dir" ] && [ -f "$theme_dir/theme.txt" ]; then
                    local theme_name=$(basename "$theme_dir")
                    echo -e "  ${GREEN}$theme_name${NC} ($(dirname "$theme_dir"))"
                fi
            done
        fi
    done
}

# Set GRUB theme
set_grub_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        list_grub_themes
        read -p "Enter GRUB theme name: " theme_name
    fi
    
    if [ -z "$theme_name" ]; then
        error "GRUB theme name required"
        return 1
    fi
    
    # Find theme directory
    local theme_path=""
    for themes_dir in "/usr/share/grub/themes" "/boot/grub/themes"; do
        if [ -f "$themes_dir/$theme_name/theme.txt" ]; then
            theme_path="$themes_dir/$theme_name"
            break
        fi
    done
    
    if [ -z "$theme_path" ]; then
        error "GRUB theme '$theme_name' not found"
        return 1
    fi
    
    log "Setting GRUB theme: $theme_name"
    
    # Update GRUB configuration
    local grub_config="/etc/default/grub"
    if [ -f "$grub_config" ]; then
        # Remove existing theme line
        sudo sed -i '/^GRUB_THEME=/d' "$grub_config"
        # Add new theme line
        echo "GRUB_THEME=\"$theme_path/theme.txt\"" | sudo tee -a "$grub_config" >/dev/null
        
        # Update GRUB
        log "Updating GRUB configuration..."
        if command -v grub-mkconfig >/dev/null 2>&1; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        elif command -v update-grub >/dev/null 2>&1; then
            sudo update-grub
        fi
        
        success "GRUB theme set to: $theme_name"
        warning "Reboot required to see GRUB changes"
    else
        error "GRUB configuration file not found"
        return 1
    fi
}

# Font management
list_fonts() {
    echo -e "${CYAN}=== Installed Fonts ===${NC}"
    
    fc-list : family | sort -u | head -20
    echo "... (showing first 20 fonts)"
    echo
    echo "Use 'fc-list : family | grep -i <pattern>' to search for specific fonts"
}

# Set system fonts
set_fonts() {
    local interface_font="$1"
    local monospace_font="$2"
    local document_font="$3"
    
    if [ -z "$interface_font" ]; then
        read -p "Enter interface font (e.g., 'Cantarell 11'): " interface_font
    fi
    
    if [ -z "$monospace_font" ]; then
        read -p "Enter monospace font (e.g., 'Source Code Pro 10'): " monospace_font
    fi
    
    if [ -z "$document_font" ]; then
        read -p "Enter document font (e.g., 'Cantarell 11'): " document_font
    fi
    
    log "Setting system fonts..."
    
    # Set interface font
    if [ -n "$interface_font" ]; then
        gsettings set org.gnome.desktop.interface font-name "$interface_font"
        log "Interface font: $interface_font"
    fi
    
    # Set monospace font
    if [ -n "$monospace_font" ]; then
        gsettings set org.gnome.desktop.interface monospace-font-name "$monospace_font"
        log "Monospace font: $monospace_font"
    fi
    
    # Set document font
    if [ -n "$document_font" ]; then
        gsettings set org.gnome.desktop.interface document-font-name "$document_font"
        log "Document font: $document_font"
    fi
    
    success "Fonts updated successfully"
}

# Create theme profile
create_theme_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        read -p "Enter profile name: " profile_name
    fi
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$THEMES_DIR/${profile_name}.conf"
    
    log "Creating theme profile: $profile_name"
    
    # Get current theme settings
    local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    local icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    local cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
    local interface_font=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'")
    local monospace_font=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null | tr -d "'")
    
    # Create profile configuration
    cat > "$profile_file" << EOF
# Theme Profile: $profile_name
# Created: $(date)

GTK_THEME="$gtk_theme"
ICON_THEME="$icon_theme"
CURSOR_THEME="$cursor_theme"
INTERFACE_FONT="$interface_font"
MONOSPACE_FONT="$monospace_font"

# Additional settings can be added here
WALLPAPER=""
HYPRLAND_THEME=""
EOF
    
    success "Theme profile '$profile_name' created: $profile_file"
}

# Load theme profile
load_theme_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        list_theme_profiles
        read -p "Enter profile name: " profile_name
    fi
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$THEMES_DIR/${profile_name}.conf"
    
    if [ ! -f "$profile_file" ]; then
        error "Theme profile '$profile_name' not found"
        return 1
    fi
    
    log "Loading theme profile: $profile_name"
    
    # Source the profile
    source "$profile_file"
    
    # Apply theme settings
    if [ -n "$GTK_THEME" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
        log "Applied GTK theme: $GTK_THEME"
    fi
    
    if [ -n "$ICON_THEME" ]; then
        gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
        log "Applied icon theme: $ICON_THEME"
    fi
    
    if [ -n "$CURSOR_THEME" ]; then
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl keyword cursor:theme "$CURSOR_THEME"
        fi
        log "Applied cursor theme: $CURSOR_THEME"
    fi
    
    if [ -n "$INTERFACE_FONT" ]; then
        gsettings set org.gnome.desktop.interface font-name "$INTERFACE_FONT"
        log "Applied interface font: $INTERFACE_FONT"
    fi
    
    if [ -n "$MONOSPACE_FONT" ]; then
        gsettings set org.gnome.desktop.interface monospace-font-name "$MONOSPACE_FONT"
        log "Applied monospace font: $MONOSPACE_FONT"
    fi
    
    success "Theme profile '$profile_name' loaded successfully"
}

# List theme profiles
list_theme_profiles() {
    echo -e "${CYAN}=== Theme Profiles ===${NC}"
    
    if [ ! -d "$THEMES_DIR" ] || [ -z "$(ls -A "$THEMES_DIR")" ]; then
        echo "No theme profiles found"
        return
    fi
    
    for profile in "$THEMES_DIR"/*.conf; do
        if [ -f "$profile" ]; then
            local name=$(basename "$profile" .conf)
            local created=$(stat -c %y "$profile" | cut -d' ' -f1)
            echo -e "  ${GREEN}$name${NC} (created: $created)"
        fi
    done
}

# Show current theme status
theme_status() {
    echo -e "${CYAN}=== Current Theme Status ===${NC}"
    
    # GTK Theme
    local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    echo -e "${GREEN}GTK Theme:${NC} $gtk_theme"
    
    # Icon Theme
    local icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    echo -e "${GREEN}Icon Theme:${NC} $icon_theme"
    
    # Cursor Theme
    local cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
    echo -e "${GREEN}Cursor Theme:${NC} $cursor_theme"
    
    # Fonts
    local interface_font=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'")
    local monospace_font=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null | tr -d "'")
    echo -e "${GREEN}Interface Font:${NC} $interface_font"
    echo -e "${GREEN}Monospace Font:${NC} $monospace_font"
    
    # Plymouth Theme
    if command -v plymouth-set-default-theme >/dev/null 2>&1; then
        local plymouth_theme=$(plymouth-set-default-theme 2>/dev/null)
        echo -e "${GREEN}Plymouth Theme:${NC} $plymouth_theme"
    fi
}

# Show help
show_help() {
    echo "Usage: theme-manager [command] [options]"
    echo
    echo "Cursor Commands:"
    echo "  list-cursors             List available cursor themes"
    echo "  set-cursor [theme]       Set cursor theme"
    echo
    echo "Icon Commands:"
    echo "  list-icons               List available icon themes"
    echo "  set-icon [theme]         Set icon theme"
    echo
    echo "GTK Commands:"
    echo "  list-gtk                 List available GTK themes"
    echo "  set-gtk [theme]          Set GTK theme"
    echo
    echo "System Theme Commands:"
    echo "  list-plymouth            List Plymouth themes"
    echo "  set-plymouth [theme]     Set Plymouth theme"
    echo "  list-grub                List GRUB themes"
    echo "  set-grub [theme]         Set GRUB theme"
    echo
    echo "Font Commands:"
    echo "  list-fonts               List installed fonts"
    echo "  set-fonts [interface] [mono] [document]  Set system fonts"
    echo
    echo "Profile Commands:"
    echo "  create-profile [name]    Create theme profile from current settings"
    echo "  load-profile [name]      Load theme profile"
    echo "  list-profiles            List theme profiles"
    echo
    echo "Utility Commands:"
    echo "  install-popular          Install popular theme packages"
    echo "  status                   Show current theme status"
    echo "  help                     Show this help message"
    echo
    echo "Examples:"
    echo "  theme-manager set-cursor Bibata-Modern-Ice"
    echo "  theme-manager set-icon Papirus-Dark"
    echo "  theme-manager set-gtk Arc-Dark"
    echo "  theme-manager create-profile dark-mode"
    echo "  theme-manager load-profile dark-mode"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    list-cursors) list_cursor_themes ;;
    set-cursor) set_cursor_theme "$2" ;;
    list-icons) list_icon_themes ;;
    set-icon) set_icon_theme "$2" ;;
    list-gtk) list_gtk_themes ;;
    set-gtk) set_gtk_theme "$2" ;;
    list-plymouth) list_plymouth_themes ;;
    set-plymouth) set_plymouth_theme "$2" ;;
    list-grub) list_grub_themes ;;
    set-grub) set_grub_theme "$2" ;;
    list-fonts) list_fonts ;;
    set-fonts) set_fonts "$2" "$3" "$4" ;;
    create-profile) create_theme_profile "$2" ;;
    load-profile) load_theme_profile "$2" ;;
    list-profiles) list_theme_profiles ;;
    install-popular) install_popular_themes ;;
    status) theme_status ;;
    help|*) show_help ;;
esac
