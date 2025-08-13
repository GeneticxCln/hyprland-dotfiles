#!/bin/bash
# Advanced Multi-Monitor Management
# Comprehensive display management for Hyprland

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config/hypr/monitors"
PROFILES_DIR="$CONFIG_DIR/profiles"
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"

# Logging
log() { echo -e "${BLUE}[MONITOR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$PROFILES_DIR"
}

# Get connected monitors
get_monitors() {
    hyprctl monitors -j | jq -r '.[] | "\(.name):\(.width)x\(.height)@\(.refreshRate):\(.x),\(.y)"'
}

# List available monitors
list_monitors() {
    echo -e "${CYAN}=== Connected Monitors ===${NC}"
    local monitors_json=$(hyprctl monitors -j)
    
    echo "$monitors_json" | jq -r '.[]' | while IFS= read -r monitor; do
        local name=$(echo "$monitor" | jq -r '.name')
        local width=$(echo "$monitor" | jq -r '.width')
        local height=$(echo "$monitor" | jq -r '.height')
        local refresh=$(echo "$monitor" | jq -r '.refreshRate')
        local x=$(echo "$monitor" | jq -r '.x')
        local y=$(echo "$monitor" | jq -r '.y')
        local transform=$(echo "$monitor" | jq -r '.transform')
        local scale=$(echo "$monitor" | jq -r '.scale')
        local focused=$(echo "$monitor" | jq -r '.focused')
        
        echo -e "${GREEN}Monitor: $name${NC}"
        echo -e "  Resolution: ${width}x${height}@${refresh}Hz"
        echo -e "  Position: ${x},${y}"
        echo -e "  Scale: ${scale}"
        echo -e "  Transform: $transform"
        if [ "$focused" = "true" ]; then
            echo -e "  Status: ${GREEN}[FOCUSED]${NC}"
        else
            echo -e "  Status: Active"
        fi
        echo
    done
}

# Detect available modes for a monitor
get_monitor_modes() {
    local monitor_name="$1"
    
    if [ -z "$monitor_name" ]; then
        warning "Monitor name required"
        return 1
    fi
    
    echo -e "${CYAN}=== Available Modes for $monitor_name ===${NC}"
    
    # Use wlr-randr if available for detailed mode information
    if command -v wlr-randr >/dev/null 2>&1; then
        wlr-randr | awk -v mon="$monitor_name" '
        $0 ~ mon":" {found=1}
        found && /^  [0-9]/ {print "  " $0}
        found && /^[A-Za-z]/ && $0 !~ mon":" {found=0}
        '
    else
        warning "wlr-randr not available. Install with: sudo pacman -S wlr-randr"
        echo "Showing current mode only:"
        hyprctl monitors -j | jq -r --arg name "$monitor_name" '.[] | select(.name==$name) | "  \(.width)x\(.height)@\(.refreshRate)Hz"'
    fi
}

# Configure monitor
configure_monitor() {
    local monitor_name="$1"
    local resolution="${2:-preferred}"
    local position="${3:-auto}"
    local scale="${4:-1}"
    local transform="${5:-0}"
    
    if [ -z "$monitor_name" ]; then
        warning "Monitor name required"
        return 1
    fi
    
    log "Configuring monitor: $monitor_name"
    
    # Build monitor configuration command
    local config_cmd="monitor = $monitor_name"
    
    if [ "$resolution" = "preferred" ]; then
        config_cmd+=",preferred"
    else
        config_cmd+=",$resolution"
    fi
    
    if [ "$position" = "auto" ]; then
        config_cmd+=",auto"
    else
        config_cmd+=",$position"
    fi
    
    config_cmd+=",$scale,$transform"
    
    # Apply configuration
    hyprctl keyword monitor "$monitor_name,$resolution,$position,$scale,transform,$transform"
    
    success "Monitor $monitor_name configured: $resolution @ $position, scale: $scale"
    
    # Save to temporary config
    echo "$config_cmd" > "$CONFIG_DIR/last_config.conf"
}

# Disable monitor
disable_monitor() {
    local monitor_name="$1"
    
    if [ -z "$monitor_name" ]; then
        warning "Monitor name required"
        return 1
    fi
    
    hyprctl keyword monitor "$monitor_name,disable"
    success "Monitor $monitor_name disabled"
}

# Enable monitor
enable_monitor() {
    local monitor_name="$1"
    local resolution="${2:-preferred}"
    local position="${3:-auto}"
    
    configure_monitor "$monitor_name" "$resolution" "$position"
}

