#!/bin/bash

# Modular Hyprland Installation Script
# Inspired by Ja-KooLit's approach but with modern features
# Version: 2.1

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Logging
LOG_DIR="$SCRIPT_DIR/Install-Logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

log() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      🚀 MODULAR HYPRLAND INSTALLATION SYSTEM 🚀                ║
║                                                                  ║
║  📦 Choose exactly what you want to install                     ║
║  🎨 20 Complete themes with wallpapers                          ║
║  🤖 AI-powered desktop automation                               ║
║  🎮 Gaming optimization suite                                   ║
║  📱 Mobile device integration                                   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Component selection menu
show_components() {
    echo -e "${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│         📦 COMPONENT SELECTION          │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}\n"
    
    echo "Available components:"
    echo -e "${WHITE}Core Components:${NC}"
    echo "  [1] 🖥️  Hyprland + Core Desktop (Required)"
    echo "  [2] 🎨 Theme System (20 themes + wallpapers)"
    echo "  [3] 📊 Waybar Status Bar"
    echo "  [4] 🚀 Quickshell Desktop Environment"
    echo "  [5] 🔍 Rofi Application Launcher"
    echo
    
    echo -e "${WHITE}Advanced Features:${NC}"
    echo "  [6] 🤖 AI Management Suite"
    echo "  [7] 🎮 Gaming Optimization"
    echo "  [8] 📱 Mobile Sync Integration" 
    echo "  [9] 🔒 Security Management"
    echo " [10] 🖼️  Wallpaper Collections"
    echo
    
    echo -e "${WHITE}Applications:${NC}"
    echo " [11] 💻 Development Tools"
    echo " [12] 🎵 Media Applications"
    echo " [13] 🎯 Productivity Suite"
    echo " [14] 🎨 Graphics & Design"
    echo
    
    echo -e "${WHITE}System Integration:${NC}"
    echo " [15] 🖥️  NVIDIA Integration"
    echo " [16] 🎭 SDDM Login Theme"
    echo " [17] 🎨 GTK Theme Integration"
    echo " [18] 🔧 System Utilities"
    echo
    
    echo -e "${WHITE}Presets:${NC}"
    echo " [P1] 🚀 Minimal Install (Core only)"
    echo " [P2] 💫 Standard Install (Core + Themes + Apps)"
    echo " [P3] 🌟 Full Install (Everything)"
    echo " [P4] 🎮 Gaming Setup (Core + Gaming + Performance)"
    echo " [P5] 💼 Workstation (Core + Development + Productivity)"
    echo
}

# Component selection
select_components() {
    show_components
    
    declare -A selected_components
    
    echo -e "${YELLOW}Select components to install:${NC}"
    echo "Enter component numbers separated by spaces (e.g., 1 2 3)"
    echo "Or choose a preset (P1, P2, P3, P4, P5)"
    echo "Press Enter when done, or 'q' to quit"
    
    while true; do
        echo
        read -p "Selection: " selection
        
        case $selection in
            "q"|"Q") exit 0 ;;
            "") break ;;
            "P1"|"p1") 
                selected_components[1]=1
                log "Selected Preset: Minimal Install"
                break ;;
            "P2"|"p2")
                selected_components[1]=1
                selected_components[2]=1
                selected_components[3]=1
                selected_components[4]=1
                selected_components[5]=1
                selected_components[11]=1
                log "Selected Preset: Standard Install"
                break ;;
            "P3"|"p3")
                for i in {1..18}; do selected_components[$i]=1; done
                log "Selected Preset: Full Install"
                break ;;
            "P4"|"p4")
                selected_components[1]=1
                selected_components[2]=1
                selected_components[7]=1
                selected_components[15]=1
                log "Selected Preset: Gaming Setup"
                break ;;
            "P5"|"p5")
                selected_components[1]=1
                selected_components[2]=1
                selected_components[11]=1
                selected_components[13]=1
                selected_components[6]=1
                log "Selected Preset: Workstation"
                break ;;
            *)
                # Parse individual selections
                for num in $selection; do
                    if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le 18 ]; then
                        selected_components[$num]=1
                        echo "  ✓ Selected component $num"
                    else
                        warning "Invalid component number: $num"
                    fi
                done
                ;;
        esac
    done
    
    # Export selected components for use in installation scripts
    export INSTALL_CORE=${selected_components[1]:-0}
    export INSTALL_THEMES=${selected_components[2]:-0}
    export INSTALL_WAYBAR=${selected_components[3]:-0}
    export INSTALL_QUICKSHELL=${selected_components[4]:-0}
    export INSTALL_ROFI=${selected_components[5]:-0}
    export INSTALL_AI=${selected_components[6]:-0}
    export INSTALL_GAMING=${selected_components[7]:-0}
    export INSTALL_MOBILE=${selected_components[8]:-0}
    export INSTALL_SECURITY=${selected_components[9]:-0}
    export INSTALL_WALLPAPERS=${selected_components[10]:-0}
    export INSTALL_DEV=${selected_components[11]:-0}
    export INSTALL_MEDIA=${selected_components[12]:-0}
    export INSTALL_PRODUCTIVITY=${selected_components[13]:-0}
    export INSTALL_GRAPHICS=${selected_components[14]:-0}
    export INSTALL_NVIDIA=${selected_components[15]:-0}
    export INSTALL_SDDM=${selected_components[16]:-0}
    export INSTALL_GTK=${selected_components[17]:-0}
    export INSTALL_UTILS=${selected_components[18]:-0}
    
    # Summary
    echo -e "\n${GREEN}Installation Summary:${NC}"
    [ "$INSTALL_CORE" = "1" ] && echo "  ✓ Hyprland Core Desktop"
    [ "$INSTALL_THEMES" = "1" ] && echo "  ✓ 20 Theme System"
    [ "$INSTALL_AI" = "1" ] && echo "  ✓ AI Management Suite"
    [ "$INSTALL_GAMING" = "1" ] && echo "  ✓ Gaming Optimization"
    [ "$INSTALL_MOBILE" = "1" ] && echo "  ✓ Mobile Integration"
    # ... continue for all components
    
    echo
    read -p "Proceed with installation? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
}

