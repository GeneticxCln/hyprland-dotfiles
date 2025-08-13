#!/bin/bash

# Hyprland Dotfiles Script Manager
# Interactive browser and executor for all project scripts

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get current directory (should be the project directory)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$PROJECT_DIR"

# Script definitions with descriptions
declare -A SCRIPTS=(
    ["install.sh"]="🚀 Main Installation - Complete Hyprland dotfiles setup with theme selection"
    ["setup-desktop-integration.sh"]="🖥️  Desktop Integration - Waybar, Rofi, keybinds, and system tray setup"
    ["advanced-config.sh"]="🌈 Advanced Configuration - 50+ keybinds, window rules, rainbow effects"
    ["nvidia-integration.sh"]="🎮 NVIDIA Integration - GPU drivers, scaling, performance optimization"
    ["sddm-setup.sh"]="🎨 SDDM Login Manager - Beautiful login screen with Simple2 theme"
    ["theme-configs.sh"]="🎭 Theme Configuration Library - Theme switching and configuration functions"
    ["full-themes.sh"]="🎪 Full Theme Manager - Complete theme management with wallpapers"
    ["effects.sh"]="✨ Visual Effects Library - Blur and transparency effect configurations"
    ["configs.sh"]="⚙️  Configuration Library - Core configuration management functions"
)

# Check script status
check_script_status() {
    local script="$1"
    local path="$SCRIPT_DIR/$script"
    
    if [[ -f "$path" && -x "$path" ]]; then
        echo -e "${GREEN}✓ Available${NC}"
    elif [[ -f "$path" && ! -x "$path" ]]; then
        echo -e "${YELLOW}⚠ Not executable${NC}"
    else
        echo -e "${RED}✗ Missing${NC}"
    fi
}

# Display main menu
show_main_menu() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗                  ║
║   ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝                  ║
║   ███████╗██║     ██████╔╝██║██████╔╝   ██║                     ║
║   ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║                     ║
║   ███████║╚██████╗██║  ██║██║██║        ██║                     ║
║   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝                     ║
║                                                                  ║
║           🎯 HYPRLAND DOTFILES SCRIPT MANAGER 🎯                ║
║                                                                  ║
║         Navigate, inspect, and execute project scripts          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${WHITE}Project Directory: ${CYAN}$PROJECT_DIR${NC}"
    echo -e "${WHITE}Available Scripts:${NC}\n"
    
    # Display scripts with status
    local counter=1
    local script_order=(
        "install.sh"
        "setup-desktop-integration.sh" 
        "advanced-config.sh"
        "nvidia-integration.sh"
        "sddm-setup.sh"
        "theme-configs.sh"
        "full-themes.sh"
        "effects.sh"
        "configs.sh"
    )
    
    for script in "${script_order[@]}"; do
        if [[ -n "${SCRIPTS[$script]}" ]]; then
            local status=$(check_script_status "$script")
            printf "%2d. %-35s %s\n" $counter "${SCRIPTS[$script]}" "$status"
            ((counter++))
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Navigation Options:${NC}"
    echo -e "  ${GREEN}1-9${NC}     - Run script"
    echo -e "  ${GREEN}i${NC} + num - Inspect script (view code)"
    echo -e "  ${GREEN}h${NC} + num - Show script help/usage"
    echo -e "  ${GREEN}f${NC}       - Fix permissions"
    echo -e "  ${GREEN}l${NC}       - List all files in project"
    echo -e "  ${GREEN}s${NC}       - Show script status"
    echo -e "  ${GREEN}q${NC}       - Quit"
    echo ""
    echo -e -n "${WHITE}Enter your choice: ${NC}"
}