# Mirror displays
mirror_displays() {
    local primary="${1:-$(hyprctl monitors -j | jq -r '.[0].name')}"
    local secondary="$2"
    
    if [ -z "$secondary" ]; then
        # Mirror to all other monitors
        hyprctl monitors -j | jq -r '.[].name' | while read -r monitor; do
            if [ "$monitor" != "$primary" ]; then
                configure_monitor "$monitor" "preferred" "0x0"
                log "Mirroring $monitor to $primary"
            fi
        done
    else
        configure_monitor "$secondary" "preferred" "0x0"
        log "Mirroring $secondary to $primary"
    fi
    
    success "Display mirroring configured"
}

# Extend displays
extend_displays() {
    local arrangement="${1:-horizontal}"
    
    log "Extending displays in $arrangement arrangement"
    
    local monitors=($(hyprctl monitors -j | jq -r '.[].name'))
    local position_x=0
    local position_y=0
    
    for i in "${!monitors[@]}"; do
        local monitor="${monitors[$i]}"
        
        if [ $i -eq 0 ]; then
            # Primary monitor at 0,0
            configure_monitor "$monitor" "preferred" "0x0"
        else
            if [ "$arrangement" = "horizontal" ]; then
                # Get width of previous monitor to calculate X offset
                local prev_width=$(hyprctl monitors -j | jq -r --arg name "${monitors[$((i-1))]}" '.[] | select(.name==$name) | .width')
                position_x=$((position_x + prev_width))
                configure_monitor "$monitor" "preferred" "${position_x}x0"
            else
                # Vertical arrangement
                local prev_height=$(hyprctl monitors -j | jq -r --arg name "${monitors[$((i-1))]}" '.[] | select(.name==$name) | .height')
                position_y=$((position_y + prev_height))
                configure_monitor "$monitor" "preferred" "0x${position_y}"
            fi
        fi
    done
    
    success "Displays extended in $arrangement arrangement"
}

# Save monitor profile
save_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        warning "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    # Get current monitor configuration
    {
        echo "# Monitor Profile: $profile_name"
        echo "# Generated: $(date)"
        echo
        hyprctl monitors -j | jq -r '.[]' | while IFS= read -r monitor; do
            local name=$(echo "$monitor" | jq -r '.name')
            local width=$(echo "$monitor" | jq -r '.width')
            local height=$(echo "$monitor" | jq -r '.height')
            local refresh=$(echo "$monitor" | jq -r '.refreshRate')
            local x=$(echo "$monitor" | jq -r '.x')
            local y=$(echo "$monitor" | jq -r '.y')
            local scale=$(echo "$monitor" | jq -r '.scale')
            local transform=$(echo "$monitor" | jq -r '.transform')
            
            echo "monitor = $name,${width}x${height}@${refresh},${x}x${y},$scale,transform,$transform"
        done
    } > "$profile_file"
    
    success "Profile '$profile_name' saved to $profile_file"
}

# Load monitor profile
load_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        warning "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    if [ ! -f "$profile_file" ]; then
        error "Profile '$profile_name' not found"
        return 1
    fi
    
    log "Loading profile: $profile_name"
    
    # Apply each monitor configuration
    grep "^monitor = " "$profile_file" | while read -r line; do
        local config=$(echo "$line" | sed 's/monitor = //')
        hyprctl keyword monitor "$config"
        log "Applied: $config"
    done
    
    success "Profile '$profile_name' loaded"
}