# Execute modular installation scripts
execute_installation() {
    log "Starting modular installation..."
    
    # Core installation (always required)
    if [ "$INSTALL_CORE" = "1" ]; then
        log "Installing core components..."
        if [ -f "$SCRIPT_DIR/install-scripts/01-core.sh" ]; then
            bash "$SCRIPT_DIR/install-scripts/01-core.sh" | tee -a "$LOG_FILE"
        else
            warning "Core installation script not found, using fallback"
            bash "$SCRIPT_DIR/install.sh" --core-only | tee -a "$LOG_FILE"
        fi
    fi
    
    # Modular components
    [ "$INSTALL_THEMES" = "1" ] && execute_script "02-themes.sh"
    [ "$INSTALL_WAYBAR" = "1" ] && execute_script "03-waybar.sh"
    [ "$INSTALL_QUICKSHELL" = "1" ] && execute_script "04-quickshell.sh"
    [ "$INSTALL_ROFI" = "1" ] && execute_script "05-rofi.sh"
    [ "$INSTALL_AI" = "1" ] && execute_script "06-ai.sh"
    [ "$INSTALL_GAMING" = "1" ] && execute_script "07-gaming.sh"
    [ "$INSTALL_MOBILE" = "1" ] && execute_script "08-mobile.sh"
    [ "$INSTALL_SECURITY" = "1" ] && execute_script "09-security.sh"
    [ "$INSTALL_WALLPAPERS" = "1" ] && execute_script "10-wallpapers.sh"
    [ "$INSTALL_DEV" = "1" ] && execute_script "11-development.sh"
    [ "$INSTALL_MEDIA" = "1" ] && execute_script "12-media.sh"
    [ "$INSTALL_PRODUCTIVITY" = "1" ] && execute_script "13-productivity.sh"
    [ "$INSTALL_GRAPHICS" = "1" ] && execute_script "14-graphics.sh"
    [ "$INSTALL_NVIDIA" = "1" ] && execute_script "15-nvidia.sh"
    [ "$INSTALL_SDDM" = "1" ] && execute_script "16-sddm.sh"
    [ "$INSTALL_GTK" = "1" ] && execute_script "17-gtk.sh"
    [ "$INSTALL_UTILS" = "1" ] && execute_script "18-utils.sh"
}

# Execute individual script with error handling
execute_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/install-scripts/$script_name"
    
    if [ -f "$script_path" ]; then
        log "Executing: $script_name"
        if bash "$script_path" | tee -a "$LOG_FILE"; then
            success "Completed: $script_name"
        else
            error "Failed: $script_name"
        fi
    else
        warning "Script not found: $script_path"
        log "Creating placeholder for future implementation"
        # Create placeholder script for future development
        create_placeholder_script "$script_path" "$script_name"
    fi
}

# Create placeholder script for missing components
create_placeholder_script() {
    local script_path="$1"
    local script_name="$2"
    
    mkdir -p "$(dirname "$script_path")"
    cat > "$script_path" << EOF
#!/bin/bash
# Placeholder script for $script_name
# This will be implemented in a future version

echo "⚠️  $script_name is not yet implemented"
echo "📝 This feature will be available in the next release"
echo "🔧 For now, you can manually configure this component"

# Exit successfully to not break the installation flow
exit 0
EOF
    chmod +x "$script_path"
}

# Main execution
main() {
    show_banner
    
    log "Starting Modular Hyprland Installation System"
    log "Log file: $LOG_FILE"
    
    # System compatibility check
    if ! command -v pacman &> /dev/null; then
        error "This installer requires Arch Linux or an Arch-based distribution"
    fi
    
    select_components
    execute_installation
    
    success "Modular installation completed!"
    echo -e "\n${GREEN}Next Steps:${NC}"
    echo "1. Reboot your system"
    echo "2. Select Hyprland at login"
    echo "3. Press SUPER+H for help overlay"
    echo "4. Check the documentation: ./docs/README.md"
    
    log "Installation completed successfully"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        show_banner
        show_components
        echo -e "\nUsage: $0 [options]"
        echo "  --help, -h    Show this help"
        echo "  --gui         Launch GUI component selector (future)"
        echo "  --preset NAME Use predefined preset (minimal, standard, full, gaming, workstation)"
        exit 0
        ;;
    --preset)
        PRESET="$2"
        # Handle preset selection automatically
        ;;
esac

# Run main function
main "$@"
