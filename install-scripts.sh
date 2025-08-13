#!/bin/bash

# Install Hyprland Dotfiles Scripts to Config Directory
# This script copies the project scripts to ~/.config/hypr/scripts/ai

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get current directory (should be the project directory)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/hypr/scripts/ai"

echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗             ║
║    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║             ║
║    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║             ║
║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║             ║
║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗        ║
║    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝        ║
║                                                                  ║
║         🚀 SCRIPTS INSTALLATION TO HYPR CONFIG 🚀               ║
║                                                                  ║
║    Install project scripts to ~/.config/hypr/scripts/ai         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${WHITE}Project Directory: ${CYAN}$PROJECT_DIR${NC}"
echo -e "${WHITE}Target Directory:  ${CYAN}$TARGET_DIR${NC}"
echo ""

# Create target directory if it doesn't exist
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${YELLOW}Creating target directory...${NC}"
    mkdir -p "$TARGET_DIR"
    echo -e "${GREEN}✓${NC} Created: $TARGET_DIR"
else
    echo -e "${GREEN}✓${NC} Target directory exists: $TARGET_DIR"
fi

# List of scripts to install
SCRIPTS=(
    "install.sh"
    "setup-desktop-integration.sh"
    "advanced-config.sh"
    "nvidia-integration.sh"
    "sddm-setup.sh"
    "theme-configs.sh"
    "full-themes.sh"
    "effects.sh"
    "configs.sh"
    "script-manager.sh"
    "install-scripts.sh"
)

echo ""
echo -e "${YELLOW}Installing scripts...${NC}"

# Copy each script
for script in "${SCRIPTS[@]}"; do
    local source_path="$PROJECT_DIR/$script"
    local target_path="$TARGET_DIR/$script"
    
    if [[ -f "$source_path" ]]; then
        # Copy script
        cp "$source_path" "$target_path"
        
        # Make executable
        chmod +x "$target_path"
        
        # Get size for display
        local size=$(du -h "$source_path" | cut -f1)
        
        echo -e "${GREEN}✓${NC} Installed: $script (${size})"
    else
        echo -e "${RED}✗${NC} Missing: $script"
    fi
done

# Copy the scripts directory if it exists
if [[ -d "$PROJECT_DIR/scripts" ]]; then
    echo ""
    echo -e "${YELLOW}Copying additional scripts directory...${NC}"
    
    # Create scripts subdirectory
    mkdir -p "$TARGET_DIR/scripts"
    
    # Copy recursively
    cp -r "$PROJECT_DIR/scripts"/* "$TARGET_DIR/scripts/"
    
    # Make all scripts executable
    find "$TARGET_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    
    # Count files copied
    local script_count=$(find "$TARGET_DIR/scripts" -name "*.sh" | wc -l)
    echo -e "${GREEN}✓${NC} Copied additional scripts directory (${script_count} shell scripts)"
fi

echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo ""
echo -e "${WHITE}Scripts installed to: ${CYAN}$TARGET_DIR${NC}"
echo ""
echo -e "${YELLOW}You can now run scripts from either location:${NC}"
echo -e "  • Project directory: ${CYAN}$PROJECT_DIR${NC}"
echo -e "  • Config directory:  ${CYAN}$TARGET_DIR${NC}"
echo ""
echo -e "${WHITE}To use the script manager from config directory:${NC}"
echo -e "  ${CYAN}cd ~/.config/hypr/scripts/ai && ./script-manager.sh${NC}"
echo ""
echo -e "${WHITE}Or add to your PATH for global access:${NC}"
echo -e "  ${CYAN}export PATH=\"\$PATH:$TARGET_DIR\"${NC}"

# Create a symlink in local bin for easy access
LOCAL_BIN="$HOME/.local/bin"
if [[ -d "$LOCAL_BIN" ]]; then
    echo ""
    echo -e "${YELLOW}Creating symlink in ~/.local/bin for global access...${NC}"
    
    ln -sf "$TARGET_DIR/script-manager.sh" "$LOCAL_BIN/hypr-scripts"
    chmod +x "$LOCAL_BIN/hypr-scripts"
    
    echo -e "${GREEN}✓${NC} Created: ~/.local/bin/hypr-scripts"
    echo -e "${WHITE}You can now run: ${CYAN}hypr-scripts${NC} from anywhere"
fi

echo ""
echo -e "${CYAN}Happy scripting! 🚀${NC}"
