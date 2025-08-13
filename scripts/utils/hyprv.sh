#!/bin/bash

# Hyprland Version Manager and Updater (hyprv)
# Manages Hyprland versions, updates, and configuration backups

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config paths
HYPR_CONFIG="$HOME/.config/hypr"
BACKUP_DIR="$HOME/.hyprland-backups"

# Logging
log() { echo -e "${BLUE}[HYPRV]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show version info
show_version() {
    echo -e "${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│         🚀 HYPRLAND VERSION INFO        │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}"
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo -e "${GREEN}Current Version:${NC}"
        hyprctl version | head -5
        echo
        
        echo -e "${GREEN}Build Info:${NC}"
        hyprctl version | grep -E "(built|flags|branch)" || echo "Build info not available"
    else
        error "Hyprland not found! Please install Hyprland first."
        exit 1
    fi
}

# Create backup
create_backup() {
    local backup_name="hyprland-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "Creating backup: $backup_name"
    mkdir -p "$backup_path"
    
    # Backup all Hyprland configs
    if [ -d "$HYPR_CONFIG" ]; then
        cp -r "$HYPR_CONFIG" "$backup_path/"
        log "Backed up: ~/.config/hypr"
    fi
    
    # Backup related configs
    for config in waybar rofi dunst kitty alacritty; do
        if [ -d "$HOME/.config/$config" ]; then
            cp -r "$HOME/.config/$config" "$backup_path/"
            log "Backed up: ~/.config/$config"
        fi
    done
    
    # Save current version info
    hyprctl version > "$backup_path/hyprland-version.txt" 2>/dev/null || echo "Version info not available"
    
    success "Backup created: $backup_path"
}

# List backups
list_backups() {
    echo -e "${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│            📁 BACKUPS LIST               │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        warning "No backups found"
        return 0
    fi
    
    local count=1
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            local name=$(basename "$backup")
            local date=$(echo "$name" | sed 's/hyprland-backup-//')
            local size=$(du -sh "$backup" | cut -f1)
            echo -e "${GREEN}$count.${NC} $name ${YELLOW}($size)${NC}"
            ((count++))
        fi
    done
}

# Restore backup
restore_backup() {
    list_backups
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        return 0
    fi
    
    echo
    read -p "Enter backup number to restore: " choice
    
    local count=1
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ] && [ "$count" = "$choice" ]; then
            log "Restoring backup: $(basename "$backup")"
            
            # Create current backup first
            create_backup
            
            # Restore configs
            if [ -d "$backup/hypr" ]; then
                rm -rf "$HYPR_CONFIG"
                cp -r "$backup/hypr" "$HYPR_CONFIG"
                success "Restored Hyprland config"
            fi
            
            # Restore other configs
            for config in waybar rofi dunst kitty alacritty; do
                if [ -d "$backup/$config" ]; then
                    rm -rf "$HOME/.config/$config"
                    cp -r "$backup/$config" "$HOME/.config/"
                    success "Restored $config config"
                fi
            done
            
            success "Backup restored successfully!"
            warning "Please restart Hyprland to apply changes"
            return 0
        fi
        ((count++))
    done
    
    error "Invalid backup selection"
}

# Update Hyprland
update_hyprland() {
    log "Checking for Hyprland updates..."
    
    # Create backup before update
    create_backup
    
    # Check AUR helper
    local aur_helper=""
    if command -v yay >/dev/null 2>&1; then
        aur_helper="yay"
    elif command -v paru >/dev/null 2>&1; then
        aur_helper="paru"
    else
        error "No AUR helper found. Please install yay or paru"
        exit 1
    fi
    
    log "Updating Hyprland using $aur_helper..."
    $aur_helper -S hyprland --noconfirm
    
    success "Hyprland updated successfully!"
    warning "Please restart your session to apply changes"
}

# Clean old backups
clean_backups() {
    echo -e "${YELLOW}This will remove backups older than 30 days${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        find "$BACKUP_DIR" -name "hyprland-backup-*" -type d -mtime +30 -exec rm -rf {} +
        success "Old backups cleaned"
    fi
}

# Show help
show_help() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗   ██╗                ║
║      ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║   ██║                ║
║      ███████║ ╚████╔╝ ██████╔╝██████╔╝██║   ██║                ║
║      ██╔══██║  ╚██╔╝  ██╔══██╗██╔══██╗╚██╗ ██╔╝                ║
║      ██║  ██║   ██║   ██║  ██║██║  ██║ ╚████╔╝                 ║
║      ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝                  ║
║                                                                  ║
║              🚀 HYPRLAND VERSION MANAGER 🚀                     ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "Usage: hyprv [command]"
    echo
    echo "Commands:"
    echo "  version, -v    Show Hyprland version info"
    echo "  backup, -b     Create configuration backup"
    echo "  list, -l       List available backups"
    echo "  restore, -r    Restore from backup"
    echo "  update, -u     Update Hyprland"
    echo "  clean, -c      Clean old backups"
    echo "  help, -h       Show this help message"
    echo
}

# Main execution
main() {
    case "${1:-help}" in
        version|-v)
            show_version
            ;;
        backup|-b)
            create_backup
            ;;
        list|-l)
            list_backups
            ;;
        restore|-r)
            restore_backup
            ;;
        update|-u)
            update_hyprland
            ;;
        clean|-c)
            clean_backups
            ;;
        help|-h|*)
            show_help
            ;;
    esac
}

main "$@"