# List saved profiles
list_profiles() {
    echo -e "${CYAN}=== Saved Monitor Profiles ===${NC}"
    
    if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR")" ]; then
        echo "No profiles found"
        return
    fi
    
    for profile in "$PROFILES_DIR"/*.conf; do
        local name=$(basename "$profile" .conf)
        local created=$(stat -c %y "$profile" | cut -d' ' -f1)
        echo -e "${GREEN}$name${NC} (created: $created)"
        
        # Show brief description if available
        local description=$(grep "^# Monitor Profile:" "$profile" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
        if [ -n "$description" ]; then
            echo "  Description:$description"
        fi
        
        # Show monitor count
        local monitor_count=$(grep -c "^monitor = " "$profile")
        echo "  Monitors: $monitor_count"
        echo
    done
}

# Delete profile
delete_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        warning "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    if [ ! -f "$profile_file" ]; then
        error "Profile '$profile_name' not found"
        return 1
    fi
    
    rm "$profile_file"
    success "Profile '$profile_name' deleted"
}

# Auto-detect and configure monitors
auto_configure() {
    log "Auto-detecting and configuring monitors..."
    
    local monitors=($(hyprctl monitors -j | jq -r '.[].name'))
    local monitor_count=${#monitors[@]}
    
    case $monitor_count in
        1)
            log "Single monitor detected, configuring as primary"
            configure_monitor "${monitors[0]}" "preferred" "0x0"
            ;;
        2)
            log "Dual monitor setup detected"
            configure_monitor "${monitors[0]}" "preferred" "0x0"
            # Place second monitor to the right
            local primary_width=$(hyprctl monitors -j | jq -r --arg name "${monitors[0]}" '.[] | select(.name==$name) | .width')
            configure_monitor "${monitors[1]}" "preferred" "${primary_width}x0"
            ;;
        *)
            log "Multiple monitors detected, extending horizontally"
            extend_displays "horizontal"
            ;;
    esac
    
    success "Auto-configuration complete"
}

# Interactive configuration
interactive_config() {
    echo -e "${CYAN}=== Interactive Monitor Configuration ===${NC}"
    
    # List available monitors
    list_monitors
    
    echo -e "${YELLOW}Available commands:${NC}"
    echo "1. Configure monitor"
    echo "2. Disable monitor"
    echo "3. Mirror displays"
    echo "4. Extend displays"
    echo "5. Save profile"
    echo "6. Load profile"
    echo "7. Auto-configure"
    echo "8. Exit"
    echo
    
    read -p "Select option (1-8): " choice
    
    case $choice in
        1)
            read -p "Monitor name: " monitor_name
            read -p "Resolution (or 'preferred'): " resolution
            read -p "Position (x,y or 'auto'): " position
            read -p "Scale (default: 1): " scale
            scale=${scale:-1}
            configure_monitor "$monitor_name" "$resolution" "$position" "$scale"
            ;;
        2)
            read -p "Monitor name to disable: " monitor_name
            disable_monitor "$monitor_name"
            ;;
        3)
            mirror_displays
            ;;
        4)
            read -p "Arrangement (horizontal/vertical): " arrangement
            arrangement=${arrangement:-horizontal}
            extend_displays "$arrangement"
            ;;
        5)
            read -p "Profile name: " profile_name
            save_profile "$profile_name"
            ;;
        6)
            list_profiles
            read -p "Profile name to load: " profile_name
            load_profile "$profile_name"
            ;;
        7)
            auto_configure
            ;;
        8)
            exit 0
            ;;
        *)
            warning "Invalid option"
            interactive_config
            ;;
    esac
}

# Monitor workspace assignment
assign_workspaces() {
    local monitor_name="$1"
    local workspaces="$2"
    
    if [ -z "$monitor_name" ] || [ -z "$workspaces" ]; then
        warning "Monitor name and workspaces required (e.g., 'DP-1' '1,2,3')"
        return 1
    fi
    
    # Split workspaces by comma
    IFS=',' read -ra workspace_array <<< "$workspaces"
    
    for workspace in "${workspace_array[@]}"; do
        hyprctl keyword workspace "$workspace,monitor:$monitor_name"
        log "Assigned workspace $workspace to $monitor_name"
    done
    
    success "Workspace assignment complete"
}

# Show help
show_help() {
    echo "Usage: monitor-manager [command] [options]"
    echo
    echo "Monitor Commands:"
    echo "  list                     List connected monitors"
    echo "  modes [monitor]          Show available modes for monitor"
    echo "  config [monitor] [res] [pos] [scale]  Configure monitor"
    echo "  disable [monitor]        Disable monitor"
    echo "  enable [monitor]         Enable monitor"
    echo
    echo "Layout Commands:"
    echo "  mirror [primary] [secondary]  Mirror displays"
    echo "  extend [horizontal/vertical]  Extend displays"
    echo "  auto                     Auto-configure monitors"
    echo
    echo "Profile Commands:"
    echo "  save [name]              Save current configuration as profile"
    echo "  load [name]              Load monitor profile"
    echo "  list-profiles            List saved profiles"
    echo "  delete [name]            Delete profile"
    echo
    echo "Workspace Commands:"
    echo "  assign [monitor] [workspaces]  Assign workspaces to monitor"
    echo
    echo "Utility Commands:"
    echo "  interactive              Start interactive configuration"
    echo "  help                     Show this help message"
    echo
    echo "Examples:"
    echo "  monitor-manager config DP-1 1920x1080@60 0x0 1"
    echo "  monitor-manager extend horizontal"
    echo "  monitor-manager save dual-setup"
    echo "  monitor-manager assign DP-1 1,2,3"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    list) list_monitors ;;
    modes) get_monitor_modes "$2" ;;
    config) configure_monitor "$2" "$3" "$4" "$5" "$6" ;;
    disable) disable_monitor "$2" ;;
    enable) enable_monitor "$2" "$3" "$4" ;;
    mirror) mirror_displays "$2" "$3" ;;
    extend) extend_displays "$2" ;;
    auto) auto_configure ;;
    save) save_profile "$2" ;;
    load) load_profile "$2" ;;
    list-profiles) list_profiles ;;
    delete) delete_profile "$2" ;;
    assign) assign_workspaces "$2" "$3" ;;
    interactive) interactive_config ;;
    help|*) show_help ;;
esac