# Get script by number
get_script_by_number() {
    local num="$1"
    local script_order=(
        "install.sh"
        "setup-desktop-integration.sh"
        "advanced-config.sh" 
        "nvidia-integration.sh"
        "sddm-setup.sh"
        "theme-configs.sh"
        "full-themes.sh"
        "effects.sh"
        "configs.sh"
    )
    
    if [[ $num -ge 1 && $num -le ${#script_order[@]} ]]; then
        echo "${script_order[$((num-1))]}"
    else
        echo ""
    fi
}

# Execute script
execute_script() {
    local script="$1"
    local path="$SCRIPT_DIR/$script"
    
    if [[ ! -f "$path" ]]; then
        echo -e "${RED}Error: Script '$script' not found at '$path'${NC}"
        return 1
    fi
    
    if [[ ! -x "$path" ]]; then
        echo -e "${YELLOW}Warning: Script '$script' is not executable. Fixing permissions...${NC}"
        chmod +x "$path"
    fi
    
    echo -e "${GREEN}Executing: $script${NC}"
    echo -e "${CYAN}Description: ${SCRIPTS[$script]}${NC}"
    echo -e "${YELLOW}Path: $path${NC}"
    echo ""
    echo -e "${WHITE}Press Enter to continue or Ctrl+C to abort...${NC}"
    read -r
    
    # Execute the script
    cd "$SCRIPT_DIR" && "./$script"
    local exit_code=$?
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}Script completed successfully!${NC}"
    else
        echo -e "${RED}Script exited with code: $exit_code${NC}"
    fi
    
    echo -e "${WHITE}Press Enter to continue...${NC}"
    read -r
}

# Inspect script
inspect_script() {
    local script="$1"
    local path="$SCRIPT_DIR/$script"
    
    if [[ ! -f "$path" ]]; then
        echo -e "${RED}Error: Script '$script' not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Inspecting: $script${NC}"
    echo -e "${CYAN}Description: ${SCRIPTS[$script]}${NC}"
    echo -e "${YELLOW}Path: $path${NC}"
    echo -e "${WHITE}Size: $(du -h "$path" | cut -f1)${NC}"
    echo ""
    
    # Show first 50 lines with syntax highlighting if available
    if command -v bat &> /dev/null; then
        bat --style=numbers --line-range=1:50 "$path"
    elif command -v highlight &> /dev/null; then
        highlight --syntax=bash --out-format=xterm256 --line-numbers --line-range=1-50 "$path"
    else
        echo -e "${WHITE}First 50 lines:${NC}"
        head -n 50 "$path" | nl -ba
    fi
    
    echo ""
    echo -e "${WHITE}Press Enter to continue...${NC}"
    read -r
}

# Show script help
show_script_help() {
    local script="$1"
    local path="$SCRIPT_DIR/$script"
    
    if [[ ! -f "$path" ]]; then
        echo -e "${RED}Error: Script '$script' not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Getting help for: $script${NC}"
    echo -e "${CYAN}Description: ${SCRIPTS[$script]}${NC}"
    echo ""
    
    # Try different help methods
    cd "$SCRIPT_DIR"
    
    # Try --help flag
    if "./$script" --help 2>/dev/null | head -n 20 | grep -q .; then
        echo -e "${WHITE}Script help output:${NC}"
        timeout 5s "./$script" --help 2>/dev/null | head -n 30
    else
        # Show script header comments
        echo -e "${WHITE}Script header/comments:${NC}"
        grep -n "^#" "$path" | head -n 20
    fi
    
    echo ""
    echo -e "${WHITE}Press Enter to continue...${NC}"
    read -r
}

# Fix permissions
fix_permissions() {
    echo -e "${YELLOW}Fixing script permissions...${NC}"
    
    for script in "${!SCRIPTS[@]}"; do
        local path="$SCRIPT_DIR/$script"
        if [[ -f "$path" ]]; then
            chmod +x "$path"
            echo -e "${GREEN}✓${NC} Fixed: $script"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Permissions fixed!${NC}"
    echo -e "${WHITE}Press Enter to continue...${NC}"
    read -r
}

# List project files
list_files() {
    echo -e "${GREEN}Project Files in: $PROJECT_DIR${NC}"
    echo ""
    
    if command -v tree &> /dev/null; then
        tree -L 2 "$PROJECT_DIR"
    else
        find "$PROJECT_DIR" -maxdepth 2 -type f -name "*.sh" | sort | while read -r file; do
            local basename=$(basename "$file")
            local size=$(du -h "$file" | cut -f1)
            local perms=$(ls -l "$file" | cut -d' ' -f1)
            printf "%-30s %-8s %s\n" "$basename" "$size" "$perms"
        done
    fi
    
    echo ""
    echo -e "${WHITE}Press Enter to continue...${NC}"
    read -r
}

# Show detailed status
show_status() {
    echo -e "${GREEN}Script Status Report${NC}"
    echo ""
    
    for script in "${!SCRIPTS[@]}"; do
        local path="$SCRIPT_DIR/$script"
        local status=$(check_script_status "$script")
        local size=""
        local perms=""
        
        if [[ -f "$path" ]]; then
            size=$(du -h "$path" | cut -f1)
            perms=$(ls -l "$path" | cut -d' ' -f1)
        fi
        
        printf "%-25s %s %-8s %s\n" "$script" "$status" "$size" "$perms"
    done
    
    echo ""
    echo -e "${WHITE}Press Enter to continue...${NC}"
    read -r
}

# Main loop
main() {
    while true; do
        show_main_menu
        read -r choice
        
        case $choice in
            [1-9])
                script=$(get_script_by_number "$choice")
                if [[ -n "$script" ]]; then
                    execute_script "$script"
                else
                    echo -e "${RED}Invalid selection!${NC}"
                    sleep 1
                fi
                ;;
            i[1-9])
                num=${choice#i}
                script=$(get_script_by_number "$num")
                if [[ -n "$script" ]]; then
                    inspect_script "$script"
                else
                    echo -e "${RED}Invalid selection!${NC}"
                    sleep 1
                fi
                ;;
            h[1-9])
                num=${choice#h}
                script=$(get_script_by_number "$num")
                if [[ -n "$script" ]]; then
                    show_script_help "$script"
                else
                    echo -e "${RED}Invalid selection!${NC}"
                    sleep 1
                fi
                ;;
            f)
                fix_permissions
                ;;
            l)
                list_files
                ;;
            s)
                show_status
                ;;
            q|Q)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice! Use 1-9, i1-i9, h1-h9, f, l, s, or q${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if we're in the right directory
if [[ ! -f "$SCRIPT_DIR/install.sh" ]]; then
    echo -e "${RED}Error: This doesn't appear to be the Hyprland project directory.${NC}"
    echo -e "${YELLOW}Current directory: $SCRIPT_DIR${NC}"
    echo -e "${WHITE}Please run this script from the Hyprland dotfiles project directory.${NC}"
    exit 1
fi

# Start the script manager
main "$@"
